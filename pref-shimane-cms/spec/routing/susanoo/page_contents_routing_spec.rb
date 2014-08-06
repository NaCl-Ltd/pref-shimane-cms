require "spec_helper"

describe Susanoo::PageContentsController do
  describe "routing" do

    it "routes to #index" do
      get("/susanoo/page_contents").should route_to("susanoo/page_contents#index")
    end

    it "routes to #new" do
      get("/susanoo/page_contents/new").should route_to("susanoo/page_contents#new")
    end

    it "routes to #show" do
      get("/susanoo/page_contents/1").should route_to("susanoo/page_contents#show", :id => "1")
    end

    it "routes to #edit" do
      get("/susanoo/page_contents/1/edit").should route_to("susanoo/page_contents#edit", :id => "1")
    end

    it "routes to #create" do
      post("/susanoo/page_contents").should route_to("susanoo/page_contents#create")
    end

    it "routes to #update" do
      put("/susanoo/page_contents/1").should route_to("susanoo/page_contents#update", :id => "1")
    end

    it "routes to #destroy" do
      delete("/susanoo/page_contents/1").should route_to("susanoo/page_contents#destroy", :id => "1")
    end

  end
end
