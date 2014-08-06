# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :mailmagazine_base, class: Mailmagazine do
    sequence(:mail_address) {|n| "test#{n}@#{Settings.mailmagazine.domain}" }
    header "test headaer"
    footer "test fotter"

    trait :with_sent_mailmagazines do
      sent_mailmagazines do
        [
          create(:sent_mailmagazine, datetime: DateTime.now),
        ]
      end
    end

    trait :with_section do
      section{create(:section)}
    end

    factory :mailmagazine, traits: [:with_sent_mailmagazines, :with_section]
    factory :mailmagazine_without_sent_mailmagazines, traits: [:with_section]
  end
end
