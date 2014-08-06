LostLinkCheck::Engine.routes.draw do
  root to: 'susanoo/lost_links#index'

  namespace :susanoo do
    resources :lost_links, only: [:index, :destroy]
  end
end
