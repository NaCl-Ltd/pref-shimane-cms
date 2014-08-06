require "spec_helper"

describe Susanoo::PagesController do
  describe "routing" do

    it "routes to #index" do
      get("/susanoo/pages").should route_to("susanoo/pages#index")
    end

    it "routes to #new" do
      get("/susanoo/pages/new").should route_to("susanoo/pages#new")
    end

    it "routes to #show" do
      get("/susanoo/pages/1").should route_to("susanoo/pages#show", :id => "1")
    end

    it "routes to #edit" do
      get("/susanoo/pages/1/edit").should route_to("susanoo/pages#edit", :id => "1")
    end

    it "routes to #create" do
      post("/susanoo/pages").should route_to("susanoo/pages#create")
    end

    it "routes to #update" do
      put("/susanoo/pages/1").should route_to("susanoo/pages#update", :id => "1")
    end

    it "routes to #destroy" do
      delete("/susanoo/pages/1").should route_to("susanoo/pages#destroy", :id => "1")
    end

   it "routes to #select" do
      get("/susanoo/pages/select").should route_to("susanoo/pages#select")
    end

  end
end
