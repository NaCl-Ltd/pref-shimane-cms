#
#= ヘルプカテゴリ管理用コントローラのアクションを定義するモジュール
#
module Concerns::Susanoo::Admin::HelpCategoriesController
  extend ActiveSupport::Concern
  included do
    before_action :admin_required
    before_action :set_help_category, only: %i(destroy update change_navigation)

    layout "explore"

    #
    #=== ヘルプカテゴリメンテナンストップ画面
    #
    def index
    end

    #
    #=== ヘルプカテゴリツリーのデータアクセス
    #
    # Jsonで値を返却する
    #
    def treeview
      render json: ::HelpCategory.siblings_for_treeview(params[:id])
    end

    #
    #=== ヘルプカテゴリ作成画面
    #
    # カテゴリの名前の編集と、子カテゴリ作成の画面が一緒に出ている
    #
    def new
      @parent_help_category = ::HelpCategory.find(params[:parent_id]) if params[:parent_id].present?
      @child_help_category = ::HelpCategory.new(parent_id: params[:parent_id])
      render "new", layout: false
    end


    #
    #=== ヘルプカテゴリの作成
    #
    # アラートHTMLを返却する
    #
    def create
      @help_category = HelpCategory.new(help_category_params)
      if @help_category.save
        @messages = [t('.success')]
        @new_tree = HelpCategory.selected_treeview(@help_category)
      else
        @error_messages = @help_category.errors.full_messages
      end
      render 'persist'
    end

    #
    #=== ヘルプカテゴリの更新
    #
    # アラートHTMLを返却する
    #
    def update
      if @help_category.update(help_category_params)
        @messages = [t('.success')]
        @new_tree = HelpCategory.selected_treeview(@help_category)
      else
        @error_messages = @help_category.errors.full_messages
      end
      render 'persist'
    end

    #
    #=== ヘルプカテゴリの削除
    #
    # アラートHTMLを返却する
    #
    def destroy
      @help_category.destroy
      if @help_category.parent.present?
        @new_tree = HelpCategory.selected_treeview(@help_category)
      else
        @new_tree = HelpCategory.siblings_for_treeview
      end
      @messages = [t('.success')]
    end

    # == ヘルプカテゴリの並び替え更新処理
    def update_sort
      ::HelpCategory.transaction do
        if params[:help_categories].blank?
          @help_category = ::HelpCategory.find(params[:id])
          @help_category.change_parent!(parent_id: params[:parent_id])
        else
          params[:help_categories].each do |i, help_category|
            ::HelpCategory.update(help_category[:id], parent_id: params[:parent_id], number: i)
          end
        end
      end
      return render partial: "shared/help_categories/alert", locals: {type: :success, messages: [t('.success')]}
    rescue => e
      logger.error("Error while updating HelpCategory: #{e.message}")
      return render partial: "shared/help_categories/alert", locals: {type: :error, messages: [t('.failure')]}
    end

    def help_list
      @helps = ::Help.where(help_category_id: params[:help_category_id]).order(:number)
      render partial: "help_list_row"
    end

    def change_navigation
      @help_category.update(navigation: !@help_category.navigation)
      redirect_to main_app.susanoo_admin_help_categories_path
    end

    private

      #
      #= ヘルプ情報を設定する
      #
      def set_help_category
        @help_category = ::HelpCategory.find(params[:id])
      end

      def help_category_params
        params.require(:help_category).permit(:name, :parent_id)
      end
  end
end

