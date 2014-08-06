# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :board_base, class: Board do
    sequence(:title){|n|"test#{n}"}
    trait :with_section do
      section{create(:section)}
    end

    trait :with_comments do
      comments{create(:board_comment_base)}
    end

    factory :board, traits: [:with_section]
    factory :board_with_comments, traits: [:with_section, :with_comments]
  end
end
