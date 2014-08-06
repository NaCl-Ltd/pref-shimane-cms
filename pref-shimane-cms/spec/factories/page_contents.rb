# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :page_content_base, class: PageContent do
    page { create(:page) }
    sequence(:content) {|n| "<h1>コンテンツ#{n}</h1>" }

    last_modified { Time.now }

    # 編集中
    trait :editing do
      begin_date { Time.now }
      end_date   { Time.now + 1.days }
      admission  0
      latest     false
    end

    # 公開依頼中
    trait :request do
      begin_date { Time.now }
      end_date   { Time.now + 1.days }
      admission  1
      latest     false
    end

    # 公開依頼却下
    trait :reject do
      begin_date { Time.now }
      end_date   { Time.now + 1.days }
      admission  2
      latest     false
    end

    # 公開中
    trait :publish do
      begin_date { Time.now - 1.month }
      end_date   { Time.now + 1.month }
      admission  3
      latest     true
    end

    # 公開中(期間無し)
    trait :publish_without_term do
      begin_date { nil }
      end_date   { nil }
      admission  3
      latest     true
    end

    # 公開停止
    trait :cancel do
      begin_date { Time.now - 1.month }
      end_date   { Time.now + 1.month }
      admission  4
      latest     true
    end

    # 公開待ち(admission は公開中と同じ)
    trait :waiting do
      begin_date { Time.now + 1.days }
      end_date   { Time.now + 1.month }
      admission  3
      latest     true
    end

    # 公開待ち(admission は公開中と同じ)
    trait :finished do
      begin_date { Time.now - 1.month }
      end_date   { Time.now - 1.days }
      admission  3
      latest     true
    end

    trait :top_news do
      top_news PageContent.top_news_status[:yes]
    end


    trait :section_news do
      section_news PageContent.section_news_status[:yes]
    end

    factory :page_content         , traits: [:publish]
    factory :page_content_editing , traits: [:editing]
    factory :page_content_request , traits: [:request]
    factory :page_content_reject  , traits: [:reject]
    factory :page_content_publish , traits: [:publish]
    factory :page_content_cancel  , traits: [:cancel]
    factory :page_content_waiting , traits: [:waiting]
    factory :page_content_finished, traits: [:finished]
    factory :page_content_publish_top_news, traits: [:publish, :top_news]
    factory :page_content_publish_section_news, traits: [:publish, :section_news]
    factory :page_content_publish_without_term, traits: [:publish_without_term]
  end
end

