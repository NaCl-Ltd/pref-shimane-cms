#
#=== API
#
class Api::TasksController < ApplicationController

  skip_before_action :verify_authenticity_token

  #
  #=== michecker でアクセシビリティチェックを行う
  #
  def validate
    respond_to do |format|
      format.json { render :json => Validator.exec(request.raw_post.force_encoding("UTF-8")) }
    end
  end

end


