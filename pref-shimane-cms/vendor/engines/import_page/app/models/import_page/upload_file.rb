#
#= 一括ページ取込モデル
#
module ImportPage
  class UploadFile
    include ActiveModel::Model
    extend  ActiveModel::Translation

    class_attribute :pool_path, :max_file_size, :extname_regex
    self.pool_path = Settings.import_page.pool_path.freeze
    self.max_file_size = Settings.import_page.max_file_size.freeze
    self.extname_regex = %r/^\.(zip)$/i.freeze

    attr_accessor :section_id, :user_id, :genre_id, :file, :filename

    validates_presence_of :section_id
    validates_presence_of :user_id
    validates_presence_of :genre_id
    validates_presence_of :file
    validate :file_validation

    def self.store_path(section_id)
      Pathname.new(pool_path).join("#{section_id}")
    end

    def self.find_by_section_id(section_id)
      return nil if section_id.blank?
      store_path = self.store_path(section_id)
      return nil unless store_path.exist?

      upload_file = new
      upload_file.section_id = section_id
      upload_file.genre_id = File.read(store_path.join('genre_id')) rescue nil
      upload_file.user_id  = File.read(store_path.join('user_id'))  rescue nil
      upload_file.file = File.open(Dir[store_path.join('*.zip')].first, 'r') rescue nil
      upload_file.filename = File.basename(upload_file.file) rescue nil
      upload_file
    end

    def initialize(section_id = nil)
      @section_id = section_id
      @store_dir = self.class.store_path(section_id)
    end

    [ [:section, Section, :section_id],
      [:user,    User,    :user_id],
      [:genre,   Genre,   :genre_id],
    ].each do |(m, klass, attr)|
      module_eval <<-__CODE__, __FILE__, __LINE__ + 1
        def #{m}
          @association_cache ||= {}
          unless @association_cache.has_key?(:#{m})  # cached?
            @association_cache[:#{m}] =
              self.#{attr} ? (#{klass}.find(self.#{attr}) rescue nil) : nil
          end
          @association_cache[:#{m}]
        end

        def #{m}=(record)
          @association_cache ||= {}
          if record && !record.is_a?(#{klass})
            raise AssociationTypeMismatch
          end
          self.#{attr} = record.try(:id)      # with uncache
          @association_cache[:#{m}] = record  # cache
          record
        end

        def #{attr}_with_association=(v)
          self.#{attr}_without_association = v
          @association_cache && @association_cache.delete(:#{m})  # uncache
          v
        end
        alias_method_chain :#{attr}=, :association

        def #{attr}_with_cast=(v)
          self.#{attr}_without_cast =
            v.blank? ? nil : ActiveRecord::ConnectionAdapters::Column.value_to_integer(v)
        end
        alias_method_chain :#{attr}=, :cast
      __CODE__
    end

    def store!
      raise UploadFileInvalid unless valid?

      store_dir = self.class.store_path(section_id)
      FileUtils.mkdir_p store_dir
      File.write store_dir.join('genre_id'), genre_id
      File.write store_dir.join('user_id'),  user_id
      unless file.path == store_dir.join(filename).to_s
        FileUtils.cp file.path, store_dir.join(filename)
      end
      self
    end

    def store
      return false unless valid?

      store_dir = self.class.store_path(section_id)
      FileUtils.mkdir_p store_dir
      File.write store_dir.join('genre_id'), genre_id
      File.write store_dir.join('user_id'),  user_id
      unless file.path == store_dir.join(filename).to_s
        FileUtils.cp file.path, store_dir.join(filename)
      end
      true
    end

    def remove
      unless self.section_id.blank?
        FileUtils.rm_rf self.class.store_path(section_id)
      end
      self
    end

    def stored?
      return false if section_id.blank? || filename.blank?

      self.class.store_path(section_id).join(filename).exist?
    end

    def results
      store_dir = self.class.store_path(section_id)
      File.read(store_dir.join('error')) rescue nil
    end

    def validates_importable_genre
      if genre && !genre.normal?
        errors.add(:genre_id, :unusable, genre: genre.name)
      end
    end

    private

    def file_validation
      err_count = errors.size

      validates_extname_of_filename
      validates_format_of_filename
      validates_size_of_file

      # 上記の検証が失敗した場合はここで検証を終了
      return if errors.size > err_count

      validates_virus_of_file
      validates_html_files_in_file
    end

    def validates_extname_of_filename
      unless filename.blank? || extname_regex =~ File.extname(filename)
        errors.add(:base, :invalid_extname)
      end
    end

    def validates_format_of_filename
      unless filename.blank? || /\A[a-zA-Z0-9\-_.]+\z/i =~ filename.sub(/\.[^\.]*?$/i, '')
        errors.add(:filename, :invalid)
      end
    end

    def validates_size_of_file
      if file && file.size > max_file_size
        errors.add(:file,
                   :greater_than,
                   size: ActiveSupport::NumberHelper.number_to_human_size(max_file_size, prefix: :binary))
      end
    end

    def validates_virus_of_file
      if file && !virus_scan_command.blank?
        Dir.mktmpdir('scan', File.dirname(file.path)) do |td|
          # td に file のハードリンクを作成し、ウィルススキャンを行う
          scan_file = File.join(td, File.basename(file.path))
          FileUtils.ln(file.path, scan_file)
          if system(*(virus_scan_command + [scan_file]))
            errors.add(:file, :infected)
          end
        end
      end
    end

    def validates_html_files_in_file
      if file
        file_list = %x{zipinfo -1 #{file.path} 2>/dev/null}
        if $?.exitstatus != 0
          errors.add(:file, :broken)
        elsif /\.html$/i !~ file_list
          errors.add(:file, :has_no_html)
        end
      end
    end

    def virus_scan_command
      Settings.anti_virus.to_a
    end
  end

  class DirectoryNotFound < StandardError; end
  class UploadFileInvalid < StandardError; end
  class AssociationTypeMismatch < StandardError; end

end
