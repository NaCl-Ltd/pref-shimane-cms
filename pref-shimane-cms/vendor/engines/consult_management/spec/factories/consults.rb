FactoryGirl.define do
  factory :consult, class: ConsultManagement::Consult do
    name 'test-consult'
    link 'test-link'
    work_content 'test-work-content'
    contact 'test-contact'
    consult_categories{ 3.times.map{create(:consult_category)} }
  end
end
