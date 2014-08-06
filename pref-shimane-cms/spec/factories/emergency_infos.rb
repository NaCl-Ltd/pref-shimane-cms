# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :emergency_info, class: EmergencyInfo do
    display_start_datetime DateTime.now
    display_end_datetime DateTime.now + 1
    sequence(:content) {|n| "content#{n}" }
  end
end
