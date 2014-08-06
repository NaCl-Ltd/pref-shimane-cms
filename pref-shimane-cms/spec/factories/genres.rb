# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :top_genre, class: Genre do
    name ""
    title "トップ"
    path "/"
    description nil
    original_id nil
    no nil
    uri nil
    section { create(:admin_section) }
    tracking_code nil
    auth nil
  end

  factory :top_genre_with_second_genre, class: Genre do
    name ""
    title "トップ"
    path "/"
    description nil
    original_id nil
    no nil
    uri nil
    section { create(:admin_section) }
    tracking_code nil
    auth nil
    children {
      [create(:second_genre), create(:second_genre)]
    }
  end

  factory :second_genre, class: Genre do
    # parent{create(:top_genre)}
    sequence(:name){|n|"second_#{n}"}
    sequence(:title){|n|"second_#{n}"}
    sequence(:path){|n|"/second_#{n}/"}
    description nil
    original_id nil
    no nil
    uri nil
    section { create(:admin_section) }
    tracking_code nil
    auth nil
  end

  factory :genre, class: Genre do
    sequence(:name){|n|"genre#{n}"}     # path に使われているものと異なっている
    sequence(:title){|n|"genre_#{n}"}
    sequence(:path){|n|"/genre_#{n}/"}  # name に使われているものと異なっている
    description nil
    original_id nil
    no nil
    uri nil
    section { create(:admin_section) }
    tracking_code nil
    auth nil
    deletable false
  end

  factory :template_genre, class: Genre do
    parent{create(:top_genre)}
    name "template"
    title "テンプレート"
    path "/template/"
    description nil
    original_id nil
    no nil
    uri nil
    section { create(:admin_section) }
    tracking_code nil
    auth nil
    deletable false
  end

  factory :section_top_genre, class: Genre do
    sequence(:name){|n|"name_#{n}"}
    title "テストジャンル"
    section { create(:section) }

    after(:create) do |genre|
      section = genre.section
      section.update(top_genre_id: genre.id)
    end
  end

end
