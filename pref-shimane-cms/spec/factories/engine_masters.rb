# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :engine_master do
    sequence(:name){|n|"test#{n}"}
    enable false
  end
end
