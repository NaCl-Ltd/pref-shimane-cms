EventCalendar::Engine.routes.draw do

  root to: 'susanoo/pages#index'

  # Susanoo コア機能 do
  namespace :susanoo do
    # ジャンル管理機能
    resources :genres do
      collection do
        get :treeview
        get :select_event_top
      end
    end

    # ページ管理機能
    resources :pages do
      member do
        get :revisions
        get :histories
        get :reflect
        delete :private_page_unlock
      end

      collection do
        get :select
        get :select_event_top
      end
    end

    # ページコンテンツ管理機能
    resources :page_contents do
      collection do
        get :cancel
        get :content
        post :check
        post :preview
        post :convert
        post :direct_html
      end

      member do
        get :cancel_request
        get :edit_private_page_status
        patch :update_private_page_status
        get :edit_public_page_status
        patch :update_public_page_status
        get :destroy_public_term
      end
    end
  end
end
