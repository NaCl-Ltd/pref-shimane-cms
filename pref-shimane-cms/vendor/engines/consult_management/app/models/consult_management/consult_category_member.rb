module ConsultManagement
  class ConsultCategoryMember < ActiveRecord::Base
    belongs_to :consult
    belongs_to :consult_category
  end
end
