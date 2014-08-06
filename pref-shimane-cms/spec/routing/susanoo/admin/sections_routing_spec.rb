require "spec_helper"

describe Susanoo::Admin::SectionsController do
  describe "routing" do

    it "routes to #index" do
      get("/susanoo/admin/sections").should route_to("susanoo/admin/sections#index")
    end

    it "routes to #new" do
      get("/susanoo/admin/sections/new").should route_to("susanoo/admin/sections#new")
    end

    it "routes to #edit" do
      get("/susanoo/admin/sections/1/edit").should route_to("susanoo/admin/sections#edit", :id => "1")
    end

    it "routes to #create" do
      post("/susanoo/admin/sections").should route_to("susanoo/admin/sections#create")
    end

    it "routes to #update" do
      put("/susanoo/admin/sections/1").should route_to("susanoo/admin/sections#update", :id => "1")
    end

    it "routes to #destroy" do
      delete("/susanoo/admin/sections/1").should route_to("susanoo/admin/sections#destroy", :id => "1")
    end

    it "routes to #update_sort" do
      post("/susanoo/admin/sections/update_sort").should route_to("susanoo/admin/sections#update_sort")
    end

  end
end
