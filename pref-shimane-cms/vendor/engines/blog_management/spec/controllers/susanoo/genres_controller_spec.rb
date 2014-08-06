require 'spec_helper'

describe Susanoo::GenresController do
  describe "フィルタ" do
    controller do
      %w(new edit).each do |act|
        define_method(act) do
          render text: "ok"
        end
      end
    end

    let(:top_genre) { create(:top_genre) }

    describe "reject_blog_genre" do
      let(:blog_genre) { create(:genre, blog_folder_type: ::Genre.blog_folder_types[:top], parent: top_genre) }
      let(:normal_genre) { create(:genre, blog_folder_type: ::Genre.blog_folder_types[:none], parent: top_genre) }

      before do
        controller.stub(:login_required).and_return(true)
        controller.stub(:set_divisions_and_sections).and_return(true)
      end

      shared_examples_for "ブログフォルダへのアクセス制限" do |met, act, params|
        it "#{met.upcase} #{act}にアクセスしたとき、reject_blog_genreがrenderされること" do
          expect(response).to render_template("blog_management/susanoo/genres/reject_blog_genre")
        end
      end

      shared_examples_for "ブログフォルダ以外へのアクセス" do |met, act, params|
        it "#{met.upcase} #{act}にアクセスしたとき、okが返ること" do
          (response.body == "ok").should be_true
        end
      end

      it_behaves_like("ブログフォルダへのアクセス制限", :get, :new) {before{ get :new, parent_id: blog_genre.id}}
      it_behaves_like("ブログフォルダへのアクセス制限", :get, :edit) {before{get :edit, id: blog_genre.id}}

      it_behaves_like("ブログフォルダ以外へのアクセス", :get, :new) {before{ get :new, parent_id: normal_genre.id}}
      it_behaves_like("ブログフォルダ以外へのアクセス", :get, :edit) {before{get :edit, id: normal_genre.id}}
    end
  end
end
