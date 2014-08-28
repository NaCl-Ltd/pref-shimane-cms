# -*- coding: utf-8 -*-
require 'nokogiri'

module Concerns::PageContent::Method
  extend ActiveSupport::Concern

  included do

    # 現在公開中のコンテンツを返す
    scope :eq_publish, ->{
      where(admission: page_status[:publish])
        .where(["(begin_date IS NULL OR begin_date <= :now) AND (end_date IS NULL OR end_date >= :now)",
          now: Time.zone.now
        ])
    }

    # 公開待ちのコンテンツを返す
    scope :eq_waiting, ->{
      where(admission: page_status[:publish])
        .where(["begin_date IS NOT NULL AND begin_date > ?", Time.zone.now])
    }

    # 公開開始日が過去日のコンテンツを返す
    scope :eq_published, ->{
      where(admission: public_status)
        .where(["begin_date IS NULL OR begin_date <= ?", Time.zone.now])
    }

    # 公開のコンテンツを返す
    scope :eq_public, ->{
      where(admission: public_status)
    }

    # 未公開のコンテンツを返す
    scope :eq_private, ->{
      where(admission: private_status)
    }

    # 編集中のコンテンツを返す
    scope :eq_editing, ->{
      where(admission: page_status[:editing])
    }

    # 公開依頼中のコンテンツを返す
    scope :eq_request, ->{
      where(admission: page_status[:request])
    }

    # 公開終了日の過ぎた公開中コンテンツを返す
    scope :eq_public_end, -> {
      where(admission: page_status[:publish])
        .where("end_date IS NOT NULL AND end_date < ?", Time.zone.now)
    }

    # SectionNewsのコンテンツを返す
    scope :eq_section_news, -> {
      where(section_news: section_news_status[:yes])
    }

    # 公開開始したコンテンツを返す
    scope :eq_public_start, ->{
      where(["(begin_date IS NULL OR begin_date <= ?)", Time.zone.now])
    }

    #
    #=== 公開状態のキーを返す
    # 公開中の場合は、公開開始日、公開終了日で判断する
    #
    def admission_key
      page_status.key(admission_local)
    end

    #
    #=== 公開状態コードを返す
    # 公開状態が「公開中」の場合、公開期間から「公開待ち」「公開期限切れ」を判定する
    #
    def admission_local
      if page_status[:publish] == admission
        if !publish_not_finished? then
          page_status[:finished]
        elsif !publish_started?
          page_status[:waiting]
        else
          page_status[:publish]
        end
      else
        admission
      end
    end

    #
    #=== 公開状態名称を返す
    #
    def admission_local_label
      ::PageContent.admission_label(admission_local)
    end

    #
    #=== 公開コンテンツかどうかを返す
    #
    def public?
      public_status.include?(admission)
    end

    #
    #=== 未公開コンテンツかどうかを返す
    #
    def private?
      private_status.include?(admission)
    end

    #
    #=== 公開期間中かどうか返す
    #
    def in_publish?
      publish_started? && publish_not_finished?
    end

    #
    #=== 公開開始日を過ぎたかどうか返す
    # begin_date が nil の場合は、無条件に true
    #
    def publish_started?
      begin_date.nil? || begin_date <= Time.zone.now
    end

    #
    #=== 公開終了日を過ぎてないかを返す
    # end_date が nil の場合は、無条件に true
    #
    def publish_not_finished?
      end_date.nil? || end_date >= Time.zone.now
    end

    #
    #=== 公開終了日を過ぎたかを返す
    #
    def publish_finished?
      end_date && end_date < Time.zone.now
    end

    #
    #=== 公開日を返す（公開期間をセットしなければbegin_dateはnilになる）
    #
    def date
      self.begin_date || self.last_modified
    end

    #
    #=== section_newsの名称を返す
    #
    def section_news_name
      section_news ? section_news_status.key(section_news) : nil
    end

    #
    #=== ドメイン付きのメールアドレスを返す
    #
    def email_with_domain
      email ? "#{email}@#{Settings.mail.domain}" : nil
    end

    #
    #=== 旧CMSのコンテンツをSusanoo用コンテンツに変換する
    #
    def to_current_format(col = :content)
      org = self.send(col)
      dest = to_current_format_html(org)
      self.send("#{col}=", dest)
      dest
    end

    #
    #=== Susanoo用コンテンツに変換する
    #
    def to_current_format_html(org, force=false)
      # HTML解析時にスクリプトブロックが削除されてしまうため一時的に編集用タグに変換する
      dest = plugin_erb_to_tag(org)

      c = editable_class
      f = c[:field]

      # すでにSusanoo用のHTMLに変換されている場合はHTMLをそのまま返却する
      doc_check = Nokogiri::HTML.fragment(dest)
      editable_block = doc_check.css("div.#{f}")
      if editable_block.present? && !force
        return org
      end

      # 編集フィールド用のタグを挿入する。
      # HTML直接入力等で、すでに編集フィールド用のタグが挿入されている場合は何もしない
      editable_field = doc_check.css("div.#{f}")
      if editable_field.blank?
        dest = %Q(<div class="#{f}">#{dest}</div>)
      end

      doc = Nokogiri::HTML.fragment(dest)

      # 編集可能フィールド毎にHTMLを整形する
      doc.css("div.#{f}").each do |field|
        block_start = true
        new_parent = nil

        # 見出しタグ間の要素をdivで囲む
        field.children.each do |node|
          if /^(h|H)[1-6]$/ =~ node.name
            block_start = true
          elsif node['class'] == "#{c[:block]} #{c[:plugin]}" || node.name == 'div'
            block_start = true
            new_parent = nil
          elsif !(node.name == 'text' && node.text.gsub("\n|\s", '').blank?)
            if block_start
              new_parent = Nokogiri::XML::Node::new('div', doc)
              node.add_next_sibling(new_parent)
              block_start = false
            end
            if new_parent.present?
              new_parent.add_child(node)
            end
          end
        end
      end

      converted = doc.to_xhtml(indent: 0)
      # プラグイン編集用タグを元に戻す
      plugin_tag_to_erb(converted.split("\n").inject('') {|s, l| s += l.strip})
    end

    #
    #=== PC向けコンテンツを正規化する
    #
    def normalize_pc!
      self.content = normalize_content(content)
      self.content = normalize_content_links
      self.content = cleanup(content)
      self.content = to_xhtml(content)
    end

    #
    #=== 携帯向けコンテンツを正規化する
    #
    def normalize_mobile!
      if mobile.present?
        self.mobile = normalize_content(mobile)
        self.mobile = cleanup(mobile)
      end
    end

    #
    #=== コンテンツ内のリンクを置換する
    #
    def replace_content_links(from, to)
      content_each_local_links do |uri|
        uri.to_s == from ? to : uri
      end
    end

    #
    #=== コンテンツ内のリンクを正規表現で置換する
    #
    def replace_content_links_regexp(from, to)
      content_each_local_links do |uri|
        uri_s = uri.to_s
        if from =~ uri_s
          uri_s.sub(from, to)
        else
          uri
        end
      end
    end

    #
    #=== Link 設定
    # コンテンツ内のリンクからPageLinkを新規作成する
    # すでにPagaLinkがある場合、削除してから新規作成する
    #
    def create_page_links(doc = nil)
      doc = Nokogiri::HTML.fragment(content) if doc.nil?
      links.clear
      find_links(doc).each do |uri|
        next unless local_uri?(uri)
        links << PageLink.new(link: uri.to_s)
      end
    end

    #
    #=== ページ編集用のコンテンツを返す
    #
    def edit_style_content
      self.content = "<h1>#{page.title}</h1>" if content.blank?
      if @edit_style_content.nil?
        _content = to_current_format
        @edit_style_content = to_edit_style(_content)
      end
      @edit_style_content
    end

    #
    #=== ページ編集用の携帯コンテンツを返す
    #
    def edit_style_mobile_content
      self.mobile = "<h1>#{page.title}</h1>" if mobile.blank?
      if @edit_style_mobile_content.nil?
        _mobile = to_current_format(:mobile)
        @edit_style_mobile_content = to_edit_style(_mobile)
      end
      @edit_style_mobile_content
    end

    #
    #=== コンテンツに編集用のクラス属性を追加する
    #
    def to_edit_style(org)
      c = editable_class
      dest = plugin_erb_to_tag(org)
      doc = Nokogiri::HTML.fragment(dest)
      doc.css("div.#{c[:field]} > *").each_with_index do |e, i|
        if /^(h|H)[1-6]$/ =~ e.name
          new_parent = Nokogiri::XML::Node::new('div', doc)
          new_parent['class'] = "#{c[:block]} #{c[:heading]}"
          e.add_next_sibling(new_parent)
          new_parent.add_child(e)
        elsif e.name == 'button' && e["class"] == "#{c[:block]} #{c[:plugin]}"
        else
          html_class = "#{c[:block]} #{c[:div]}"
          if e['class'].present?
            e['class'] += " #{html_class}"
          else
            e['class'] = html_class
          end
        end
      end

      if Settings.page_content && Settings.page_content.remove_class
        Settings.page_content.remove_class.each do |ra|
          node_set = doc.css(ra.selector)
          ra.value.each { |v| node_set.remove_class(v) }
        end
      end

      doc.to_xhtml(indent: 0)
    end

    #
    #=== プラグインをスクリプトブロックに変換したコンテンツを返す
    #
    #
    def display_style_content(html)
      ret = normalize_content(html)
      ret = cleanup(ret)
      ret = plugin_tag_to_erb(ret)
      ret
    end

    #
    #=== 新規コンテンツ作成
    # ページリンク、アンケート項目、編集履歴の作成も行う
    #
    def save_with_normalization(user)

      # 機種依存文字変換失敗時に挿入されるタグを削除する
      self.content = remove_tmp_tags(content) if content.present? && self.content_changed?
      self.mobile = remove_tmp_tags(mobile) if mobile.present? && self.mobile_changed?

      self.content ||= ""
      self.mobile ||= ""

      begin
        self.transaction do
          self.admission = page_status[:editing]
          self.top_news = top_news_status[:no]
          self.format_version = current_format_version
          self.last_modified = Time.zone.now

          if self.content_changed?
            self.content = content.split("\n").inject("") {|s, l| s += l.strip}
            normalize_pc!
            create_page_links
            replace_links_with_core
            self.content = plugin_tag_to_erb(content)
          end

          if self.mobile_changed?
            normalize_mobile!
            self.mobile = plugin_tag_to_erb(mobile)
          end

          self.save!
          revision = ::PageRevision.new(last_modified: self.last_modified, user_id: user.id)
          page.new_revision(revision)
        end
        true
      rescue =>e
        logger.fatal(%Q!#{$!} : #{$@.join("\n")}!)
        false
      end
    end

    #
    #=== contentのvalidation
    #
    def validate_content(conv = false)
      self.content = _validate_content(content || '', conv)
      return errors.empty?
    end

    #
    #=== mobile_contentのvalidation
    #
    def validate_mobile_content(conv = false)
      self.mobile = _validate_content(mobile || '', conv)
      return errors.empty?
    end

    #
    #=== 非公開ページのステータス更新処理
    #
    def update_as_private(current_user, page_content_params, term_params)
      term_params ||= {}
      old_admission = admission
      self.attributes = page_content_params
      self.last_modified = Time.now if publish?

      if news_title.blank?
        self.section_news = PageContent.section_news_status[:no]
      else
        validate_news_title
      end

      # 公開期間設定
      if term_params[:switch] == "on"
        if term_params[:end_date_enable].blank?
          if begin_date >= end_date
            errors.add(:begin_date,
              I18n.t("activerecord.errors.models.page_content.attributes.begin_date.invalid"))
          elsif end_date < Time.now
            errors.add(:end_date,
              I18n.t("activerecord.errors.models.page_content.attributes.end_date.invalid"))
          end
        else
          self.end_date = nil
        end
      else
        self.begin_date = nil
        self.end_date = nil
      end

      # メールアドレスのチェック
      validate_email

      if errors.any?
        self.admission = old_admission
        return false
      end

      begin
        self.transaction do
          if publish?
            self.last_modified = Time.now
            self.latest = true
          end
          self.save!
          publish! if publish?
        end
        send_mail(current_user, admission)
        return true
      rescue => e
        logger.fatal(%Q!#{$!} : #{$@.join("\n")}!)
        return false
      end
    end

    #
    #=== 公開ページのステータス更新処理
    #
    def update_as_public(current_user, page_content_params)
      old_admission = admission

      self.attributes = page_content_params
      validate_email
      validate_last_modified

      if errors.any?
        self.admission = old_admission
        return false
      end

      begin
        is_send_mail = false
        self.transaction do
          if old_admission != admission
            case
            when publish?
              publish!
            when reject?
              is_send_mail = true
              reject!
            when cancel?
              cancel!
            end
          end
          self.save!
        end
        send_mail(current_user, admission) if is_send_mail
        return true
      rescue => e
        logger.fatal(%Q!#{$!} : #{$@.join("\n")}!)
        return false
      end
    end

    #
    #=== 公開中にしたときに行う処理
    #
    def publish!
      create_page_links
      clear_history
      update_remove_attachment_job
      add_publish_job

      # コピーしたページのジョブ登録を行う
      page.copies.each do |c|
        add_publish_job(c)
      end
    end

    #
    #=== 公開停止依頼にしたときに行う処理
    #
    def reject!
      add_reject_job
      # コピーしたページのジョブ登録を行う
      page.copies.each { |c| add_reject_job(c) }
    end

    #
    #=== 公開停止にしたときに行う処理
    #
    def cancel!
      add_cancel_job
      # コピーしたページのジョブ登録を行う
      page.copies.each { |c| add_cancel_job(c) }
    end

    #
    #=== メール送信処理
    #
    def send_mail(user, status, top = nil)
      if top.nil?
        begin
          case status.to_i
          when page_status[:request]
            Susanoo::PageNotifyMailer.publish_request(user, self).deliver
          when page_status[:reject]
            Susanoo::PageNotifyMailer.publish_reject(user, self).deliver
          when page_status[:publish]
            Susanoo::PageNotifyMailer.publish(user, self).deliver
          end
        rescue Net::SMTPError
          logger.fatal(%Q!#{$!} : #{$@.join("\n")}!)
        end

        if status.to_i == page_status[:publish] && self.top_news == top_news_status[:request]
          begin
            Susanoo::PageNotifyMailer.top_news_status_request(user, self).deliver
          rescue Net::SMTPError
            logger.fatal(%Q!#{$!} : #{$@.join("\n")}!)
          end
        end
      else # top
        begin
          case status.to_i
          when @@top_news_status[:reject]
            Susanoo::PageNotifyMailer.top_news_status_reject(user, self).deliver
          when @@top_news_status[:yes]
            Susanoo::PageNotifyMailer.top_news_status_yes(user, self).deliver
          end
        rescue Net::SMTPError
          logger.fatal(%Q!#{$!} : #{$@.join("\n")}!)
        end
      end
    end

    #
    #=== 公開期間の削除処理
    #
    def destroy_public_term
      waiting_content = page.waiting_content
      term_flag = in_publish?

      destroy_jobs = Job.where('action =? AND arg1 = ?', Job::CANCEL_PAGE, page.id.to_s)
      if waiting_content
        if self == waiting_content
          Job.where('action IN (?) AND arg1 = ?', [Job::CREATE_PAGE, Job::CANCEL_PAGE], page.id.to_s).destroy_all
          Job.create(action: Job::CREATE_PAGE, arg1: page.id.to_s, datetime: Time.now)
          arg1 = page.url_base_path + '.data/'
          jobs = Job.where('action = ? AND arg1 = ? AND datetime = ?', Job::ENABLE_REMOVE_ATTACHMENT, arg1, self.begin_date)
          # update_allは使わない。update_attributeではバリデーション等を無視する
          jobs.each{|job|job.update_attribute(:datetime, Time.now)}
        else
          destroy_jobs.where("NOT datetime = ?", waiting_content.end_date).destroy_all
        end
      else
        destroy_jobs.destroy_all
      end
      update_attrs = {begin_date: nil, end_date: nil}
      unless self == waiting_content
        if !term_flag && self.publish?
          Job.create(action: Job::CREATE_PAGE, arg1: page.id.to_s, datetime: Time.now)
        elsif term_flag && self.cancel?
          Job.create(action: Job::CREATE_PAGE, arg1: page.id.to_s, datetime: Time.now)
          update_attrs.merge!(admission: page_status[:publish])
        end
      end
      self.update_attributes(update_attrs)
    end

    def section_news?
      self.section_news == PageContent.section_news_status[:yes]
    end

    def top_news?
      self.top_news == PageContent.top_news_status[:yes]
    end

    #=== 携帯本文の使用できないタグの削除
    def cleanup_mobile_content(html = mobile)
      c = editable_class

      # アンケートは削除する
      html = html.gsub(/<%=\s*plugin\(\s*'form_([^']*?)',\s'([^']*?)\*?'(?:,\s('.*?))?\)\s*%>/m, '')

      # HTML解析時にスクリプトブロックが削除されてしまうため一時的にエスケープ
      html.gsub!(/<%= /, '&lt;%= ')
      html.gsub!(/ %>/, ' %&gt;')

      doc = Nokogiri::HTML.fragment(html)
      elems = doc.css("div.#{c[:field]}")
      elems = [doc] if elems.empty?
      elems.each do |e|
        h = convert_to_nbsp(e.inner_html)
        h = remove_forbidden_mobile_tags(h)
        e.inner_html = h
      end
      html = convert_to_nbsp(doc.to_html)
      html.gsub!(/&lt;%= /, '<%= ')
      html.gsub!(/ %&gt;/, ' %>')
      html.gsub!(%r!<(/?)(?:img)\b[^>]*>!m, '')
      html.gsub!(/<!--.+?-->/, '')
      self.mobile = html
    end

    #
    #=== PageViewのインスタンスを返す
    #
    def page_view(html: nil, is_mobile: false, plugin_convert: false)
      html = display_style_content(html) if plugin_convert

      if is_mobile
        self.mobile = html
      else
        self.content = html
      end
      Susanoo::PageView.new(page_content: self, mobile: is_mobile)
    end

    #
    #=== PageViewのインスタンスを返す
    #
    def edit_style_page_view(template_id: nil, is_mobile: false, is_copy: false, copy_id: nil)
      if content.blank?
        if copy_id.present?
          self.copy_from!(PageContent.find(copy_id))
        elsif template_id.present?
          templates = ::PageTemplate.where(id: template_id)
          self.content = templates.first.content if templates.present?
        end
      end

      if is_mobile
        if is_copy
          self.mobile = self.content
          cleanup_mobile_content
        end
        self.mobile = edit_style_mobile_content
      else
        self.content = edit_style_content
      end
      Susanoo::PageView.new(page_content: self, edit: true, mobile: is_mobile)
    end

    #
    #=== ページステータスを変更可能か否かを返す
    #
    def page_status_editable?
      !(self.editing? && self.edit_required?)
    end

    #
    #=== コンテンツを過去の公開として扱う
    # 最新フラグをfalseに変更し、PageLinkを削除する
    #
    def to_history
      self.update_attributes(latest: false) if self.latest
      self.links.clear
    end

    #
    #=== コンテンツ内のリンクを置換する
    #
    def replace_links_with_core
      # Nothing
    end

    #
    #=== コピー元のページコンテンツの内容からcontentや画像をコピーする
    #
    def copy_from!(from_page_content)
      # 画像ファイルをコピーする
      to_path = Rails.root.join('files', Rails.env, self.page.id.to_s).to_s
      from_path = Rails.root.join('files', Rails.env, from_page_content.page.id.to_s).to_s

      files = Dir.glob(from_path + "/*").map do |file_path|
        file_path if file_path =~ Susanoo::Assets::Base.regex[:image]
      end.compact
      FileUtils.mkdir to_path if files.present? && !File.exists?(to_path)
      files.each { |file_path| FileUtils.cp file_path, to_path }

      # contentをコピーする
      # CMS内の画像へのリンク(aタグのhref要素、imgタグのsrc要素)は自身のページのファイルを見るよう置換する
      doc = Nokogiri::HTML(plugin_erb_to_tag(from_page_content.content))
      re_from = Regexp.new("^#{from_page_content.page.url_base_path}")
      [["img", "src"], ["a", "href"]].each do |tag, attr|
        doc.xpath("//#{tag}").each do |node|
          if node[attr] =~ Susanoo::Assets::Base.regex[:image] &&
              node[attr] =~ Regexp.new("^#{from_page_content.page.url_base_path}.data/")
            node[attr] = node[attr].gsub(re_from, self.page.url_base_path)
          end
        end
      end

      self.content = plugin_tag_to_erb(doc.to_html)
    end

    private

      def _validate_content(org, conv)
        text = remove_tmp_tags(org)

        values = []  # buttonのvalue値。機種依存文字変換させずに、一旦退避させる
        doc = Nokogiri::HTML(text)
        doc.xpath("//button").each do |e|
          values << e[:value]
          e[:value] = ""
        end
        text = convert_to_nbsp(doc.xpath("//body/*").to_html) if values.present?
        invalid_chars = Susanoo::Filter::non_japanese_chars(text)
        if invalid_chars.present?
          if conv
            text2 = Susanoo::Filter::convert_non_japanese_chars(text, true)
            cannot_converted = text2.scan(%r!<span\s*class="invalid"\s*>(.+?)</span\s*>!).collect{|i,| CGI.unescapeHTML i}.uniq
            if cannot_converted.present?
              errors.add(:content,
                I18n.t("activerecord.errors.models.page_content.attributes.content.cannot_convert_invalid_chars",
                  chars: cannot_converted.join(",")))
            end

            converted_chars = invalid_chars.collect do |e|
              converted_char = Susanoo::Filter::CONV_TABLE[e]
              converted_char ? "#{e} -> #{Susanoo::Filter::CONV_TABLE[e]}" : nil
            end.compact
            if converted_chars.present?
              errors.add(:content,
                         I18n.t("activerecord.errors.models.page_content.attributes.content.convert_invalid_chars",
                                chars: converted_chars.join(",")))
            end
            result = text2
          else
            errors.add(:content,
              I18n.t("activerecord.errors.models.page_content.attributes.content.invalid_chars",
                chars: invalid_chars.uniq.join(",")))
            result = text
          end
        else
          result = text
        end
        if values.present?
          result = Nokogiri::HTML(result).xpath("//button").each_with_index do |e, i|
            e[:value] = values[i]
          end.xpath("//body/*").to_html
          convert_to_nbsp(result)
        else
          result
        end
      end

      #
      #===ページ編集時に一時的に挿入するタグを削除する
      #
      def remove_tmp_tags(org)
        text = convert_to_nbsp(org)
        text.gsub!(/<!--.*?-->/, '')
        # IE8使用時には、ブラウザから送られてくるhtmlのタグが全て大文字になったので、iを追加
        # さらに、IE8だとclassの属性値の前の"が無かったので、ない場合も対応できるよう修正
        text.gsub!(%r!<span[^>]*?\s*class="?invalid"?[^>]*>([^<]+)</span\s*>!i, '\1')
        text.gsub!(%r!<img([^>]*?)\s*class="?invalid"?!i, '<img\1')
        text
      end

      #
      #=== URIがローカルを指すかどうかを返す
      #
      def local_uri?(uri)
        (uri.relative? && !uri.path.empty?) || (uri.scheme == 'http' && Settings.local_domains.include?(uri.host))
      end

      #
      #=== コンテンツから非推奨のタグ、属性を取り除く
      #
      def cleanup(html)
        return if html.blank?

        html = convert_to_nbsp(html)

        # remove script tags and script attributes
        html.gsub!(%r!<(script)\b.*?</\1>!m, '')
        html.gsub!(%r!(<[^>]*) on[a-z]+="[^"]*"([^>]*>)!, '\1\2')

        # remove basefont tags
        html.gsub!(%r!<(/?)basefont\b[^>]*>!m, '')

        # remove img border
        html.gsub!(%r!(<img[^>]*) border=".*?"!, '\1')

        # remove font tags
        html.gsub!(%r!<(/?)font\b[^>]*>!m, '')

        # remove target attributes
        html.gsub!(%r!(<[^>]*) target="[^"]*"([^>]*>)!, '\1\2')

        # remove iframe tags
        html.gsub!(%r!<(iframe)\b.*</\1>!m, '')

        # remove frameset, frame, noframe tags
        html.gsub!(%r!<(/?)(?:frameset|frame|noframe)\b[^>]*>!m, '')

        doc = Nokogiri.HTML("<body>" + html.gsub(/&/, '&amp;') + "</body>")
        # remove blockquote tags
        doc.css('blockquote').remove
        html = doc.at_css('body').inner_html.gsub(/&amp;/, '&')

        # remove mce* class attributes
        html.gsub!(%r!(<[^>]*?)\s*class="mce\w*"([^>]*>)!, '\1\2')

        # remove mce* attributes
        html.gsub!(%r!(<[^>]*?)\s*mce_\w+="[^"]*"([^>]*>)!, '\1\2')

        # change align and valign attributes
        html.gsub!(%r!(<[^>]+?)\bvalign="([^"]*)"([^>]*>)!, '\1style="vertical-align: \2"\3')

        # change p to div in tables' parent nodes
        html.gsub!(%r!<p\b([^>]*?)>(\s*<table\b[^>]*?>.*?</table>\s*)</p>!im, '<div\1>\2</div>')

        html
      end

      #
      #=== HTMLをXHTMLに変換する
      #
      #
      def to_xhtml(html)
        doc = Nokogiri::HTML.fragment(html)
        converted = doc.to_xhtml(indent: 0)
        converted
      end

      #
      #=== 引数のHTMLを正規化する
      # 編集用のCSSの削除、align属性を持つテーブルのラッピングを行う
      #
      def normalize_content(html)
        c= editable_class
        doc = Nokogiri::HTML.parse(html)

        # 編集料のタグを削除
        doc.css('*').remove_class("#{c[:block]}")
        doc.css('*').remove_class("#{c[:div]}")
        doc.css('*').remove_class("#{c[:highlight]}")
        doc.css("div.#{c[:heading]}").each do |div|
          div.swap(div.children)
        end
        doc.xpath('//*[@class=""]').remove_attr('class')
        doc = wrap_table_having_align(doc)
        doc.at_css("body").children.to_xhtml(indent: 0)
      end

      #
      #=== align 属性を持つテーブルから align を抜き出し div でラップする
      #
      def wrap_table_having_align(doc)
        doc.css("table").each do |node|
          if node.attr("align").present?
            # align属性を削除
            align = node.attr("align").downcase
            node.remove_attribute("align")

            # tableに配置用クラスを追加
            set_table_align_classes(node, align)

            # tableをdivでラッピングする
            parent = node.parent
            if parent && parent.name == 'div' && parent["class"].present? &&
              parent["class"].downcase =~ /table_div_(left|center|right)/
              # すでにdivでラッピング済みの場合、親のdivのクラスを書き換える
              set_div_align_classes(parent, align)
            else
              new_parent = doc.parse("<div class='table_div_#{align}'></div>").first
              node.add_next_sibling(new_parent)
              new_parent.add_child(node)
            end
          end
        end
        doc
      end

      #
      #=== tableタグから表示位置用のクラスを除去する
      #
      def set_table_align_classes(node, align="")
        node_classes = (node["class"] || "").split(" ")
        node_classes.delete("table_left")
        node_classes.delete("table_center")
        node_classes.delete("table_right")
        node_classes << "table_#{align}" if align.present?
        node["class"] = node_classes.join(" ")
      end

      #
      #=== divタグら表示位置用のクラスを除去する
      #
      def set_div_align_classes(node, align="")
        node_classes = (node["class"] || "").split(' ')
        node_classes.delete("table_div_left")
        node_classes.delete("table_div_center")
        node_classes.delete("table_div_right")
        node_classes << "table_div_#{align}" if align.present?
        node["class"] = node_classes.join(' ')
      end

      #
      #===コンテンツ中のリンクを正規化する
      #
      def normalize_content_links
        path = URI.parse(page.genre.path)
        content_each_local_links do |uri|
          uri = local_uri + path + uri if uri.relative?
          uri.path.sub!(/\.html?$/i, '.html')
          uri.path.sub!(%r|/index\.html$|, '/')
          uri.scheme = nil
          uri.host = nil
          uri.to_s
        end
        content
      end

      #
      #=== 内部リンク の each
      #
      def content_each_local_links
        self.content = content.gsub(/(<[a-z]+\s+[^>]*?(?:href|src)=")([^"]+)/im) do |str|
          pre = $1
          uri = $2
          begin
            uri = URI.parse(uri)
            if local_uri?(uri)
              uri = yield uri
            end
          rescue
          end
          "#{pre}#{uri}"
        end
      end

      #
      #== コンテンツ内のリンクを探す
      #
      def find_links(doc)
        _links = []
        doc.css("*").each do |node|
          attr = nil
          case node.name
          when "base", "a", "area", "link"
            attrs = ['href']
          when "img"
            attrs = ['src', 'longdesc', 'usemap']
          when "object"
            attrs = ['classid', 'codebase', 'data', 'usemap']
          when "q","blockquote","ins","del"
            attrs = ['cite']
          when "form"
            attrs = ['action']
          when "input"
            attrs = ['src', 'usemap']
          when "head"
            attrs = ['profile']
          when "script"
            attrs = ['src', 'for']
          end

          if attrs
            attrs.each do |attr|
              _links << URI.parse(node.attr(attr)) if node.attr(attr)
            end
          end
        end
        _links
      end

      #
      #=== プラグイン用のタグをERBのスクリプトブロックに変換する
      #
      def plugin_tag_to_erb(html)
        html.gsub(/<button .*?<\/button>/) do |b|
          tag = ""
          html_class  = b.match(/class="(.*?)"/)
          if html_class.blank? || html_class[1] !~ /#{editable_class[:plugin]}/
             b
          else
            name  = b.match(/name="(.*?)"/)
            value = b.match(/value="(.*?)"/)
            if name
            tag += "<%= plugin('#{name[1]}'"
            if value
              args = value[1].split(",")
              args.each { |a| tag += ", '#{a}'"}
            end
            tag += ") %>"
            end
            tag ? tag : b
          end
        end
      end

      #
      #=== プラグイン用のスクリプトブロックをタグに変換する
      #
      def plugin_erb_to_tag(html)
        html.gsub(/<%=\s*plugin.*?%>/) do |b|
          params = b.scan(/'([^\']*?)'/).flatten
          name   = params.first
          values = (params.size > 1) ? params[1..-1] : []
          "<button class='#{editable_class[:block]} #{editable_class[:plugin]}' name='#{name}' value='#{values.join(',')}'>#{I18n.t(name, scope:"widgets.items")}</button>"
        end
      end

      #
      #=== HTMLの整形
      #
      def beautify_html(str)
        str.gsub(/\r?\n/, '').gsub(%r!\s*/>!, ' />').gsub(%r!</(?:blockquote|dd|div|dl|dt|form|h[1-6]|hr|li|ol|p|pre|table|tbody|td|tfoot|th|thead|tr|ul)>!, "\\&\n").gsub(%r!<(?:dl|ol|table|tbody|tfoot|thead|tr|ul)\b[^>]*>!, "\\&\n")
      end

      #
      #=== 機種依存文字のチェックを行う
      #
      def validate_news_title
        if news_title.present?
          invalid_chars = Susanoo::Filter.non_japanese_chars(news_title)
          if invalid_chars.present?
            errors.add(:news_title,
              I18n.t("activerecord.errors.models.page_content.attributes.news_title.invalid_chars",
              chars: invalid_chars.join(",")))
            return false
          end
        end
        return true
      end

      #
      #=== Eメールを検証する
      #
      def validate_email
        if email && email =~ /@/
          errors.add(:email,
            I18n.t("activerecord.errors.models.page_content.attributes.email.invalid"))
          return false
        else
          return true
        end
      end

      #
      #=== 最終更新日時
      #
      def validate_last_modified
        if last_modified > Time.zone.now
          errors.add(:last_modified,
            I18n.t("activerecord.errors.models.page_content.attributes.last_modified.invalid"))
          return false
        else
          return true
        end
      end

      #
      #=== 公開にあたってJOBの作成処理
      #
      def add_publish_job(target = page)
        jobs = Job.where("arg1 = ?", target.id.to_s)
        if !(waiting_content = target.waiting_content) || self == waiting_content
          jobs.destroy_all(['action = ? AND datetime >= ?', Job::CANCEL_PAGE, self.begin_date || Time.now])
          jobs.destroy_all(['action = ? AND datetime <= ?', Job::CREATE_PAGE, Time.now])
        else
          jobs.destroy_all(['action = ? AND datetime >= ? AND NOT datetime = ?', Job::CANCEL_PAGE, self.begin_date || Time.now, waiting_content.end_date])
          jobs.destroy_all(['action = ? AND datetime <= ? AND NOT datetime = ?', Job::CREATE_PAGE, Time.now, waiting_content.begin_date])
        end
        Job.create(action: Job::CREATE_PAGE, arg1: target.id.to_s, datetime: self.begin_date || Time.now)
        Job.create(action: Job::CANCEL_PAGE, arg1: target.id.to_s, datetime: self.end_date) if self.end_date
      end

      #
      #== 添付ファイル更新
      #
      def update_remove_attachment_job
        if Job.where('action = ? AND arg1 like ?', Job::REMOVE_ATTACHMENT, page.url_base_path + '.data/%').exists?
          if job = Job.find_by(action: Job::ENABLE_REMOVE_ATTACHMENT, arg1: page.url_base_path + '.data/')
            job.update_attribute(:datetime, self.begin_date || Time.now)
          else
            Job.create(action: Job::ENABLE_REMOVE_ATTACHMENT,
                       arg1: page.url_base_path + '.data/',
                       datetime: self.begin_date || Time.now)
          end
        end
      end

      #
      #=== 携帯コンテンツに使用できないタグを削除する
      #
      def remove_forbidden_mobile_tags(str)
        ret = str.dup
        ret.gsub!(%r!(<[^>]*) (?:class|style|align)="[^"]*"([^>]*>)!, '\1\2')
        # remove font, span tags
        ret.gsub!(%r!<(/?)(?:font|span)\b[^>]*>!m, '')
        return ret
      end

      #
      #=== ActionViewを取得する
      #
      def action_view(assigns = {})
        controller = Susanoo::VisitorsController.new
        action_view = ActionView::Base.new(Rails.configuration.paths['app/views'], assigns, controller)
        action_view.class_eval do
          include Rails.application.routes.url_helpers

          def protect_against_forgery?
            false
          end
        end
        action_view
      end

      #
      #=== UTF-8の半角空白を&nbsp;に変換する
      #
      def convert_to_nbsp(html)
        nbsp = Nokogiri::HTML("&nbsp;").text
        html.gsub(nbsp, "&nbsp;")
      end

      #
      #=== 古いページコンテンツを掃除する
      # 公開処理したコンテンツが公開済みの場合
      #  全履歴の latest フラグを false にし、PageLink を削除する
      #
      # 公開処理したコンテンツが公開待ちの場合
      #  直前の公開中コンテンツ以外の latest フラグを false にし、PageLink を削除する
      #
      def clear_history
        histories = page.contents.where.not(id: id).eq_public.order('id DESC')
        if histories.blank?
          return
        end

        if self.publish_started?
          histories.each { |h| h.to_history }
        else
          histories.each_with_index do |h, i|
            if i != 0
              h.to_history
            else
              h.to_history unless h.in_publish?
            end
          end
        end

        l = Settings.page_content.limit
        if l.present? && l >= 1
          if histories.size >= l
            histories[(l-1)..-1].each do |h|
              h.destroy
            end
          end
        end
      end

      #
      #=== 公開却下時のジョブを登録する
      #
      def add_reject_job(target = page)
        jobs = Job.where("arg1 = ?", target.id.to_s)
        jobs.destroy_all(['action =? and datetime =?', Job::CREATE_PAGE, self.begin_date]) if self.begin_date
        jobs.destroy_all(['action =? and datetime =?', Job::CANCEL_PAGE, self.end_date])   if self.end_date
        if (pc = target.publish_content) && pc.end_date
          unless jobs.where('action = ? AND datetime = ?', Job::CANCEL_PAGE, pc.end_date).exists?
            Job.create(action: 'cancel_page', arg1: target.id.to_s, datetime: pc.end_date)
          end
        end
      end

      #
      #=== 公開停止時のジョブを登録する
      #
      def add_cancel_job(target = page)
        jobs = Job.where("arg1 = ? AND action = ?", target.id.to_s, Job::CANCEL_PAGE)
        if wp = target.waiting_content
          jobs.where!('NOT datetime = ?', wp.end_date)
        end
        jobs.delete_all
        Job.create(action: Job::CANCEL_PAGE, arg1: target.id.to_s, datetime: Time.now)
      end
  end

  module ClassMethods
    #
    #=== ページの公開状況設定画面で表示する非公開時のステータスを返す
    #
    def private_status_list(user)
      if user.editor?
        [page_status[:editing], page_status[:request]]
      elsif user.authorizer?
        [page_status[:editing], page_status[:request], page_status[:reject], page_status[:publish]]
      elsif user.admin?
        [page_status[:editing], page_status[:request], page_status[:reject], page_status[:publish]]
      else
        []
      end
    end

    #
    #=== ページの公開状況設定画面で表示する公開時のステータスを返す
    #
    def public_status_list(user)
      if user.authorizer?
        [page_status[:publish], page_status[:cancel]]
      elsif user.admin?
        [page_status[:publish], page_status[:cancel]]
      else
        []
      end
    end

    #
    #=== admission の表示名を返す
    #
    def admission_label(value)
      I18n.t("shared.admission.#{page_status.key(value)}")
    end
  end
end
