module ImportPage
  class ImportController < self::ApplicationController
    before_action :enable_engine_required
    before_action :login_required

    def show
      @upload_file =
        UploadFile.find_by_section_id(current_user.section_id) || UploadFile.new
    end

    def create
      @upload_file = UploadFile.new
      @upload_file.user_id = current_user.id
      @upload_file.section_id = current_user.section_id
      @upload_file.genre_id = params[:upload_file][:genre_id]
      @upload_file.file     = params[:upload_file][:file]
      @upload_file.filename = @upload_file.file.try(:original_filename)

      @upload_file.validates_importable_genre

      if @upload_file.errors.empty? && @upload_file.store
        redirect_to import_path
      else
        @upload_file.remove
        render action: :show
      end
    end

    def destroy
      upload_file = UploadFile.find_by_section_id(current_user.section_id) rescue nil
      upload_file.remove if upload_file
      redirect_to import_path
    end
  end
end
