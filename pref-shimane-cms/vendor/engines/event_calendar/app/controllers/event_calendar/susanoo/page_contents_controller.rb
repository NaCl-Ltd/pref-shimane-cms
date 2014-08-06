require_dependency "event_calendar/application_controller"

module EventCalendar
  class Susanoo::PageContentsController < EventCalendar::ApplicationController
    helper ::Susanoo::PageContentsHelper
    helper ::Susanoo::VisitorsHelper

    before_action :footer_not_required, only: %i(new create edit update)
    before_action :login_required
    before_action :set_mobile_edit_mode,
      only: %i(new edit content check preview)
    before_action :set_page, only: %i(new create)
    before_action :set_page_content, only: %i(show edit update destroy cancel_request
      edit_private_page_status update_private_page_status edit_public_page_status
      update_public_page_status destroy_public_term)
    before_action :set_creation_params, only: %i(new create edit update)
    before_action :page_permission_required, only: %i(edit update)
    before_action :page_status_check, only: %i(new create edit update)

    # GET /event_calendar/susanoo/page_contents
    def index
      @page_contents = PageContent.all
    end

    # GET /event_calendar/susanoo/page_contents/1
    def show
    end

    # GET /event_calendar/susanoo/page_contents/new
    def new
      @page_content = @page.private_content_or_new
      @page.lock!(request.session_options[:id], current_user)
      render 'new', layout: 'editor'
    end

    #
    # GET /event_calendar/susanoo/page_contents/1/edit
    #
    def edit
      @page.lock!(request.session_options[:id], current_user)
      render 'edit', layout: 'editor'
    end

    # POST /event_calendar/susanoo/page_contents
    def create
      @page_content = ::PageContent.new(page_content_params(:create))
      # 一時保存の設定
      @page_content.edit_required = saved_temporarily? if can_save_temporarily?

      if @page_content.save_with_normalization(current_user)
        @page.unlock!
        flash[:notice] = t(".success")
        render 'create'
      else
        render 'create_error'
      end
    end

    # GET /event_calendar/susanoo/page_contents/cancel
    def cancel
      @page = ::Page.find(params[:page_id])
      if params[:mode] == "new_page" &&
        @page.destroy
        redirect_to susanoo_pages_path
      else
        @page.unlock!
        redirect_to(susanoo_page_path(@page))
      end
    end

    # PATCH/PUT /event_calendar/susanoo/page_contents/1
    def update
      # 一時保存の設定
      @page_content.edit_required = saved_temporarily? if can_save_temporarily?

      @page_content.attributes = page_content_params(:update)
      if @page_content.save_with_normalization(current_user)
        @page.unlock!
        flash[:notice] = t(".success")
        render 'create'
      else
        render 'create_error'
      end
    end

    # DELETE /event_calendar/susanoo/page_contents/1
    def destroy
      @page_content.destroy
      redirect_to susanoo_page_contents_url, notice: 'Page content was successfully destroyed.'
    end

    #
    #=== コンテンツの内容を表示する
    # ページコンテンツのフォーマット古い場合、新しいフォーマットに変換します
    # リクエストパラメータ copy がある場合
    # PC向けコンテンツを携帯向けコンテンツにコピーします
    #
    def content
      @page = ::Page.find(params[:page_id])
      if params[:id]
        @page_content = PageContent.where(id: params[:id]).first
      else
        @page_content = @page.private_content_or_new
        @page_content.page_id = @page.id
      end

      @page_view = @page_content.edit_style_page_view(
        template_id: params[:template_id],
        is_mobile: (params[:mobile].present?) ? params[:mobile] == 'true' : false,
        is_copy: (params[:copy].present?) ? params[:copy] == 'true' : false
      )
      @page_view.engine_name = EventCalendar.to_s.underscore
      render @page_view.rendering_view_name(@mobile_edit_mode), layout: false
    end

    #
    #===　アクセシビリティをチェックする
    #
    def check
      begin
        page = Page.find(params[:page_id])
        @result = params[:content]
        page_content = page.contents.build
        @page_view = page_content.page_view(
          html: params[:content],
          is_mobile: (params[:mobile].present?) ? params[:mobile] == 'true' : false
        )
        @checker = ::Susanoo::AccessibilityChecker.new(path: page.path)
        html = render_to_string(@page_view.rendering_view_name(@mobile_edit_mode), layout: false)
        doc = Nokogiri.HTML(html)
        @result = @checker.run(doc.to_html)
      rescue => e
        @fatal_message = t('.failure')
        logger.error(%Q!#{$!} : #{$@.join("\n")}!)
      end
      respond_to do |format|
        format.js { render 'check' }
      end
    end

    #
    # GET /event_calendar/susanoo/page_content/1/cancel_request
    #=== 公開停止依頼
    #
    def cancel_request
      begin
        to_address = @genre.section.users.select(&:authorizer?).map(&:mail)
        ::Susanoo::PageNotifyMailer.cancel_request(current_user, @page_content, to_address).deliver
        redirect_to susanoo_page_path(@page), flash: {error: t(".success")}
      rescue => e
        logger.error("#{e.message}\n#{e.backtrace.join("\n")}")
        redirect_to susanoo_page_path(@page), flash: {error: t(".failure")}
      end
    end

    #
    #=== 未公開ページのステータス変更処理
    #
    def edit_private_page_status
      @page_content.news_title = @page.title if @page_content.news_title.blank?
      @page_content.section_news = PageContent.section_news_status[:no] if @page_content.section_news.blank?
    end

    #
    #===  編集中ページの状態変更処理
    #
    def update_private_page_status
      if params[:cancel].blank?
        if @page_content.update_as_private(current_user,
            page_content_params(:update_private_page_status),
            params[:public_term])
          redirect_to susanoo_page_path(@page),
            notice: t(".success", name: @page_content.admission_local_label)
        else
          render action: 'edit_private_page_status'
        end
      else
        redirect_to susanoo_page_path(@page)
      end
    end

    #
    #=== 公開中ページの状態変更画面
    #
    def edit_public_page_status
    end

    #
    #=== 公開ページの状態変更
    #
    def update_public_page_status
      if params[:cancel].blank?
        if @page_content.update_as_public(current_user,
            page_content_params(:update_public_page_status))
          redirect_to susanoo_page_path(@page), notice: t(".success")
        else
          render action: 'edit_public_page_status'
        end
      else
        redirect_to susanoo_page_path(@page)
      end
    end

    #
    #=== 公開期間を解除
    #
    def destroy_public_term
      @page_content.destroy_public_term
      return redirect_to(susanoo_page_path(@page), notice: t(".success"))
    end

    #
    #=== 編集中のコンテンツをプレビューする
    #
    def preview
      begin
        page = Page.find(params[:page_id])
        page_content = page.contents.build
        @page_view = page_content.page_view(
          html: params[:content],
          is_mobile: (params[:mobile].present?) ? params[:mobile] == 'true' : false,
          plugin_convert: true)
        html = render_to_string(@page_view.rendering_view_name(@mobile_edit_mode), layout: false)
        doc = Nokogiri::HTML.parse(html)
        doc.xpath('//link[@rel="stylesheet"]').remove
        doc.xpath('//*[@style]').remove_attr('style')
        @preview_html = doc.to_xhtml
      rescue => e
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
        page = Page.find(params[:page_id])
        @page_content = page.contents.build
        if params[:mobile].blank?
          @page_content.content = params[:content]
          @page_content.validate_content(true)
          @result = @page_content.content
        else
          @page_content.mobile = params[:content]
          @page_content.validate_mobile_content(true)
          @result = @page_content.mobile
        end
      rescue => e
        @fatal_message = t('.failure')
        logger.error(%Q!#{$!} : #{$@.join("\n")}!)
      end
      respond_to do |format|
        format.js { render 'convert' }
      end
    end

    #
    #=== 編集画面で入力したHTMLを画面に反映する
    #
    def direct_html
      begin
        page_content =  PageContent.new
        @source = page_content.to_current_format_html(params[:source], true)
        @source = page_content.to_edit_style(@source)
      rescue => e
        @fatal_message = t('.failure')
        logger.error(%Q!#{$!} : #{$@.join("\n")}!)
      end
    end

    private
    def set_page
      @page = ::Page.find(params[:page_id] || params[:page_content][:page_id])
    end

    def set_page_content
      @page_content = PageContent.find(params[:id])
      @page = @page_content.page
      @genre = @page.genre
    end

    def page_content_params(method)
      case method
      when :create
          params[:page_content].permit(:page_id, :content, :mobile)
      when :update
        params[:page_content].permit(:content, :mobile)
      when :update_private_page_status, :update_public_page_status
        params[:page_content].permit(:user_name, :email, :comment, :tel, :admission, :begin_date, :end_date, :section_news, :news_title, :last_modified)
      end
    end

    def set_creation_params
      @template_id = params[:template_id]
      @mode = params[:mode]
    end

    #
    #=== ページの状態をチェック
    #
    def page_status_check(page = @page)
      if page.locked?(request.session_options[:id])
        return redirect_to susanoo_page_path(page),
        flash: {error: t("shared.page.locked") }
      elsif current_user.editor? && page.request_content
        return redirect_to susanoo_page_path(page),
        flash: {error: t("shared.page.requested") }
      elsif page.waiting_content
        return redirect_to susanoo_page_path(page),
        flash: {error: t("shared.page.waiting") }
      else
        true
      end
    end

    #
    #=== 携帯コンテンツの編集モードに設定する
    #
    def set_mobile_edit_mode
      @mobile_edit_mode = (params[:mobile].present?) ? params[:mobile] == 'true' : false
    end

    def saved_temporarily?
      params[:commit] == 'save_temporarily'
    end

    def can_save_temporarily?
      params.has_key?(:_save_temporarily)
    end
  end
end
