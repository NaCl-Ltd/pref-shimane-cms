# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :mailmagazine_content_base, class: MailmagazineContent do
    sequence(:title) {|n| "title#{n}" }
    sequence(:content) {|n| "content#{n}" }
    sequence(:no) {|n|n}

    trait :with_sent_mailmagazine do
      sent_mailmagazine{create(:sent_mailmagazine_base)}
    end

    trait :with_mailmagazine do
      mailmagazine{create(:mailmagazine_base)}
    end

    trait :with_section do
      section{create(:section)}
    end

    datetime nil

    factory :mailmagazine_content
    factory :mailmagazine_content_with_mailmagazine, traits: [:with_mailmagazine]
  end
end
