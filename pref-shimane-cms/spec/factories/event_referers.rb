# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :event_referer_base, class: EventReferer do
    sequence(:path) {|n| "/path#{n}/" }

    trait :event_calendar do
      plugin 0
      sequence(:target_path) {|n| "/path#{n}/event_calendar/" }
    end

    trait :event_pickup do
      plugin 1
      sequence(:target_path) {|n| "/path#{n}/event_pickup/" }
    end

    factory :event_referer_event_calendar, traits: [:event_calendar]
    factory :event_referer_event_pickup, traits: [:event_pickup]
  end
end
