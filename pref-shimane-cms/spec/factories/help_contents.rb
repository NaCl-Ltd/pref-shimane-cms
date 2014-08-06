# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :help_content, class: HelpContent do
    content 'help content'
  end
end
