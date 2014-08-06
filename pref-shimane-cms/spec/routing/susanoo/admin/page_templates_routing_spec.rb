require "spec_helper"

describe Susanoo::Admin::PageTemplatesController do
  describe "routing" do

    it "routes to #index" do
      get("/susanoo/admin/page_templates").should route_to("susanoo/admin/page_templates#index")
    end

    it "routes to #new" do
      get("/susanoo/admin/page_templates/new").should route_to("susanoo/admin/page_templates#new")
    end

    it "routes to #show" do
      get("/susanoo/admin/page_templates/1").should route_to("susanoo/admin/page_templates#show", :id => "1")
    end

    it "routes to #edit" do
      get("/susanoo/admin/page_templates/1/edit").should route_to("susanoo/admin/page_templates#edit", :id => "1")
    end

    it "routes to #create" do
      post("/susanoo/admin/page_templates").should route_to("susanoo/admin/page_templates#create")
    end

    it "routes to #update" do
      put("/susanoo/admin/page_templates/1").should route_to("susanoo/admin/page_templates#update", :id => "1")
    end

    it "routes to #destroy" do
      delete("/susanoo/admin/page_templates/1").should route_to("susanoo/admin/page_templates#destroy", :id => "1")
    end

  end
end
