# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :help, class: Help do
    name 'help name'
    help_content_id 1
    help_category_id 1
  end
end
