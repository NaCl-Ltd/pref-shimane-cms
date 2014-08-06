class Susanoo::Admin::PageTemplatesController < ApplicationController

  #
  # html にルビをふる
  #
  # see app/controllers/application_controller.rb
  after_action :rubi_filter, only: %i(preview)

end
