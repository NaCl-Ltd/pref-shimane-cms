# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :page, class: Page do
    sequence(:name) {|n| "page#{n}" }
    sequence(:title){|n| "title#{n}"}
    genre { create(:genre).reload }  # nameとpathとの違いを是正するため

    #コンテンツの状態毎のページを定義する
    # 公開済みのページについては編集中コンテンツも追加する
    trait :editing do
      contents { [create(:page_content_editing)] }
    end

    trait :request do
      contents { [create(:page_content_request)] }
    end

    trait :reject do
      contents { [create(:page_content_reject)] }
    end

    trait :publish do
      contents {[create(:page_content_publish) , create(:page_content_editing)].reverse}
    end

    trait :cancel do
      contents {[create(:page_content_cancel)  , create(:page_content_editing)].reverse}
    end

    trait :waiting do
      contents {[create(:page_content_waiting) , create(:page_content_editing)].reverse}
    end

    trait :finished do
      contents {[create(:page_content_finished), create(:page_content_editing)].reverse}
    end

    trait :publish_with_waiting do
      contents {[create(:page_content_publish) , create(:page_content_waiting)].reverse}
    end

    trait :publish_without_private do
      contents {[create(:page_content_publish)]}
    end

    trait :waiting_without_private do
      contents {[create(:page_content_waiting)]}
    end

    trait :publish_top_news do
      contents {[create(:page_content_publish_top_news)]}
    end

    trait :publish_section_news do
      contents {[create(:page_content_publish_section_news)]}
    end

    trait :with_section_news do
      after(:create) do |page|
        SectionNews.create(page_id: page.id,
                           begin_date: page.publish_content.try(:begin_date),
                           path: page.path,
                           title: page.news_title,
                           genre_id: page.genre_id)
      end
    end

    trait :publish_without_term do
      contents {[create(:page_content_publish_without_term) , create(:page_content_editing)].reverse}
    end

    factory :page_editing , traits: [:editing]
    factory :page_request , traits: [:request]
    factory :page_reject  , traits: [:reject]
    factory :page_publish , traits: [:publish]
    factory :page_cancel  , traits: [:cancel]
    factory :page_waiting , traits: [:waiting]
    factory :page_finished, traits: [:finished]
    factory :page_publish_with_waiting, traits: [:publish_with_waiting]
    factory :page_publish_without_private, traits: [:publish_without_private]
    factory :page_waiting_without_private, traits: [:waiting_without_private]
    factory :page_publish_top_news, traits: [:publish_top_news]
    factory :page_publish_section_news, traits: [:publish_section_news]
    factory :page_publish_without_term, traits: [:publish_without_term]
  end
end
