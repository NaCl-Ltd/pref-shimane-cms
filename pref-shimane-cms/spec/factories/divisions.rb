# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :division, class: Division do
    sequence(:name){|n|"test#{n}"}
    sequence(:number){|n|n}
    enable true
  end

  factory :admin_division, parent: :division do
    name "admin_division"
    enable true
    initialize_with { Division.find_or_create_by(name: name) }
  end
end
