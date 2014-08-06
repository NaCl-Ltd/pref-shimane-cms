module Susanoo
  module Assets
    class AttachmentFile < Base

      def self.all(params = {})
        assets = []
        page = Page.find(params[:page_id])
        files = Dir.glob(Rails.root.join('files', Rails.env.to_s, page.id.to_s, '*')).sort
        files.grep(regex[:attachment_file]).each do |i|
          asset = new
          asset.page = page
          asset.data = File.open(i)
          assets << asset
        end
        assets
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

    end
  end
end
