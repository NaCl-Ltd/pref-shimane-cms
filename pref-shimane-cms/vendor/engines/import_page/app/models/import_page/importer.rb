#
#= 一括ページ取込モデル
#
module ImportPage
  class Importer
    extend ActiveModel::Translation

    class_attribute :logger
    self.logger = Rails.logger

    class_attribute :extract_dirname
    self.extract_dirname = 'extract'

    class_attribute :visitor_data_root
    self.visitor_data_root = Settings.visitor_data_path

    attr_reader :messages
    attr_reader :store_dir, :section_id, :genre, :user_id, :file

    def self.i18n_message_scope(attr = :base)
      "#{i18n_scope}.errors.models.#{model_name.i18n_key}.attributes.#{attr}"
    end

    def self.run
      Dir.glob(File.join(Settings.import_page.pool_path, '**')).sort.each do |entry|
        next unless File.directory?(entry) && /^\d+$/ =~ File.basename(entry)

        importer = new(File.basename(entry))
        importer.run
      end
    end

    def initialize(section_id)
      @messages = []
      @upload_file = UploadFile.find_by_section_id( section_id )
      @store_dir = UploadFile.store_path( section_id )
      if @upload_file
        @section_id = @upload_file.section_id
        @genre = @upload_file.genre
        @user_id = @upload_file.user_id
        @file = @upload_file.file
      end
    end

    def run
      import

    rescue => e
      logger.error e.message
      logger.error e.backtrace.join("\n")
    ensure
      begin
        FileUtils.rm_f file.path if file
      rescue => e
        errors << I18n.t(:compressed_file_not_deleted, scope: self.class.i18n_message_scope)
        logger.error e.message
        logger.error e.backtrace.join("\n")
      end
      write_messages
    end

    def import
      with_transaction do
        import_without_transaction

        # DBの巻き戻し
        raise ActiveRecord::Rollback unless messages.empty?
      end
    end

    def import_without_transaction
      messages.clear

      return unless file

      unless genre
        messages << I18n.t(:genre_not_found, scope: self.class.i18n_message_scope)
        return
      end

      extract! do |exdir|
        exdir = Pathname.new(exdir)

        queue = Dir[exdir.join('**')].sort.map{|e| [e, self.genre]}
        while (entry, genre = queue.shift; entry)
          case
          when FileTest.directory?(entry)
            new_genre = import_directory(entry, genre)

            if new_genre
              sub_entries = Dir[File.join(entry, '**')].sort
              # フォルダ内を優先して探索する
              queue.unshift( *sub_entries.map{|e| [e, new_genre]} )
            end
          when FileTest.file?(entry)
            import_html_file(entry, genre) if /^\.(html|htm)$/i =~ File.extname(entry)
          end
        end
      end
    rescue ExtractArchiveError
      messages << I18n.t(:compressed_file_broken, scope: self.class.i18n_message_scope)
    end

    def tmp_visitor_data_root
      store_dir.join('assets')
    end

    private

    def import_directory(path, genre)
      genre_importer = Importers::GenreImporter.new(section_id, genre, user_id, path)
      genre_importer.logger = self.logger
      new_genre = genre_importer.import

      unless genre_importer.messages.blank?
        exdir = store_dir.join(extract_dirname)
        genre_path = File.join('/', path.sub(/^#{exdir}/, ''), '/')
        caption = I18n.t(:result, scope: self.class.i18n_message_scope(:genre), path: genre_path)
        add_message caption, genre_importer.messages
      end
      new_genre
    end

    def import_html_file(path, genre)
      page_importer = Importers::PageImporter.new(section_id, genre, user_id, path)
      if Page.connection.transaction_open?
        page_importer.visitor_data_root = self.tmp_visitor_data_root 
      end
      page_importer.logger = self.logger
      new_page = page_importer.import

      unless page_importer.messages.blank?
        exdir = store_dir.join(extract_dirname)
        page_path = File.join('/', path.sub(/^#{exdir}/, ''))
        caption = I18n.t(:result, scope: self.class.i18n_message_scope(:page), path: page_path)
        add_message caption, page_importer.messages
      end
      new_page
    end

    def extract!
      exdir = store_dir.join(extract_dirname)
      err = extract_archive(file.path, exdir)
      unless err.blank?
        logger.error("Failed to extract archive (#{file.path})")
        logger.debug(err)
        raise ExtractArchiveError
      end

      yield exdir
    ensure
      FileUtils.rm_rf exdir if exdir
    end

    def extract_archive(file, exdir)
      err = %x{unzip -qq -o #{file} -d #{exdir} 2>&1}
      err = '' if $?.exitstatus == 0
      err
    end

    def add_message(caption, messages = [])
      @messages << {title: caption, messages: messages}
    end

    def write_messages
      File.write(store_dir.join('error'), Array(messages).to_json)
    end

    def with_transaction
      Page.transaction do
        yield

        if tmp_visitor_data_root.exist?
          FileUtils.mkdir_p(self.visitor_data_root)
          FileUtils.cp_r(
            Dir[tmp_visitor_data_root.join('**')],
            self.visitor_data_root
          )
        end
      end

    ensure
      FileUtils.rm_rf tmp_visitor_data_root
    end
  end
end
