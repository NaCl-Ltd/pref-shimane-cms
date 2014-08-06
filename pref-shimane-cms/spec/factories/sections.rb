# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :section_base, class: Section do
    sequence(:code){|n|"code#{n}"}
    sequence(:name){|n|"test#{n}"}
    sequence(:place_code){|n|"code#{n}"}
    sequence(:number){|n|n}
    sequence(:ftp){|n|"/contents/test#{n}"}
    info "test_section1"
    feature Settings.section.features.susanoo

    trait :with_genres do
      after(:create) do |s|
        s.genre ||= create(:genre, section: s) unless s.top_genre_id
      end
      after(:build) do |s|
        s.genre ||= build(:genre, section: s) unless s.top_genre_id
      end
    end

    trait :with_division do
      division{create(:division)}
    end

    trait :without_genres do
    end

    factory :section, traits: [:with_division, :with_genres]
    factory :section_without_genres, traits: [:without_genres]
  end

  factory :admin_section, parent: :section_base do
    code            "admin_section"
    name            "admin_section"
    ftp             "/contents/admin_section"
    info            "admin_section"
    division        { create(:admin_division) }
    initialize_with { Section.find_or_create_by(code: code) }
  end
end
