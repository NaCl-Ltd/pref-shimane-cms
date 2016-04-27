module Concerns::Susanoo::PageAssetsController
  extend ActiveSupport::Concern

  included do
    layout 'filebrowser', only: %i(images attachment_files)

    #
    #=== 画像一覧を返す
    #
    def images
      @page_assets = Susanoo::Assets::Image.all(params)
      respond_with(@page_assets)
    end

    #
    #=== 添付ファイル一覧を返す
    #
    def attachment_files
      @page_assets = Susanoo::Assets::AttachmentFile.all(params)
      respond_with(@page_assets)
    end

    #
    #=== ファイルアップロード
    #
    def upload_image
      @page_asset = Susanoo::Assets::Image.new(params)
      respond_with_asset(@page_asset)
    end

    #
    #=== ファイルアップロード
    #
    def upload_attachment_file
      @page_asset = Susanoo::Assets::AttachmentFile.new(params)
      respond_with_asset(@page_asset)
    end

    #
    #=== ファイル削除
    #
    def destroy
      @page_asset.destroy
      respond_to do |format|
        format.js { render nothing: true }
      end
    end

    protected

      def find_asset
        @page_asset = Susanoo::Assets::Base.find(params)
      end

      def authorize_resource
      end

      def respond_with_asset(asset)
        func_num = nil
        if params[:CKEditorFuncNum].present? && params[:CKEditorFuncNum] =~ /\A[0-9]+\z/
          func_num = params[:CKEditorFuncNum].to_i
        end

        file = params[:CKEditor].blank? ? params[:qqfile] : params[:upload]
        asset.data = Ckeditor::Http.normalize_param(file, request)

        if func_num
          if asset.save
            json = {id: asset.id, type: asset.content_type, page_id: asset.page.id}.to_json
              body = params[:CKEditor].blank? ? json : %Q"<script type='text/javascript'>
                window.parent.CKEDITOR.tools.callFunction(#{func_num}, '#{Ckeditor::Utils.escape_single_quotes(asset.url_content)}');
              </script>"
          else
            body = %Q"<script type='text/javascript'>
              alert('#{asset.messages.join('<br>')}');
              window.parent.CKEDITOR.tools.callFunction(#{func_num}, '');
            </script>"
          end
        else
          body = nil
        end

        render text: body
      end
  end
end
