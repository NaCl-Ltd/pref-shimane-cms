PrefShimaneChecker::Application.routes.draw do
  namespace :api do
    post "validate" => "tasks#validate"
  end
end
