module Concerns::Susanoo::Admin::HelpContentAssetsController
  extend ActiveSupport::Concern

  included do
    respond_to :html

    layout 'filebrowser', only: %i(images attachment_files)

    #
    #=== 画像を表示させる
    #
    def show
      @help_image = Susanoo::Assets::HelpAttachmentFile.find(params)
      send_file(@help_image.path, stream: false, disposition: 'inline')
    end

    #
    #=== 画像一覧を返す
    #
    def images
      @help_images = Susanoo::Assets::HelpImage.all(params)
      respond_with(@help_images)
    end

    #
    #=== 添付ファイル一覧を返す
    #
    def attachment_files
      @help_assets = Susanoo::Assets::HelpAttachmentFile.all(params)
      respond_with(@help_assets)
    end

    #
    #=== ファイルアップロード
    #
    def upload_image
      @help_image = Susanoo::Assets::HelpImage.new(params)
      respond_with_asset(@help_image)
    end

    #
    #=== ファイルアップロード
    #
    def upload_attachment_file
      @help_attachment_file = Susanoo::Assets::HelpAttachmentFile.new(params)
      respond_with_asset(@help_attachment_file)
    end

    #
    #=== ファイル削除
    #
    def destroy
      @help_attachment_file = Susanoo::Assets::HelpAttachmentFile.find(params)
      @help_attachment_file.data.destroy
      respond_to do |format|
        format.js { render nothing: true }
      end
    end

    protected

      def respond_with_asset(asset)
        file = params[:CKEditor].blank? ? params[:qqfile] : params[:upload]
        asset.data = Ckeditor::Http.normalize_param(file, request)

        if asset.save
          json = {id: asset.id, type: asset.content_type, help_content_id: asset.help_content_id}.to_json
          body = params[:CKEditor].blank? ? json : %Q"<script type='text/javascript'>
            window.parent.CKEDITOR.tools.callFunction(#{params[:CKEditorFuncNum]}, '#{Ckeditor::Utils.escape_single_quotes(asset.url_content)}');
          </script>"
        else
          body = %Q"<script type='text/javascript'>
            alert('#{asset.messages.join('<br>')}')
            window.parent.CKEDITOR.tools.callFunction(#{params[:CKEditorFuncNum]}, '');
          </script>"
        end
        render text: body
      end
  end
end
