require_dependency "blog_management/application_controller"

module BlogManagement
  class Susanoo::PagesController < BlogManagement::ApplicationController
    before_action :enable_engine_required
    before_action :set_page, only: %i(show edit update destroy revisions reflect histories private_page_unlock)
    before_action :page_permission_required, only: %i(edit update destroy)

    helper ::Susanoo::PagesHelper

    # GET /blog_management/susanoo/pages/1
    def show
      @publishing = @page.publish_content
      @published = @page.published_content
      @unpublished = @page.unpublished_content
      @request = @page.request_content
    end

    # GET /blog_management/susanoo/pages/new
    def new
      @page = ::Page.new(blog_date: Date.today)

      render 'new'
    end

    # GET /blog_management/susanoo/pages/1/edit
    def edit
    end

    # POST /blog_management/susanoo/pags/create
    def create
      @page = ::Page.new(page_params)

      begin
        page_content = nil

        @page.transaction do
          @page.save!
          page_content = @page.contents.build
          page_content.admission = PageContent.page_status[:editing]
          page_content.top_news = PageContent.top_news_status[:no]
          page_content.format_version = PageContent.current_format_version
          page_content.save!
        end

        redirect_to edit_susanoo_page_content_path(
          page_content,
          template_id: @page.template_id,
          mode: 'new_page')
      rescue => e
        render action: 'new'
      end
    end

    # PATCH/PUT /blog_management/susanoo/pages/1
    def update
      if @page.update(page_params(:update))
        redirect_to susanoo_page_path(@page), notice: t(".success")
      else
        render action: 'edit'
      end
    end

    # DELETE /blog_management/susanoo/pages/1
    def destroy
      unless @page.deletable?(current_user)
        return redirect_to main_app.susanoo_page_path(page),
          flash: { error: t(".not_deletable") }
      end

      if @page.destroy_with_job
        redirect_to susanoo_blogs_path, notice: t(".success", name: @page.title)
      else
        redirect_to susanoo_page_path(@page), notice: t(".failure", name: @page.title)
      end
    end

    #
    # GET /blog_management/susanoo/pages/select
    #=== フォルダの選択
    #
    # 選択したフォルダの内容を表示する
    #
    def select
      @genre = Genre.by_id_and_authority(params[:genre_id], current_user).first
      if @genre.present?
        @search_form = PageSearchForm.new
        @pages = @search_form.search(@genre).page(params[:page])

        respond_to do |format|
          format.js   { render action: 'select' }
        end
      else
        render_missing
      end
    end

    #
    # GET /blog_management/susanoo/pages/1/revisions
    #=== 編集履歴を表示する
    #
    def revisions
    end

    # GET /blog_management/susanoo/pages/1/histories
    #=== 公開履歴を表示する
    #
    def histories
      @published_contents = @page.contents.eq_public.order('id DESC')
      @request_content = @page.request_content
      @waiting_content = @page.waiting_content
      @unreflectable = @page.locked?(request.session_options[:id]) || @waiting_content || (@request_content && current_user.editor?)
    end

    #
    # GET /blog_management/susanoo/page/1/reflect
    #=== 過去の公開ページを編集履歴に反映する
    #
    def reflect
      @page_content = PageContent.find(params[:content_id])
      if @page.reflect_editing_content(@page_content, current_user)
        message = t(".success", name: @page.title)
      else
        message = t(".failure", name: @page.title)
      end
      redirect_to susanoo_page_path(@page), notice: message
    end

    #
    # DELETE /blog_management/susanoo/page/1/private_page_unlock
    #===  編集中ページのロック解除
    #
    def private_page_unlock
      @page.page_unlock!
      return redirect_to susanoo_page_path(@page)
    end

    private

    # Use callbacks to share common setup or constraints between actions.
    def set_page
      @page = ::Page.find(params[:id])
    end

    # Only allow a trusted parameter "white list" through.
    def page_params(role=nil)
      case role
      when :udpate
        params[:page].permit(:title)
      else
        params[:page].permit(:title, :blog_date, :blog_top_genre_id, :template_id)
      end
    end
  end
end
