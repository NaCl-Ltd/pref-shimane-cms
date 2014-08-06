module ConsultManagement
  class ConsultCategory < ActiveRecord::Base
    include ConsultManagement::Concerns::AddJob

    has_many :consult_category_members, dependent: :destroy
    has_many :consults, through: :consult_category_members

    validates :name, presence: true
    validates :description, presence: true
  end
end
