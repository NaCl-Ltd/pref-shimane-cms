# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :page_template, class: PageTemplate do
    sequence(:name) {|n| "page_template#{n}" }
    content "<h1>見出し</h1>"
  end
end

