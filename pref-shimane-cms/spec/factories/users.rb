FactoryGirl.define do
  factory :user, class: User do
    sequence(:name) {|n| "test#{n}" }
    sequence(:login) {|n| "test#{n}" }
    sequence(:mail) {|n| "test#{n}@example.com" }
    section { create(:section) }
    authority 2
    password "password"
    password_confirmation "password"
  end

  factory :section_user, class: User do
    sequence(:name) {|n| "test_section#{n}" }
    sequence(:login) {|n| "test_section#{n}" }
    sequence(:mail) {|n| "test_section#{n}@example.com" }
    section { create(:section) }
    authority 1
    password "password"
    password_confirmation "password"
  end

  factory :normal_user, class: User do
    sequence(:name) {|n| "test_normal#{n}" }
    sequence(:login) {|n| "test_normal#{n}" }
    sequence(:mail) {|n| "test_normal#{n}@example.com" }
    section { create(:section) }
    authority 0
    password "password"
    password_confirmation "password"
  end

  factory :admin_user, class: User do
    name   "admin_user"
    login  "admin_user"
    mail   "admin_user@example.com"
    section { create(:admin_section) }
    authority 2
    password "password"
    password_confirmation "password"
    initialize_with { User.find_or_create_by(login: login) }
  end
end

