# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :board_comment_base, class: BoardComment do
    sequence(:body){|n|"test#{n}"}
    public nil
    sequence(:from){|n|"from#{n}"}

    trait :with_board do
      board{create(:board)}
    end

    factory :board_comment, traits: [:with_board]
  end
end
