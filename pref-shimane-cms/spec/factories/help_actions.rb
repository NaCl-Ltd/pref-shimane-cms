# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :help_action do
    name 'HelpAction'
    action_master_id 1
    help_category_id 1
  end
end
