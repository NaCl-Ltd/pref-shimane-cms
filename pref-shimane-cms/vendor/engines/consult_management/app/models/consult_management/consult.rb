module ConsultManagement
  class Consult < ActiveRecord::Base
    include ConsultManagement::Concerns::AddJob

    has_many :consult_category_members, dependent: :destroy
    has_many :consult_categories, through: :consult_category_members

    validates :name, presence: true
    validates :link, presence: true
    validates :work_content, presence: true
    validates :contact, presence: true
  end
end
