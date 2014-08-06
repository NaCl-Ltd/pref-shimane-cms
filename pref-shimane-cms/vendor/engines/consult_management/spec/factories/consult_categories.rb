FactoryGirl.define do
  factory :consult_category, class: ConsultManagement::ConsultCategory do
    name 'test-name'
    description 'test-description'
  end
end
