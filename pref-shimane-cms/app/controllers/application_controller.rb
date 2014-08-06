class ApplicationController < ActionController::Base
  include Concerns::ApplicationController

  rescue_from Exceptions::PaymentGatewayError do |exception|
    render(:file => "#{Rails.root}/public/500", :layout => false, :status => 500)
  end
end
