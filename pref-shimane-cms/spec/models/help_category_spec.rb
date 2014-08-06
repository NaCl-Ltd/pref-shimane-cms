require 'spec_helper'

describe HelpCategory do
  describe "validate" do
    it { should validate_presence_of :name }
  end

  describe "メソッド" do
    describe".siblings_for_treeview" do
      before do
        @parent = create(:help_category, name: 'name')
      end

      context "idが存在しない場合" do
        subject{ HelpCategory.siblings_for_treeview }

        it "HelpCategoryにbig_categoriesを呼び出していること" do
          HelpCategory.should_receive(:big_categories).and_return([])
          subject
        end

        it "結果が正しいこと" do
          expect(subject).to eq(
            [{title: "ヘルプカテゴリ一覧", id: nil, expanded: true,
              navigation: false,
              children: [@parent].map{|c| {id: c.id, title: c.name, expanded: false, parent_id: c.parent_id, navigation: c.navigation,expanded: false, lazy: false}} }
            ]
          )
        end
      end


      context "idが存在する場合" do
        before do
          @children = []
          @children << create(:help_category, parent_id: @parent.id, name: 'name')
        end

        subject{ HelpCategory.siblings_for_treeview(@parent.id) }

        it "HelpCategoryから引数のIDを親に持つカテゴリーを取得していること" do
          expect(subject).to eq(@children.map{|c| {id: c.id, title: c.name, parent_id: c.parent_id, expanded: false, navigation: c.navigation, lazy: false} })
        end
      end
    end

    describe".category_and_help_for_treeview" do
      context "idが存在しない場合" do
        before do
          @help_categories = []
          3.times{ @help_categories << create(:help_category) }
        end


        subject{ HelpCategory.category_and_help_for_treeview }

        it "HelpCategoryにbig_categoriesを呼び出していること" do
          HelpCategory.should_receive(:big_categories).and_return([])
          subject
        end

        it "結果が正しいこと" do
          expect(subject).to eq(@help_categories.map{|c| {id: c.id, title: c.name, datatype: 'folder', expanded: false, lazy: false}})
        end
      end

      context "idが存在する場合" do
        subject{ HelpCategory.category_and_help_for_treeview(id: @big.id) }

        before do
          @big = create(:help_category)
          @middle = create(:help_category, parent_id: @big.id)

          @helps = []
          3.times{ @helps << create(:help, help_category_id: @big.id, public: Help::PUBLIC) }
        end

        it "指定されたIDを親に持つカテゴリとヘルプを取得していること" do
          expect(subject).to eq(@helps.unshift(@middle).map{|c|
            data = {id: c.id, title: c.name, datatype: c.instance_of?(HelpCategory) ? HelpCategory::CATEGORY_CLASS : HelpCategory::HELP_CLASS}
            if c.instance_of?(HelpCategory)
              data[:expanded] = false
              data[:lazy] = false
            end
            data
          })
        end
      end

      context "expandedが存在する場合" do
        subject{ HelpCategory.category_and_help_for_treeview(expanded: @small.id) }

        before do
          @big = create(:help_category)
          @middle = create(:help_category, parent_id: @big.id)
          @small = create(:help_category, parent_id: @middle.id)
        end

        it "指定されたIDまでの階層のexpandedがtrueになっていること" do
          expect(subject).to eq(
            [{
              id: @big.id,
              title: @big.name,
              datatype: HelpCategory::CATEGORY_CLASS,
              expanded: true,
              children: [{
                id: @middle.id,
                title: @middle.name,
                datatype: HelpCategory::CATEGORY_CLASS,
                expanded: true,
                children: [{
                  id: @small.id,
                  title: @small.name,
                  datatype: HelpCategory::CATEGORY_CLASS,
                  expanded: true,
                  children: []
                }]
              }]
            }]
          )
        end
      end
    end

    describe ".category_and_help_search" do
      context "keywordが空の場合" do
        subject{ HelpCategory.category_and_help_search(nil) }

        it ".category_and_help_for_treeviewを呼び出していること" do
          HelpCategory.should_receive(:category_and_help_for_treeview)
          subject
        end
      end

      context "keywordが入ってる場合" do
        let(:keyword) { 'me' }

        subject{ HelpCategory.category_and_help_search(keyword) }

        before do
          @help = create(:help, name: 'name', public: Help::PUBLIC)
          @help_category = create(:help_category, name: 'name')
        end

        it "一致するカテゴリとヘルプを返却していること" do
          expect(subject).to eq(
            [@help_category, @help].map do |h_c|
              data = {
                id: h_c.id,
                title: h_c.name,
                datatype: h_c.instance_of?(HelpCategory) ? HelpCategory::CATEGORY_CLASS : HelpCategory::HELP_CLASS
              }
              if h_c.instance_of?(HelpCategory)
                data[:expanded] = false
                data[:lazy] = true
              end
              data
            end
          )
        end
      end
    end

    describe "#addable" do
      subject{ @help_category.addable }

      context "子カテゴリが2つ存在するとき" do
        before do
          @help_category = create(:help_category, name: 'test')
          @help_category.stub(:ancestors).and_return([1, 2])
        end

        it 'falseを返却すること' do
          expect(subject).to be_false
        end
      end

      context "子カテゴリが2つ未満の場合" do
        before do
          @help_category = create(:help_category, name: 'test')
        end

        it "trueを返却すること" do
          expect(subject).to be_true
        end
      end
    end

    describe "#change_parent!" do
      let(:parent_id) { 1 }

      before do
        @help_category = create(:help_category, name: 'name')
      end

      it "parent_idが変更されること" do
        @help_category.change_parent!(parent_id: parent_id)
        expect(@help_category.parent_id).to eq(parent_id)
      end
    end

    describe "#fullpath" do
      before do
        @top = create(:help_category, name: 'name')
        @child = create(:help_category, name: 'name', parent_id: @top.id)
        @grand_child = create(:help_category, name: 'name', parent_id: @child.id)
      end

      it "トップのフォルダを指定した場合、トップフォルダのみが取得できること" do
        expect(@top.fullpath).to eq [@top]
      end

      it "孫フォルダを指定した場合、親〜孫のフォルダが取得できること" do
        expect(@grand_child.fullpath).to eq [@top, @child, @grand_child]
      end
    end

    describe "#set_number" do
      before do
        @help_category = create(:help_category, name: 'name')
      end

      subject{@help_category.set_number!}

      it "numerの最大値プラス1をnumberにセットすること" do
        expect(subject).to eq(1)
      end

      context "numberの最大値が空の場合" do
        before do
          @help_category = build(:help_category, name: 'name')
          HelpCategory.delete_all
        end

        it "numberに0をセットすること" do
          expect(subject).to eq(0)
        end
      end
    end

    describe "#get_category_name" do
      before do
        @top = create(:help_category, name: 'name')
        @child = create(:help_category, name: 'name', parent_id: @top.id)
        @grand_child = create(:help_category, name: 'name', parent_id: @child.id)
      end

      it "BIG_CATEGORY_NAMEが返却されること" do
        expect(@top.get_category_name).to eq(HelpCategory::BIG_CATEGORY_NAME)
      end

      it "MIDDLE_CATEGORY_NAMEが返却されること" do
        expect(@child.get_category_name).to eq(HelpCategory::MIDDLE_CATEGORY_NAME)
      end

      it "SMALL_CATEGORY_NAMEが返却されること" do
        expect(@grand_child.get_category_name).to eq(HelpCategory::SMALL_CATEGORY_NAME)
      end
    end

    describe "#all_children" do
      before do
        @top = create(:help_category, name: 'name')
        @child = create(:help_category, name: 'name', parent_id: @top.id)
        @grand_child = create(:help_category, name: 'name', parent_id: @child.id)
      end

      context "大カテゴリの場合" do
        it "自分を含めた子供をすべて返却すること" do
          expect(@top.all_children).to eq([@top, @child, @grand_child])
        end
      end

      context "中カテゴリの場合" do
        it "自分を含めた子供をすべて返却すること" do
          expect(@child.all_children).to eq([@child, @grand_child])
        end
      end

      context "子カテゴリの場合" do
        it "自分を含めた子供をすべて返却すること" do
          expect(@grand_child.all_children).to eq([@grand_child])
        end
      end

    end
  end
end
