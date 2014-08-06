require 'spec_helper'

# Specs in this file have access to a helper object that includes
# the Susanoo::Admin::SectionsHelper. For example:
#
# describe Susanoo::Admin::SectionsHelper do
#   describe "string concat" do
#     it "concats two strings with spaces" do
#       expect(helper.concat_strings("this","that")).to eq("this that")
#     end
#   end
# end
describe Susanoo::Admin::SectionsHelper do
  context "options_for_select_with_second_genres" do
    before do
      create(:top_genre_with_second_genre)
    end

    it "引数で渡したgenresをもとにoptionsタグが生成されること" do
      genres = Genre.where("parent_id IS NOT NULL").to_a
      Genre.stub_chain('top_genre.children').and_return(genres)
      blank_html = %Q(<option value="0">指定無し</option>)
      html = genres.map{|d|%Q(<option value="#{d.id}">#{d.title}</option>)}.unshift(blank_html).join("\n")
      expect(helper.options_for_select_with_second_genres).to eq(html)
    end

    it "引数selectedに渡した値がselectedになること" do
      genres = Genre.where("parent_id IS NOT NULL")
      Genre.stub_chain('top_genre.children').and_return(genres)
      selected = genres.last.id
      blank_html = %Q(<option value="0">指定無し</option>)
      html = genres.map do |d|
        sel = selected == d.id ? %Q(selected="selected" ) : ""
        %Q(<option #{sel}value="#{d.id}">#{d.title}</option>)
      end.unshift(blank_html).join("\n")
      expect(helper.options_for_select_with_second_genres(selected)).to eq(html)
    end
  end
end
