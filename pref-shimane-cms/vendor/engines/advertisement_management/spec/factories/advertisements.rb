# Read about factories at https://github.com/thoughtbot/factory_girl
include ActionDispatch::TestProcess

FactoryGirl.define do
  factory :advertisement1, class: Advertisement do
    sequence(:name){|n|"test#{n}"}
    sequence(:advertiser){|n|"advertiser#{n}"}

    image{fixture_file_upload(File.join(File.dirname(__FILE__), '../', "files/rails.png"), 'image/png')}
    sequence(:alt){|n|"alt#{n}"}
    sequence(:url){|n|"http://localhost:#{n}"}
    begin_date DateTime.now
    end_date DateTime.now + 1
    side_type Advertisement::INSIDE_TYPE
    show_in_header true
    sequence(:corp_ad_number){|n|n}
    sequence(:pref_ad_number){|n|n}
    state 1
    sequence(:description){|n|"description#{n}"}
    sequence(:description_link){|n|"http://localhost:#{n}"}

    trait :corp do
      side_type Advertisement::OUTSIDE_TYPE
    end

    trait :pref do
      side_type Advertisement::INSIDE_TYPE
    end

    trait :toppage do
      side_type Advertisement::TOPPAGE_TYPE
    end

    trait :published do
      state Advertisement::PUBLISHED
    end

    trait :unpublished do
      state Advertisement::NOT_PUBLISHED
    end

    factory :toppage_advertisement, traits: %i(toppage)
    factory :published_corp_advertisement, traits: %i(corp published)
    factory :published_pref_advertisement, traits: %i(pref published)
    factory :published_toppage_advertisement, traits: %i(toppage published)
    factory :unpublished_corp_advertisement, traits: %i(corp unpublished)
    factory :unpublished_pref_advertisement, traits: %i(pref unpublished)
    factory :unpublished_toppage_advertisement, traits: %i(toppage unpublished)
  end

  factory :corp_advertisement, class: Advertisement, parent: :advertisement1 do
    state Advertisement::PUBLISHED
    side_type Advertisement::OUTSIDE_TYPE
  end

  factory :pref_advertisement, class: Advertisement, parent: :advertisement1 do
    state Advertisement::PUBLISHED
    side_type Advertisement::INSIDE_TYPE
  end
end
