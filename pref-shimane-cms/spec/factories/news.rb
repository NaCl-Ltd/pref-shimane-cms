# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :news, class: News do
    sequence(:title) {|n| "test#{n}" }
    published_at Time.now
  end
end
