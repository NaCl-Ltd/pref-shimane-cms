# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :sent_mailmagazine_base, class: SentMailmagazine do
    sequence(:title) {|n| "title#{n}" }
    sequence(:content) {|n| "content#{n}" }

    trait :with_mailmagazine do
      mailmagazine{create(:mailmagazine_base)}
    end

    trait :with_mailmagazine_contents do
      mailmagazine_contents{[create(:mailmagazine_content, mailmagazine_id: mailmagazine_id)]}
    end

    factory :sent_mailmagazine, traits: [:with_mailmagazine_contents]
    factory :sent_mailmagazine_with_mailmagazine, traits: [:with_mailmagazine]
    datetime Time.now
  end
end
