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

    describe "reject_event_genre" do
      let(:event_genre) { create(:genre, event_folder_type: ::Genre.event_folder_types[:top], parent: top_genre) }
      let(:normal_genre) { create(:genre, event_folder_type: ::Genre.event_folder_types[:none], parent: top_genre) }

      before do
        controller.stub(:login_required).and_return(true)
        controller.stub(:set_divisions_and_sections).and_return(true)
      end

      shared_examples_for "イベントフォルダへのアクセス制限" do |met, act, params|
        it "#{met.upcase} #{act}にアクセスしたとき、reject_event_genreがrenderされること" do
          expect(response).to render_template("event_calendar/susanoo/genres/reject_event_genre")
        end
      end

      shared_examples_for "イベントフォルダ以外へのアクセス" do |met, act, params|
        it "#{met.upcase} #{act}にアクセスしたとき、okが返ること" do
          (response.body == "ok").should be_true
        end
      end

      it_behaves_like("イベントフォルダへのアクセス制限", :get, :new) {before{ get :new, parent_id: event_genre.id}}
      it_behaves_like("イベントフォルダへのアクセス制限", :get, :edit) {before{get :edit, id: event_genre.id}}

      it_behaves_like("イベントフォルダ以外へのアクセス", :get, :new) {before{ get :new, parent_id: normal_genre.id}}
      it_behaves_like("イベントフォルダ以外へのアクセス", :get, :edit) {before{get :edit, id: normal_genre.id}}
    end
  end
end
