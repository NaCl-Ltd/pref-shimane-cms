require 'spec_helper'

include Susanoo::Helpers::Admin::SectionsHelper
include ActionView::Helpers::FormOptionsHelper

describe "Susanoo::Helpers::Admin::SectionsHelper" do
  describe "options_for_select_with_second_genres" do
    before do
      top_genre = create(:top_genre)
      @genres = (1..3).to_a.map{|n|create(:second_genre, parent: top_genre)}
      Genre.stub_chain(:top_genre, :children).and_return(@genres)
    end

    it "引数で渡したsectionsをもとにoptionsタグが生成されること" do
      options = [%Q(<option value="0">#{I18n.t("shared.not_select")}</option>)]
      options += @genres.map{|d|%Q(<option value="#{d.id}">#{d.name}</option>)}
      html = options.join("\n")
      expect(options_for_select_with_second_genres).to eq(html)
    end

    it "引数selectedに渡した値がselectedになること" do
      selected = @genres.last.id
      options = [%Q(<option value="0">#{I18n.t("shared.not_select")}</option>)]
      options += @genres.map do |d|
        sel = selected == d.id ? %Q(selected="selected" ) : ""
        %Q(<option #{sel}value="#{d.id}">#{d.name}</option>)
      end
      html = options.join("\n")

      expect(options_for_select_with_second_genres(selected)).to eq(html)
    end
  end
end