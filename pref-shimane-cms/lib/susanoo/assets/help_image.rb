module Susanoo
  module Assets
    class HelpImage < Base
      attr_accessor :help_content_id

      has_attached_file :data,
          url: ':help_content_data/:basename.:extension',
          path: ':rails_root/files/help/:rails_env/:help_content_id/:basename.:extension',
          styles: { original: Proc.new { |instance| instance.resize } }

      Paperclip.interpolates :help_content_id do |attachment, style|
        attachment.instance.help_content_id
      end

      def self.all(params = {})
        images = []
        files = Dir.glob(Rails.root.join('files', 'help', Rails.env.to_s, params[:help_content_id], '*')).sort
        files.grep(regex[:image]).each do |i|
          image = new
          image.help_content_id = params[:help_content_id]
          image.data = File.open(i)
          images << image
        end
        images
      end

      def initialize(params = {})
        @messages = []
        @help_content_id = params[:help_content_id]
      end

      def url
        "/susanoo/admin/help_content_assets/#{self.help_content_id}?data_file_name=#{data_file_name}"
      end

      def url_content
        url
      end

      #
      #=== アップロードファイルを検証する
      #
      def save
        return false unless validate_image_file_type
        return false unless validate_image_size
        return false unless validate_total_image_size
        super
      end

      def resize
        data_file_size > Settings.max_upload_image_size ? '400x266!' : ''
      end

      #
      #=== ファイルの拡張子を検証する
      #
      def validate_image_file_type
        if extname !~ regex[:image]
          @messages << I18n.t('shared.upload.invalid_image_type')
          false
        else
          true
        end
      end

      #
      #=== ファイルサイズを検証する
      #
      def validate_image_size
        if data_file_size > Settings.max_upload_image_size
          @messages << I18n.t('shared.upload.image_size_too_big', size: number_to_human_size(Settings.max_upload_image_size))
          false
        else
          true
        end
      end

      #
      #=== ファイル合計サイズを検証する
      #
      def validate_total_image_size
        if total_image_size + data_file_size > Settings.max_upload_image_total_size
          @messages << I18n.t('shared.upload.image_total_size_too_big', size: number_to_human_size(Settings.max_upload_image_total_size))
          false
        else
          true
        end
      end

      #
      #== ページフォルダにある画像一覧
      #
      def sibling
        Susanoo::Assets::HelpImage.all(help_content_id: self.help_content_id)
      end

      #
      #== ページフォルダにある画像の合計サイズ
      #
      def total_image_size
        total_size = 0
        sibling.each {|_| total_size += _.data_file_size}
        total_size
      end

      private

        def number_to_human_size(number)
          ActiveSupport::NumberHelper.number_to_human_size(number, precision: 0).sub(/b(?:ytes?)?$/i, '').sub(/K$/, 'k').delete(' ')
        end
    end
  end
end

