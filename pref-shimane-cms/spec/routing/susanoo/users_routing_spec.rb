require "spec_helper"

describe Susanoo::UsersController do
  describe "routing" do

    it "routes to #index" do
      get("/susanoo/users").should route_to("susanoo/users#index")
    end

    it "routes to #new" do
      get("/susanoo/users/new").should route_to("susanoo/users#new")
    end

    it "routes to #show" do
      get("/susanoo/users/1").should route_to("susanoo/users#show", :id => "1")
    end

    it "routes to #edit" do
      get("/susanoo/users/1/edit").should route_to("susanoo/users#edit", :id => "1")
    end

    it "routes to #create" do
      post("/susanoo/users").should route_to("susanoo/users#create")
    end

    it "routes to #update" do
      put("/susanoo/users/1").should route_to("susanoo/users#update", :id => "1")
    end

    it "routes to #destroy" do
      delete("/susanoo/users/1").should route_to("susanoo/users#destroy", :id => "1")
    end

  end
end
