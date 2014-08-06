ConsultManagement::Engine.routes.draw do
  root to: 'susanoo/admin/consults#index'

  namespace :susanoo do
    namespace :admin do
      resources :consult_categories, except: [:new, :show] do
        collection do
          get :cancel
        end
      end

      resources :consults, except: [:new, :show] do
        collection do
          post :search
          get :cancel
        end
      end
    end
  end
end
