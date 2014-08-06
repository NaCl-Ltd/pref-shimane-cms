# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :info, class: Info do
    sequence(:title) {|n| "title#{n}" }
    last_modified DateTime.now
    sequence(:content) {|n| "content#{n}" }
  end

end
