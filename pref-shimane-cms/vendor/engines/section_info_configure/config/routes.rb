SectionInfoConfigure::Engine.routes.draw do
  root to: 'susanoo/authoriser/sections#edit_info'

  namespace :susanoo do
    namespace :authoriser do
      resources :sections, only: [:update] do
        collection do
          get :edit_info
        end
      end
    end
  end
end
