#
#= 閲覧管理コントローラ
#
class Susanoo::VisitorsController < ApplicationController
  include Concerns::Susanoo::VisitorsController

  before_action :set_consult_attach_file, only: %i(attach_file)

  private

    #
    #=== 広告画像を返す
    #
    def set_consult_attach_file
      path = request.path
      dir = File.dirname(path)
      file = File.basename(path)

      if dir == '/consult.data'
        consults = ConsultManagement::Consult.includes(:consult_categories)
        consults.map!{|c|
          c.attributes.merge(consult_category_ids: c.consult_categories.pluck(:id))
        }
        @attach_response = {type: :json, content: consults}
      end
    end

end
