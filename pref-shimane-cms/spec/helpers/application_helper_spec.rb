require 'spec_helper'

# Specs in this file have access to a helper object that includes
# the ApplicationHelper. For example:
#
# describe ApplicationHelper do
#   describe "string concat" do
#     it "concats two strings with spaces" do
#       expect(helper.concat_strings("this","that")).to eq("this that")
#     end
#   end
# end
describe ApplicationHelper do
  describe "#error_messages" do
    it "エラーメッセージのHTMLが返ること" do
      messages = ["error_message1"]
      str = %Q(<div class="alert fade in alert-error"><button class="close" data-dismiss="alert">×</button><ul><li><span>error_message1</span></li></ul></div>)
      (helper.error_messages(messages) == str).should be_true
    end
  end

  describe "#error_messages_for" do
    it "インスタンス変数をもとにエラーメッセージのHTMLが返ること" do
      section = Section.new(ftp: "invalid")
      section.invalid?
      str = %Q(<div class="alert fade in alert-error"><button class="close" data-dismiss="alert">×</button><ul>)
      str << section.errors.full_messages.map{|m|%Q(<li><span>#{m}</span></li>)}.join("")
      str << %Q(</ul></div>)
      (helper.error_messages_for(section) == str).should be_true
    end
  end

  describe "#genre_fullpath" do
    context "フォルダがnilでない場合" do
      before do
        @top = create(:top_genre)
        @child = create(:genre, parent_id: @top.id)
      end

      it "子フォルダのフルパスを返すこと" do
        fullpath = %Q(#{@top.title} > #{@child.title})
        expect(helper.genre_fullpath(@child)).to eq fullpath
      end

      it "トップフォルダのフルパスを返すこと" do
        fullpath = %Q(#{@top.title})
        expect(helper.genre_fullpath(@top)).to eq fullpath
      end
    end

    context "フォルダがnilの場合" do
      it "nilを返すこと" do
        expect(helper.genre_fullpath(nil)).to be_nil
      end
    end
  end

  describe "options_for_select_with_sections" do
    let(:sections){Section.all}
    before do
      2.times{create(:section)}
    end

    it "引数で渡したsectionsをもとにoptionsタグが生成されること" do
      html = sections.map{|d|%Q(<option value="#{d.id}">#{d.name}</option>)}.join("\n")
      expect(helper.options_for_select_with_sections(sections)).to eq(html)
    end

    it "引数selectedに渡した値がselectedになること" do
      selected = sections.last.id
      html = sections.map do |d|
        sel = selected == d.id ? %Q(selected="selected" ) : ""
        %Q(<option #{sel}value="#{d.id}">#{d.name}</option>)
      end.join("\n")
      expect(helper.options_for_select_with_sections(sections, selected)).to eq(html)
    end
  end

  describe "options_for_select_with_divisions" do
    let(:divisions){Division.all}
    before do
      2.times{create(:division)}
    end

    it "引数で渡したdivisionsをもとにoptionsタグが生成されること" do
      html = divisions.map{|d|%Q(<option value="#{d.id}">#{d.name}</option>)}.join("\n")
      expect(helper.options_for_select_with_divisions(divisions)).to eq(html)
    end

    it "引数selectedに渡した値がselectedになること" do
      selected = divisions.last.id
      html = divisions.map do |d|
        sel = selected == d.id ? %Q(selected="selected" ) : ""
        %Q(<option #{sel}value="#{d.id}">#{d.name}</option>)
      end.join("\n")
      expect(helper.options_for_select_with_divisions(divisions, selected)).to eq(html)
    end
  end
end
