# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :advertisement_list1, class: AdvertisementList do
    state 1
    sequence(:corp_ad_number){|n|n}
    sequence(:pref_ad_number){|n|n}
    advertisement {create(:advertisement1)}

    trait :corp do
      advertisement { create(:corp_advertisement) }
    end

    trait :pref do
      advertisement { create(:pref_advertisement) }
    end

    trait :toppage do
      advertisement { create(:published_toppage_advertisement) }
    end

    trait :published do
      state AdvertisementList::PUBLISHED
    end

    trait :unpublished do
      state AdvertisementList::NOT_PUBLISHED
    end

    factory :toppage_advertisement_list, traits: %i(toppage)
    factory :published_corp_advertisement_list, traits: %i(corp published)
    factory :published_pref_advertisement_list, traits: %i(pref published)
    factory :published_toppage_advertisement_list, traits: %i(toppage published)
    factory :unpublished_corp_advertisement_list, traits: %i(corp unpublished)
    factory :unpublished_pref_advertisement_list, traits: %i(pref unpublished)
    factory :unpublished_toppage_advertisement_list, traits: %i(toppage unpublished)
  end

  factory :corp_advertisement_list, class: AdvertisementList, parent: :advertisement_list1 do
    advertisement {create(:corp_advertisement)}
  end

  factory :pref_advertisement_list, class: AdvertisementList, parent: :advertisement_list1 do
    advertisement {create(:pref_advertisement)}
  end
end
