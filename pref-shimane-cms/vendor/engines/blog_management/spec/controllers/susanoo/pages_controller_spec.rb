require 'spec_helper'

describe Susanoo::PagesController do
  describe "フィルタ" do
    controller do
      %w(show new edit create).each do |act|
        define_method(act) do
          render text: "ok"
        end
      end
    end

    let(:top_genre) { create(:top_genre) }

    describe "reject_blog_page" do
      let(:blog_genre) { create(:genre, blog_folder_type: ::Genre.blog_folder_types[:top], parent: top_genre) }
      let(:page_in_blog) { create(:page, genre: blog_genre) }
      let(:index_page_in_blog) { create(:page, genre: blog_genre, name: "index") }
      let(:normal_genre) { create(:genre, blog_folder_type: ::Genre.blog_folder_types[:none], parent: top_genre) }
      let(:page_in_normal) { create(:page, genre: normal_genre) }

      before do
        controller.stub(:login_required).and_return(true)
        controller.stub(:page_permission_required).and_return(true)
        controller.stub(:set_susanoo_page).and_return(true)
        controller.stub(:genre_required).and_return(true)
      end

      shared_examples_for "アクセス制限" do |met, act|
        it "#{met.upcase} #{act}にアクセスしたとき、reject_blog_pageがrenderされること" do
          expect(response).to render_template("blog_management/susanoo/pages/reject_blog_page")
        end
      end

      shared_examples_for "アクセス制限されない" do |met, act|
        it "#{met.upcase} #{act}にアクセスしたとき、okが返ること" do
          (response.body == "ok").should be_true
        end
      end

      # new
      it_behaves_like("アクセス制限", :get, :new) {before{ get :new, genre_id: blog_genre.id}}
      it_behaves_like("アクセス制限されない", :get, :new) {before{ get :new, genre_id: normal_genre.id}}

      # create
      it_behaves_like("アクセス制限", :get, :create) {before{post :create, page: {genre_id: blog_genre.id}}}
      it_behaves_like("アクセス制限されない", :get, :create) {before{post :create, page: {genre_id: normal_genre.id}}}

      # edit
      it_behaves_like("アクセス制限", :get, :edit) {before{get :edit, id: page_in_blog.id}}
      it_behaves_like("アクセス制限されない", :get, :edit) {before{get :edit, id: index_page_in_blog.id}}
      it_behaves_like("アクセス制限されない", :get, :edit) {before{get :edit, id: page_in_normal.id}}

      # show
      it_behaves_like("アクセス制限", :get, :show) {before{get :show, id: page_in_blog.id}}
      it_behaves_like("アクセス制限されない", :get, :show) {before{get :show, id: index_page_in_blog.id}}
      it_behaves_like("アクセス制限されない", :get, :show) {before{get :show, id: page_in_normal.id}}
    end
  end
end
