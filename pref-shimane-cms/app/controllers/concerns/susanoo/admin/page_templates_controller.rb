module Concerns::Susanoo::Admin::PageTemplatesController
  extend ActiveSupport::Concern

  included do
    before_action :admin_required
    before_action :set_page_template, only: %i(show edit update destroy edit_content update_content cancel)
    before_action :build_page_template_and_content, only: %i(content check preview convert)

    # GET /susanoo/admin/page_templates
    def index
      @search_form = PageTemplateForm.new(params[:search] || {})
      @page_templates = @search_form.search.
        order('name').page(params[:page]).per(6)
    end

    # GET /susanoo/admin/page_templates/1
    def show
    end

    # GET /susanoo/admin/page_templates/new
    def new
      @page_template = ::PageTemplate.new
    end

    # GET /susanoo/admin/page_templates/1/edit
    def edit
    end

    # POST /susanoo/admin/page_templates
    def create
      @page_template = ::PageTemplate.new(page_template_params(:create))

      if @page_template.save
        redirect_to edit_content_susanoo_admin_page_template_path(@page_template),
          notice: t(".success", name: @page_template.name)
      else
        render action: 'new'
      end
    end

    # PATCH/PUT /susanoo/admin/page_templates/1
    def update
      if @page_template.update(page_template_params(:update))
        redirect_to edit_content_susanoo_admin_page_template_path(@page_template),
          notice: t(".success", name: @page_template.name)
      else
        render action: 'edit'
      end
    end

    # DELETE /susanoo/admin/page_templates/1
    def destroy
      @page_template.destroy
      redirect_to susanoo_admin_page_templates_path,
          notice: t(".success", name: @page_template.name)
    end

    def edit_content
      render 'edit_content', layout: 'editor'
    end

    def update_content
      if @page_template.update(page_template_params(:update_content))
        flash[:notice] = t(".success", name: @page_template.name)
        render 'create'
      else
        render 'create_error'
      end
    end

    #
    #=== コンテンツの内容を表示する
    #
    def content
      @page_view = @page_content.edit_style_page_view

      render @page_view.rendering_view_name(false), layout: false
    end

    #
    #===　アクセシビリティをチェックする
    #
    def check
      begin
        @result = params[:content]
        @page_view = @page_content.page_view(
          html: params[:content]
        )
        html = render_to_string(@page_view.rendering_view_name(false), layout: false)
        @checker = Susanoo::AccessibilityChecker.new
        @result = @checker.run(html)
      rescue => e
        @fatal_message = t('.failure')
        logger.error(%Q!#{$!} : #{$@.join("\n")}!)
      end
      respond_to do |format|
        format.js { render 'check' }
      end
    end

    #
    #=== ページ編集キャンセル
    #
    def cancel
      redirect_to main_app.susanoo_admin_page_templates_path,
        notice: t(".success", name: @page_template.name)
    end

    #
    #=== 編集中のコンテンツをプレビューする
    #
    def preview
      begin
        @page_view = @page_content.page_view(
          html: params[:content]
        )
        @preview_html = render_to_string(@page_view.rendering_view_name(false), layout: false)
      rescue
        @fatal_message = t('.failure')
        logger.error(%Q!#{$!} : #{$@.join("\n")}!)
      end
      respond_to do |format|
        format.js { render 'preview' }
      end
    end

    #
    #=== コンテンツの機種依存文字を変換する
    #
    def convert
      begin
        @page_content.content = params[:content]
        @page_content.validate_content(true)
        @result = @page_content.content
      rescue
        @fatal_message = t('.failure')
        logger.error(%Q!#{$!} : #{$@.join("\n")}!)
      end
      respond_to do |format|
        format.js { render 'convert' }
      end
    end

    def direct_html
      begin
        page_content =  PageContent.new
        @source = page_content.to_current_format_html(params[:source], true)
        @source = page_content.to_edit_style(@source)
      rescue
        @fatal_message = t('.failure')
        logger.error(%Q!#{$!} : #{$@.join("\n")}!)
      end
    end

    private
      # Use callbacks to share common setup or constraints between actions.
      def set_page_template
        @page_template = ::PageTemplate.find(params[:id])
      end

      # Only allow a trusted parameter "white list" through.
      def page_template_params(method)
        case method
        when :create, :update
          params[:page_template].permit(:name)
        when :update_content
          params[:page_template].permit(:content)
        end
      end

      def build_page_template_and_content
        @page_template = ::PageTemplate.find(params[:id])
        @page = Page.new(name: "template", title: @page_template.name, genre: Genre.top_genre)
        @page_content = PageContent.new(page: @page, content: @page_template.content)
      end

    #
    #== ツリービュー検索フォームモデル
    #
    class PageTemplateForm < ::Susanoo::SearchForm
      field :name, type: :string

      # キーワードでフォルダを検索する
      def search
        scoped = ::PageTemplate.all
        scoped = scoped.where(["name LIKE ?" ,"%#{name}%"]) if name
        scoped
      end
    end
  end
end
