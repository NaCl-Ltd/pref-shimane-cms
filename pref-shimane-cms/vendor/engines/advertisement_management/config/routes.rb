AdvertisementManagement::Engine.routes.draw do

  root to: 'susanoo/advertisements#index'

  # Susanoo コア機能
  namespace :susanoo do
    # 広告管理機能
    resources :advertisements do
      collection do
        get :edit_state
        post :update_state
        get :sort
        post :update_sort
        post :finish_sort
      end

      member do
        get :show_file
      end
    end
  end
end
