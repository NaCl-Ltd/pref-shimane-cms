require "spec_helper"

describe Susanoo::Admin::DivisionsController do
  describe "routing" do

    it "routes to #index" do
      get("/susanoo/admin/divisions").should route_to("susanoo/admin/divisions#index")
    end

    it "routes to #new" do
      get("/susanoo/admin/divisions/new").should route_to("susanoo/admin/divisions#new")
    end

    it "routes to #edit" do
      get("/susanoo/admin/divisions/1/edit").should route_to("susanoo/admin/divisions#edit", :id => "1")
    end

    it "routes to #create" do
      post("/susanoo/admin/divisions").should route_to("susanoo/admin/divisions#create")
    end

    it "routes to #update" do
      put("/susanoo/admin/divisions/1").should route_to("susanoo/admin/divisions#update", :id => "1")
    end

    it "routes to #destroy" do
      delete("/susanoo/admin/divisions/1").should route_to("susanoo/admin/divisions#destroy", :id => "1")
    end

    it "routes to #update_sort" do
      post("/susanoo/admin/divisions/update_sort").should route_to("susanoo/admin/divisions#update_sort")
    end

  end
end
