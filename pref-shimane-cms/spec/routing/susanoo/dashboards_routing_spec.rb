require "spec_helper"

describe Susanoo::DashboardsController do
  describe "routing" do

    it "routes to #index" do
      get("/susanoo/dashboards").should route_to("susanoo/dashboards#index")
    end

  end
end
