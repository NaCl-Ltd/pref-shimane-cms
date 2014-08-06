require 'spec_helper'

describe Genre do
  describe "スコープ" do
    describe "search_for_blog" do
      let(:top) { create(:genre, parent_id: nil, path: "/") }
      let(:section_1) { create(:section_base) }
      let(:section_2) { create(:section_base) }
      let(:blog_top_genre_1) { create(:genre, parent_id: top.id, path: "/genre1/", blog_folder_type: Genre.blog_folder_types[:top], section_id: section_1.id)}
      let(:blog_top_genre_2) { create(:genre, parent_id: top.id, path: "/genre2/", blog_folder_type: Genre.blog_folder_types[:top], section_id: section_2.id)}

      it "sectionと一致するブログトップフォルダを取得できること" do
        genres = Genre.blog_top_in_section(section_1)
        expect(genres).to eq([blog_top_genre_1])
      end
    end
  end

  describe "メソッド" do
    before do
      @section = create(:section_base)
      @top = create(:top_genre, section_id: @section.id)

      # /genre1/2013/11と/genre1/2013/12とgenre1/2014/1までのジャンルが作成される
      @blog_top = create(:genre, parent_id: @top.id, path: "/genre1/", :blog_folder_type => ::Genre.blog_folder_types[:top], section_id: @section.id)
      @blog_top.create_year_month_folder!(Date.new(2013, 11, 1))
      @blog_top.create_year_month_folder!(Date.new(2013, 12, 1))
      @blog_top.create_year_month_folder!(Date.new(2014, 1, 1))

      @blog_2013    = @blog_top.children.where(name: "2013").first
      @blog_2013_11 = @blog_2013.children.where(name: "11").first
      @blog_2013_12 = @blog_2013.children.where(name: "12").first
      @blog_2014    = @blog_top.children.where(name: "2014").first
      @blog_2014_1  = @blog_2014.children.where(name: "1").first
    end

    describe "#create_year_month_folder!" do
      subject do
        @top.create_year_month_folder!
        @top
      end

      it "該当ジャンル以下に、yyyyというフォルダ名でyearフォルダが作成されること" do
        expect(subject.children.where(name: Date.today.year.to_s, blog_folder_type: ::Genre.blog_folder_types[:year]).count).to eq(1)
      end

      it "yyyyというフォルダ名以下に、mmというフォルダ名でmonthフォルダが作成されること" do
        year_folder = subject.children.where(name: Date.today.year.to_s).first
        expect(year_folder.children.where(name: Date.today.month.to_s, blog_folder_type: ::Genre.blog_folder_types[:month]).count).to eq(1)
      end
    end

    describe "#blog_folder?" do
      shared_examples_for "ブログフォルダである" do |value|
        subject { create(:genre, blog_folder_type: value, parent_id: @top) }
        it "blog_folder_typeが#{value.inspect}のとき、ブログフォルダと判定されること" do
          expect(subject.blog_folder?).to be_true
        end
      end

      shared_examples_for "ブログフォルダでない" do |value|
        subject { create(:genre, blog_folder_type: value, parent_id: @top) }
        it "blog_folder_typeが#{value.inspect}のとき、ブログフォルダと判定されないこと" do
          expect(subject.blog_folder?).to be_false
        end
      end

      it_behaves_like("ブログフォルダである", ::Genre.blog_folder_types[:year])
      it_behaves_like("ブログフォルダである", ::Genre.blog_folder_types[:month])
      it_behaves_like("ブログフォルダでない", ::Genre.blog_folder_types[:none])
      it_behaves_like("ブログフォルダでない", nil)
    end

    describe "#blog_page_ids" do
      before do
        @page_2014_1_1  = create(:page_publish, genre: @blog_2014_1,  :name => "1", blog_date: Date.new(2014, 1, 1))
        @page_2014_1_2  = create(:page_publish, genre: @blog_2014_1,  :name => "2", blog_date: Date.new(2014, 1, 2))
        @page_2013_12_1 = create(:page_publish, genre: @blog_2013_12, :name => "1", blog_date: Date.new(2013, 12, 1))
        @page_2013_11_1 = create(:page_publish, genre: @blog_2013_11, :name => "1", blog_date: Date.new(2013, 11, 1))
      end

      it "ブログトップに対して、ブログページのidを返すこと" do
        expect(@blog_top.blog_page_ids).to match_array [@page_2014_1_1, @page_2014_1_2, @page_2013_12_1, @page_2013_11_1].map(&:id)
      end

      it "年に対して、ブログページのidを返すこと" do
        expect(@blog_2013.blog_page_ids).to match_array [@page_2013_12_1, @page_2013_11_1].map(&:id)
      end

      it "月に対して、ブログページのidを返すこと" do
        expect(@blog_2014_1.blog_page_ids).to match_array [@page_2014_1_1, @page_2014_1_2].map(&:id)
      end
    end
  end
end
