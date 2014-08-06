#
#= ヘルプ管理用コントローラのアクションを定義するモジュール
#
module Concerns::Susanoo::Admin::HelpsController
  extend ActiveSupport::Concern
  included do
    before_action :admin_required
    before_action :set_help_content, only: %i(edit update destroy)

    layout "explore"

    #
    #=== ヘルプ管理一覧画面
    #
    # parent_idがある場合は、紐づくヘルプを返却する
    # ajaxアクセスの場合は、部分テンプレートを返却する
    #
    def index
      @help_categories = ::HelpCategory.big_categories
      @help_contents = ::HelpContent.includes(:helps).references(:helps).page(params[:page]).order(:id)
      if params[:help_category_id].present?
        help_category = @help_categories.detect{|h_c| h_c.id == params[:help_category_id].to_i}
        help_categories = help_category.all_children
        @help_contents.where!('helps.help_category_id IN (?)', help_categories.map(&:id))
      end

      if request.xhr?
        render partial: 'index_row', locals: {help_contents: @help_contents}
      else
        render :index
      end
    end

    #
    #=== ヘルプ作成画面
    #
    def new
      @help = ::Help.new
      @help.build_help_content
    end

    #
    #== ヘルプの作成
    #
    def create
      @help = ::Help.new(help_params)

      if @help.save
        redirect_to main_app.susanoo_admin_helps_path, notice: t('.success')
      else
        render :new
      end
    end

    #
    #=== ヘルプコンテンツ編集画面
    #
    def edit
    end

    #
    #=== ヘルプコンテンツ更新
    #
    def update
      if @help_content.update(help_content_params)
        redirect_to main_app.susanoo_admin_helps_path, notice: t('.success')
      else
        render :edit
      end
    end

    #
    #=== ヘルプコンテンツ削除画面
    #
    def destroy
      @help_content.destroy
      redirect_to main_app.susanoo_admin_helps_path, notice: t(".success")
    end

    #
    #=== ヘルプの並び替え処理
    #
    def update_sort
     ::Help.transaction do
        params[:helps].each_with_index do |id, idx|
          ::Help.update(id, number: idx)
        end
      end
      return render json: true
    rescue => e
      logger.error("Error while creating help: #{e.message}")
      return render json: false
    end

    #
    #=== 見出しの一覧画面
    #
    def configure
      @help_content = ::HelpContent.includes(:helps).find(params[:help_content_id])
    end

    #
    #=== 見出しの編集画面
    #
    # パラメータにIDが含まれていたら、findをする
    #
    def edit_caption
      @help = (params[:id].blank? ? ::Help.new(help_content_id: params[:help_content_id]) : ::Help.find(params[:id]))

      @big_categories = ::HelpCategory.big_categories.includes(:children)
      help_category = @help.help_category
      case help_category.try(:get_category_name)
      when ::HelpCategory::BIG_CATEGORY_NAME
        @big_category      = help_category
        @middle_categories = help_category.children
        @small_categories  = []
      when ::HelpCategory::MIDDLE_CATEGORY_NAME
        @middle_category = help_category
        @big_category = help_category.parent
        @middle_categories = @big_category.children
        @small_categories = @middle_category.children
      when ::HelpCategory::SMALL_CATEGORY_NAME
        @small_category = help_category
        @middle_category = @small_category.parent
        @big_category = @middle_category.parent
        @small_categories = @middle_category.children
        @middle_categories = @big_category.children
      else
        @middle_categories = []
        @small_categories = []
      end
      render partial: "edit_caption"
    end

    #
    #=== 見出しの保存
    #
    # IDがあれば更新とみなす
    #
    def save_caption
      @help = (params[:id].blank? ? ::Help.new : ::Help.find(params[:id]))
      @help.attributes = help_params_as_save_caption
      if params[:help_category_ids].present?
        @help.help_category_id =  params[:help_category_ids].delete_if{|id| id.blank?}.last
      end

      json = {}
      if json[:result] = @help.save
        json[:html] = render_to_string partial: "shared/helps/alert", locals: {type: :success, messages: [t('.success')]}
        if @help.help_content.present?
          json[:url] = main_app.configure_susanoo_admin_helps_path(help_content_id: @help.help_content.id)
        end
        flash[:notice] = t('.success')
      else
        json[:html] = render_to_string partial: "shared/helps/alert", locals: {type: :error, messages: @help.errors.full_messages}
      end

      render json: json
    end

    #
    #=== 見出しの削除
    #
    # 見出しに紐づいていたコンテンツの見出しが０になったら、
    # コンテンツも削除する
    #
    def destroy_caption
      help = ::Help.find(params[:id])
      help_content = help.help_content
      help.destroy
      if help_content.helps.blank?
        help_content.destroy
        redirect_to main_app.susanoo_admin_helps_path, notice: t('.success')
      else
        redirect_to main_app.configure_susanoo_admin_helps_path(help_content_id: help_content.id), notice: t('.success')
      end
    end

    #
    #=== 見出しの公開・非公開状態を変更する
    #
    def caption_change_public
      help = ::Help.find(params[:id])
      help.update(public: help.public.zero? ? ::Help::PUBLIC : ::Help::PRIVATE)
      redirect_to main_app.configure_susanoo_admin_helps_path(help_content_id: help.help_content_id)
    end

    #
    #=== ヘルプアクションの一覧画面
    #
    def action_configure
      @help_actions = ::HelpAction.all.includes(:action_master, :help_category)
    end

    def edit_action
      @help_action = (params[:id].blank? ? ::HelpAction.new : ::HelpAction.find(params[:id]))

      @big_categories = ::HelpCategory.big_categories.includes(:children)

      help_category = @help_action.help_category
      case help_category.try(:get_category_name)
      when ::HelpCategory::BIG_CATEGORY_NAME
        @big_category      = help_category
        @middle_categories = help_category.children
        @small_categories  = []
      when ::HelpCategory::MIDDLE_CATEGORY_NAME
        @middle_category = help_category
        @big_category = help_category.parent
        @middle_categories = @big_category.children
        @small_categories = @middle_category.children
      when ::HelpCategory::SMALL_CATEGORY_NAME
        @small_category = help_category
        @middle_category = @small_category.parent
        @big_category = @middle_category.parent
        @small_categories = @middle_category.children
        @middle_categories = @big_category.children
      else
        @middle_categories = []
        @small_categories = []
      end

      render partial: 'edit_action'
    end

    #
    #=== ヘルプアクションの保存を行う
    #
    # IDがあれば更新とみなす
    #
    def save_action
      @help_action = (params[:id].blank? ? ::HelpAction.new : ::HelpAction.find(params[:id]))
      @help_action.attributes = help_action_params

      if params[:help_category_ids].present?
        @help_action.help_category_id =  params[:help_category_ids].delete_if{|id| id.blank?}.last
      end

      if @help_action.save
        return render partial: "shared/helps/alert", locals: {type: :success, messages: [t('.success')]}
      else
        return render partial: "shared/helps/alert", locals: {type: :error, messages: @help_action.errors.full_messages}
      end
    end

    def destroy_action
      help_action = ::HelpAction.find(params[:id])
      help_action.destroy
      redirect_to main_app.action_configure_susanoo_admin_helps_path, notice: t('.success')
    end

    private

      #
      #= ヘルプ情報を設定する
      #
      def set_help_content
        @help_content = ::HelpContent.find(params[:id])
      end

      def help_params
        params.require(:help).permit(:name, :help_category_id, help_content_attributes: [:content, :temp_key])
      end

      def help_content_params
        params.require(:help_content).permit(:content)
      end

      def help_params_as_save_caption
        params.require(:help).permit(:name, :help_category_id, :help_content_id)
      end

      def help_action_params
        params.require(:help_action).permit(:name, :help_category_id, :action_master_id)
      end
  end
end

