ImportPage::Engine.routes.draw do
  root to: 'import#show'

  resource :import, controller: 'import'
end
