require 'nkf'

module ImportPage::Importers
  class PageImporter < self::Base

    class_attribute :visitor_data_root
    self.visitor_data_root = Settings.visitor_data_path

    def import
      messages.clear

      page = nil

      begin
        Page.transaction do
          page = create_or_update_page
          raise ActiveRecord::Rollback unless page

          pc = create_or_update_private_content(page)
          unless pc
            page = nil
            raise ActiveRecord::Rollback
          end
        end
      rescue => e
        messages << I18n.t(:page_not_imported, scope: self.class.i18n_message_scope)
        logger.error(e.message)
        logger.error(e.backtrace.join("\n"))
        page = nil
      end

      page
    end

    private

    def create_or_update_page
      filename = File.basename(path)
      page_name = filename.split('.').first
      page = Page.find_or_initialize_by(name: page_name, genre_id: genre.id)
      if page.new_record?
        page.title = page_name

        unless page.save
          msg = if page.errors[:name].any?
            I18n.t(:invalid_filename, scope: self.class.i18n_message_scope)
          else
            I18n.t(:page_not_imported, scope: self.class.i18n_message_scope)
          end
          messages << msg
        end
      end

      return nil if page.new_record?

      doc = Nokogiri.HTML(NKF.nkf('-w', File.read(path)))
      page.title = doc.at_css('title').inner_html
      unless page.save
        messages << I18n.t(:invalid_page_title, scope: self.class.i18n_message_scope)
      end

      page.reload
    end

    def create_or_update_private_content(page)
      pc = nil
      begin
        PageContent.transaction do
          pc = page.private_content_or_new
          # Susanoo のページコンテンツに合わせ実装
          pc.content = NKF.nkf('-w -X', File.read(path)).
            slice(%r!<body(.*)</body>!im).
            gsub(%r!</?(?:body)\b[^>]*>!im, '')

          # 機種依存文字を変換する
          # 変換できない機種依存文字が存在する場合は取り込まない
          unless validates_platform_dependent_characters(pc)
            raise ImportPage::DataInvalid
          end

          # 添付ファイルの取り込み
          import_attached_files(pc)

          pc.normalize_pc!
          pc.normalize_mobile!
          pc.content = pc.send(:plugin_tag_to_erb, pc.content)

          pc.admission = PageContent.page_status[:editing]
          pc.top_news = PageContent.top_news_status[:no]
          pc.last_modified = Time.zone.now
          pc.edit_required = true

          pc.save!

          # Susanoo::AccessibilityCheker を用いた検証
          validates_accessibility(pc)

          pc.save!

          revision = ::PageRevision.new(last_modified: pc.last_modified, user_id: user_id)
          page.new_revision(revision)
        end
      rescue ImportPage::DataInvalid
        # Nothing
        pc = nil
      end
      pc
    end

    #
    # === 機種依存文字の検証
    #
    # 機種依存文字を検証する。
    # 変換可能な機種依存文字は変換する。
    # 失敗する。
    def validates_platform_dependent_characters(pc)
      text = pc.content.dup

      # UTF-8の半角空白を &nbsp; に変換する
      # (UTF-8の半角空白は機種依存文字として扱われるため)
      nbsp = Nokogiri::HTML("&nbsp;").text
      text.gsub!(nbsp, "&nbsp;")

      text.gsub!(/<!--.*?-->/, '')
      text.gsub!(%r!<span[^>]*?\s*class="invalid"[^>]*>([^<]+)</span\s*>!, '\1')
      text.gsub!(%r!<img([^>]*?)\s*class="invalid"!, '<img\1')

      pc.content = text
      invalid_chars = Susanoo::Filter.non_japanese_chars(pc.content)
      return true if invalid_chars.blank?

      # 機種依存文字の変換
      text = Susanoo::Filter.convert_non_japanese_chars(text, true)
      text.gsub!(%r!<span[^>]*?\s*class="invalid"[^>]*>([^<]+)</span\s*>!) do
        Nokogiri.HTML($1).text
      end

      # 変換できない機種依存文字のメッセージの取得
      pc.content = text
      unless pc.validate_content(true)
        pc.errors.full_messages.each do |msg|
          messages << msg
        end
        return false
      end
      true
    end

    def validates_accessibility(pc)
      app = susanoo_application
      # ページ編集画面で使用するページを取得する
      app.get("/susanoo/visitors/#{pc.id}/preview?edit_style=1")
      checker = Susanoo::AccessibilityChecker.new
      checker.run(app.body)

      # Accesibility のエラーをメッセージに変換し、登録
      # 処理は ::ApplicationHelper#accessibility_messages を参考
      checker.errors.map do |e|
        options = { scope: 'accessibility.errors', default: e['description'] }
        if e['args'].present?
          e['args'].each_with_index { |a, i| options["arg#{i+1}".to_sym] = a }
        else
          options[:arg1] = e['target']
        end
        messages << %{#{e['id']}:#{I18n.t(e['id'].gsub("\.", "_"), options)}}
      end
      checker.errors.empty?
    end

    def get_html_for_accessibility(pc)
      # Susanoo::VisitorController#preview アクションから取得したページは
      # 画面上でのアクセシビリティチェックの結果と異なるため、
      # コンテンツ編集画面と同じ Susanoo::PageContentsController#content アクションから
      # 取得するHTMLに対してアクセシビリティチェックする。
      page_view = pc.edit_style_page_view
      view_context = Susanoo::PageContentsController.view_context_class.new
      view_context.view_paths = Susanoo::PageContentsController.view_paths.paths
      view_context.assign(page_view: page_view, page_content: pc, page: pc.page)
      view_context.render(template: page_view.template, layout: false)
    end

    def import_attached_files(pc)
      page = pc.page

      doc = Nokogiri.HTML("<body>#{pc.content}</body>")

      grouped_exist_images = Susanoo::Assets::Image.all(page_id: pc.page_id).group_by(&:data_file_name)
      grouped_images = grouped_exist_images.dup

      Dir.mktmpdir do |tmpdir|
        doc.css('img, a').each do |tag|
          attr = case tag.name
                   when 'img'; 'src'
                   when 'a';   'href'
                   end
          next unless attr

          uri = URI.parse(tag[attr]) rescue nil
          next unless uri && uri.scheme.blank? && uri.query.blank? && uri.fragment.blank?

          attached_file_path = File.expand_path(File.join('../', uri.path), path)
          next unless File.exist?(attached_file_path)

          attached_file =
            case File.basename(attached_file_path)
            when Susanoo::Assets::Base.regex[:image]
              Susanoo::Assets::Image.new
            when Susanoo::Assets::Base.regex[:attachment_file]
              Susanoo::Assets::AttachmentFile.new
            end
          next if attached_file.nil?

          attached_file.page = pc.page
          attached_file.data = File.open(attached_file_path)
          # 保存パスの変更
          attached_file.data.options[:path] = File.join(tmpdir, ':basename.:extension')
          # 元のファイルは保持する
          attached_file.data.options[:keep_old_files] = true
          # パーミッションは保持しておく(こうしないとファイルの削除時にパーミッションエラーが発生する)
          attached_file.data.options[:override_file_permissions] = false

          if attached_file.image?
            grouped_images[attached_file.data_file_name] = attached_file

            if grouped_images.values.sum(&:data_file_size) > Settings.max_upload_image_total_size
              human_size = ActiveSupport::NumberHelper.number_to_human_size(
                Settings.max_upload_image_total_size
              ).sub(/B(?:ytes?)?$/, '').strip

              messages <<
                I18n.t(:image_total_size_too_big,
                       scope: self.class.i18n_message_scope,
                       size: human_size,
                      )
              raise ImportPage::DataInvalid
            end
          end

          if attached_file.save
            tag[attr] = attached_file.url
          end
        end
        dst = Pathname.new(self.visitor_data_root).join(page.id.to_s)
        FileUtils.mkdir_p dst
        FileUtils.cp Dir[File.join(tmpdir, '*')], dst
      end

      pc.content = doc.at_css('body').inner_html
    end

    def susanoo_application
      @susanoo_application ||=
        ActionDispatch::Integration::Session.new(PrefShimaneCms::Application)
    end
  end
end
