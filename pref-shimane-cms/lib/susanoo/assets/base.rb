module Susanoo
  module Assets
    #
    #=== PaperClip を ActiveRecord なしで使用するための擬似モデルクラス
    #
    class Base
      extend ActiveModel::Naming
      extend ActiveModel::Callbacks

      include ActiveModel::Validations
      include Paperclip::Glue

      @@regex = {
        filename: /\A[a-zA-Z0-9\-\_.]+\z/,
        attachment_file: /\.(docx?|xlsx?|jaw|jbw|jfw|jsw|jtd|jtt|jtw|juw|jvw|pdf|jpe?g|png|gif|rtf|kml|csv|tsv|txt)\z/i,
        image: /\.(jpe?g|png|gif)\z/i
      }

      # Paperclip required callbacks
      define_model_callbacks :save, only: [:after]
      define_model_callbacks :destroy, only: [:before, :after]

      Paperclip.interpolates :page_data do |attachment, style|
        page = attachment.instance.page
        "#{page.genre.path}#{page.name}.data"
      end

      Paperclip.interpolates :page_id do |attachment, style|
        attachment.instance.page.id
      end

      has_attached_file :data,
          url: ':page_data/:basename.:extension',
          path: ':rails_root/files/:rails_env/:page_id/:basename.:extension'

      delegate :url, :path, :styles, :size, :content_type, to: :data

      cattr_reader :regex
      attr_accessor :id
      attr_accessor :page
      attr_accessor :data_file_name
      attr_accessor :data_file_size
      attr_accessor :data_content_type
      attr_accessor :data_updated_at
      attr_accessor :messages

      def initialize(params = {})
        @messages = []
        if params[:page_id].present?
          @page = Page.find(params[:page_id])
        end
      end

      #
      # ページディレクトリにあるファイルを検索する
      #
      def self.find(params = {})
        page = Page.find(params[:page_id])
        files = Dir.glob(Rails.root.join('files', Rails.env.to_s, page.id.to_s, params[:id])).sort
        asset = new
        asset.page = page
        asset.data = File.open(files.first)
        return asset
      end

      # ActiveModel requirements
      def to_model
        self
      end

      def save
        return false unless validate_filename
        return false unless validate_anti_virus
        run_callbacks :save do
        end
        true
      end

      def id
        data_file_name
      end

      #
      #=== 拡張子を返す
      #
      def extname
        data_file_name.present? ? File.extname(data_file_name) : ''
      end

      #
      #=== ファイル名をチェックする
      #
      def validate_filename
        if data_file_name =~ regex[:filename]
          true
        else
          @messages << I18n.t('shared.upload.invalid_file_name')
          false
        end
      end

      #
      #=== ウイルスチェックを行う
      #
      def validate_anti_virus
        command = Settings.anti_virus.to_a
        if command && system(*(command + [data.queued_for_write[:original].path]))
          @messages << I18n.t('shared.upload.infected')
          false
        else
          true
        end
      end

      def image?
        extname =~ regex[:image]
      end

      def url
        "#{page.genre.path}#{page.name}.data/#{data_file_name}"
      end

      def url_content
        url
      end

      def destroy
        files = Rails.root.join('files', Rails.env.to_s, page.id.to_s, data_file_name)
        if page.publish_content
          # datetime is adjusted when the page is exported.
          Job.create(action: Job::REMOVE_ATTACHMENT,
                     arg1: "#{page.path_base}.data/#{data_file_name}",
                     datetime: 10.years.since)
        end
        run_callbacks :destroy do
        end
        true
      end

      def valid?()      true end
      def new_record?() true end
      def destroyed?()  true end

      def errors
        obj = Object.new
        def obj.[](key)         [] end
        def obj.full_messages() [] end
        def obj.any?()       false end
        def obj.empty?() [] end
        obj
      end
    end
  end
end
