module Susanoo
  module Assets
    class HelpAttachmentFile < Base
      attr_accessor :help_content_id

      has_attached_file :data,
          url: ':help_content_data/:basename.:extension',
          path: ':rails_root/files/help/:rails_env/:help_content_id/:basename.:extension'

      Paperclip.interpolates :help_content_id do |attachment, style|
        attachment.instance.help_content_id
      end

      #
      # ページディレクトリにあるファイルを検索する
      #
      def self.find(params = {})
        files = Dir.glob(Rails.root.join('files', 'help', Rails.env.to_s, params[:id], params[:data_file_name])).sort
        asset = new
        asset.help_content_id = params[:id]
        asset.data = File.open(files.first)
        return asset
      end

      def self.all(params = {})
        assets = []
        files = Dir.glob(Rails.root.join('files', 'help', Rails.env.to_s, params[:help_content_id], '*')).sort
        files.grep(regex[:attachment_file]).each do |i|
          asset = new
          asset.help_content_id = params[:help_content_id]
          asset.data = File.open(i)
          assets << asset
        end
        assets
      end

      def initialize(params = {})
        @messages = []
        self.help_content_id = params[:help_content_id]
      end

      def url_thumb
        @url_thumb ||= Ckeditor::Utils.filethumb(filename)
      end

      #
      #=== 添付ファイルかどうかを返す
      #
      def attachment_files?
        extname =~ regex[:attachment_file]
      end

      def url
        "/susanoo/admin/help_content_assets/#{help_content_id}?data_file_name=#{data_file_name}"
      end

      def url_content
        url
      end
    end
  end
end
