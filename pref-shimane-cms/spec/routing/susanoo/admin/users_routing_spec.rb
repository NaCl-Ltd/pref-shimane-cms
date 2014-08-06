require "spec_helper"

describe Susanoo::Admin::UsersController do
  describe "routing" do

    it "routes to #index" do
      get("/susanoo/admin/users").should route_to("susanoo/admin/users#index")
    end

    it "routes to #new" do
      get("/susanoo/admin/users/new").should route_to("susanoo/admin/users#new")
    end

    it "routes to #show" do
      get("/susanoo/admin/users/1").should route_to("susanoo/admin/users#show", :id => "1")
    end

    it "routes to #edit" do
      get("/susanoo/admin/users/1/edit").should route_to("susanoo/admin/users#edit", :id => "1")
    end

    it "routes to #create" do
      post("/susanoo/admin/users").should route_to("susanoo/admin/users#create")
    end

    it "routes to #update" do
      put("/susanoo/admin/users/1").should route_to("susanoo/admin/users#update", :id => "1")
    end

    it "routes to #destroy" do
      delete("/susanoo/admin/users/1").should route_to("susanoo/admin/users#destroy", :id => "1")
    end

  end
end
