#
#= 閲覧管理コントローラ
#
class Susanoo::VisitorsController < ApplicationController

  #
  # html にルビをふる
  #
  # see app/controllers/application_controller.rb
  after_action :rubi_filter, only: %i(view preview)

end
