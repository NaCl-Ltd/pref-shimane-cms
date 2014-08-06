# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :web_monitor do
    genre { create(:genre) }

    sequence(:name) {|n| "test#{n}" }
    sequence(:login) {|n| "test#{n}" }
    password "password"
    password_confirmation "password"
  end
end
