require 'spec_helper'

describe Genre do
  describe "バリデーション" do
    it { should validate_presence_of :title }
    it { should validate_uniqueness_of(:name).scoped_to(:parent_id)  }
    it { should_not allow_value("   ").for(:title) }

    describe ".validate_name"  do
      ["_ABC", "javascripts", "stylesheets", "images", "contents", "backnumbers"].each do |name|
        it { should_not allow_value(name).for(:name).
          with_message(I18n.t("activerecord.errors.models.genre.attributes.name.initial_invalid"))
        }
      end

      context "トップフォルダの場合" do
        subject { build(:genre, path: "/", parent_id: nil) }
        it { should allow_value("").for(:name) }
      end

      context "トップフォルダでない場合" do
        subject { build(:genre, path: "/path", parent_id: 1)}
        it { should_not allow_value("").for(:name).
          with_message(I18n.t("activerecord.errors.models.genre.attributes.name.invalid"))
        }
      end
    end


    describe 'parent_top_genre_valid' do
      it "Sectionのトップフォルダへフォルダが作成できないこと" do
        pending ' parent_top_genre_valid を一時的に無効化してるので、コメントアウトする'
        parent_genre = create(:genre)
        section = create(:section, top_genre_id: parent_genre.id)

        genre = build(:genre, parent_id: parent_genre.id, section_id: section.id)
        genre.valid?

        expect(genre.errors[:parent_id].any?).to be_true
      end
    end
  end

  describe "スコープ" do
    describe "by_id_and_authority" do
      before do
        @admin = create(:user)
        @user_1  = create(:normal_user, section_id: 10)

        @top = create(:top_genre, section_id: 1)
        @child_1 = create(:genre, parent_id: @top.id, section_id: 10, no: 1)
      end

      it "運用管理者は指定したIDのGenreが取得できること" do
        genres = Genre.by_id_and_authority(@top.id, @admin)
        expect(genres.first).to eq(@top)
      end

      it "運用管理者以外は所属の持つGenreが取得できること" do
        genres = Genre.by_id_and_authority(@child_1.id, @user_1)
        expect(genres.first).to eq(@child_1)
      end

      it "運用管理者以外は所属外のGenreが取得できないこと" do
        genres = Genre.by_id_and_authority(@top.id, @user_1)
        expect(genres.first).to be_nil
      end
    end
  end

  describe "メソッド" do
    describe ".top_genre" do
      before do
        create(:top_genre)
      end

      it "pathが'/'のレコードが１件取得されること" do
        Genre.top_genre.should be_kind_of(Genre)
        Genre.top_genre.path.eql?("/")
      end
    end

    describe ".siblings_for_treeview" do
      context "Genreがnilでない場合" do
        before do
          @admin = create(:user)
          @user_1  = create(:normal_user, section_id: 10)
          @user_2  = create(:normal_user, section_id: 20)

          Genre.delete_all

          @top = create(:top_genre, section_id: 1)
          @child_1 = create(:genre, parent_id: @top.id, section_id: 10, no: 1)
          @child_2 = create(:genre, parent_id: @top.id, section_id: 20, no: 2)
          @gchild_1 = create(:genre, parent_id: @child_1.id, section_id: 10, no: 1)
          @gchild_2 = create(:genre, parent_id: @child_2.id, section_id: 20, no: 2)
        end

        context "運用管理者の場合" do
          it "トップフォルダ取得できること" do
            siblings = Genre.siblings_for_treeview(@admin)
            siblings.each do |genre|
              expect(genre[:id]).to eq @top.id
            end
          end

          it "フォルダ直下の兄弟要素が取得できること" do
            siblings = Genre.siblings_for_treeview(@admin, @top.id)

            expect(siblings.size).to eq 2
            expect(siblings[0][:id]).to eq @child_1.id
            expect(siblings[1][:id]).to eq @child_2.id
          end
        end

        context "運用管理者以外の場合" do
          it "所属のルートフォルダが取得できること" do
            siblings = Genre.siblings_for_treeview(@user_1)
            expect(siblings.size).to eq 1
            expect(siblings[0][:id]).to eq @child_1.id
          end

          it "フォルダ直下の兄弟要素が取得できること" do
            siblings = Genre.siblings_for_treeview(@user_1, @child_1.id)
            expect(siblings.size).to eq 1
            expect(siblings[0][:id]).to eq @gchild_1.id
          end
        end
      end

      context "Genreがnilの場合" do
        before do
          @admin = create(:user)
        end

        it "空の配列が返ること" do
          tree = Genre.siblings_for_treeview(@admin)
          expect(tree).not_to be_nil
        end
      end
    end

    describe ".siblings_for_treeview_with_pages" do
      context "Genreがnilでない場合" do
        before do
          @admin = create(:user)
          @user_1  = create(:normal_user, section_id: 10)
          @user_2  = create(:normal_user, section_id: 20)

          Genre.delete_all

          @top = create(:top_genre, section_id: 1)
          @top_page = create(:page, genre: @top)
          @child_1 = create(:genre, parent_id: @top.id, section_id: 10, no: 1)
          @child_2 = create(:genre, parent_id: @top.id, section_id: 20, no: 2)
          @gchild_1 = create(:genre, parent_id: @child_1.id, section_id: 10, no: 1)
          @gchild_2 = create(:genre, parent_id: @child_2.id, section_id: 20, no: 2)
        end

        context "運用管理者の場合" do
          it "トップフォルダ取得できること" do
            siblings = Genre.siblings_for_treeview_with_pages(@admin)
            siblings.each do |genre|
              expect(genre[:id]).to eq @top.id
            end
          end

          it "フォルダ直下の兄弟要素が取得できること" do
            siblings = Genre.siblings_for_treeview_with_pages(@admin, @top.id)

            expect(siblings.size).to eq 3
            expect(siblings[0][:id]).to eq @child_1.id
            expect(siblings[1][:id]).to eq @child_2.id
            expect(siblings[2][:id]).to eq @top_page.id
          end
        end

        context "運用管理者以外の場合" do
          it "所属のルートフォルダが取得できること" do
            siblings = Genre.siblings_for_treeview_with_pages(@user_1)
            expect(siblings.size).to eq 1
            expect(siblings[0][:id]).to eq @child_1.id
          end

          it "フォルダ直下の兄弟要素が取得できること" do
            siblings = Genre.siblings_for_treeview_with_pages(@user_1, @child_1.id)
            expect(siblings.size).to eq 1
            expect(siblings[0][:id]).to eq @gchild_1.id
          end
        end
      end

      context "Genreがnilの場合" do
        before do
          @admin = create(:user)
        end

        it "空の配列が返ること" do
          tree = Genre.siblings_for_treeview_with_pages(@admin)
          expect(tree).not_to be_nil
        end
      end
    end

    describe "#fullpath" do
      before do
        @top = create(:top_genre)
        @child = create(:genre, parent_id: @top.id)
        @grand_child = create(:genre, parent_id: @child.id)
      end

      it "トップのフォルダを指定した場合、トップフォルダのみが取得できること" do
        expect(@top.fullpath).to eq [@top]
      end

      it "孫フォルダを指定した場合、親〜孫のフォルダが取得できること" do
        expect(@grand_child.fullpath).to eq [@top, @child, @grand_child]
      end
    end

    describe "#deletable?" do
      let!(:division) { create(:division) }
      let!(:section1) { create(:section, division: division) }
      let!(:section2) { create(:section, division: division) }
      let!(:root)  { create(:top_genre, section: section1) }
      let!(:genre1) { create(:genre, parent: root, section: section1, deletable: true) }
      let!(:g1_page1)  { create(:page_editing, genre: genre1) }
      let!(:g1_page2)  { create(:page_editing, genre: genre1) }
      let!(:child)  { create(:genre, parent: genre1, section: section1, deletable: true) }
      let!(:child_page1)  { create(:page_editing, genre: child) }
      let!(:child_page2)  { create(:page_editing, genre: child) }
      let!(:genre2) { create(:genre, parent: root, section: section2, deletable: true) }
      let!(:genre3) { create(:genre, parent: root, section: section1, deletable: true) }
      let!(:child_genre1) { create(:genre, parent: genre1, section: section1, deletable: true) }
      let!(:child_genre2) { create(:genre, parent: genre1, section: section2, deletable: true) }

      before do
        allow_any_instance_of(Page).to receive(:deletable?).and_return(true)
        allow(genre1).to receive(:descendants_pages).and_return([g1_page1, g1_page2, child_page1, child_page2])
      end

      context "運用管理者の場合" do
        let!(:user) { create(:user) }

        it "deletableカラムが false の場合falseが返ること" do
          genre1.update_attribute(:deletable, false)
          expect(genre1.deletable?(user)).to be_false
        end

        it "コピー先フォルダが存在する場合falseが返ること" do
          create(:genre, original: genre1, parent: genre3)
          expect(genre1.deletable?(user)).to be_false
        end

        it "配下に削除不可なページが一つでも存在する場合falseが返ること" do
          allow(
            genre1.descendants_pages.find {|r| r.id == g1_page1.id }
          ).to receive(:deletable?).and_return(false)
          expect(genre1.deletable?(user)).to be_false
        end

        it "配下のフォルダ内に削除不可なページが一つでも存在する場合falseが返ること" do
          allow(
            genre1.descendants_pages.find {|r| r.id == child_page1.id }
          ).to receive(:deletable?).and_return(false)
          expect(genre1.deletable?(user)).to be_false
        end

        it "異なる所属である場合trueが返ること" do
          expect(genre2.deletable?(user)).to be_true
        end

        it "同じ所属である場合trueが返ること" do
          expect(genre1.deletable?(user)).to be_true
        end

        it "親と同じ所属である場合trueが返ること" do
          expect(child_genre1.deletable?(user)).to be_true
        end

        it "親と異なる所属である場合trueが返ること" do
          expect(child_genre2.deletable?(user)).to be_true
        end
      end

      context "情報提供管理者の場合" do
        let!(:user) { create(:section_user, section: section1) }

        it "deletableカラムが false の場合falseが返ること" do
          genre1.update_attribute(:deletable, false)
          expect(genre1.deletable?(user)).to be_false
        end

        it "コピー先フォルダが存在する場合falseが返ること" do
          create(:genre, original: genre1, parent: genre3)
          expect(genre1.deletable?(user)).to be_false
        end

        it "配下に削除不可なページが一つでも存在する場合falseが返ること" do
          allow(
            genre1.descendants_pages.find {|r| r.id == g1_page1.id }
          ).to receive(:deletable?).and_return(false)
          expect(genre1.deletable?(user)).to be_false
        end

        it "配下のフォルダ内に削除不可なページが一つでも存在する場合falseが返ること" do
          allow(
            genre1.descendants_pages.find {|r| r.id == child_page1.id }
          ).to receive(:deletable?).and_return(false)
          expect(genre1.deletable?(user)).to be_false
        end

        it "異なる所属である場合falseが返ること" do
          expect(genre2.deletable?(user)).to be_false
        end

        it "同じ所属である場合trueが返ること" do
          expect(genre1.deletable?(user)).to be_true
        end

        it "親と同じ所属である場合trueが返ること" do
          expect(child_genre1.deletable?(user)).to be_true
        end

        it "親と異なる所属である場合falseが返ること" do
          expect(child_genre2.deletable?(user)).to be_false
        end
      end

      context "ホームページ担当者の場合" do
        let!(:user) { create(:normal_user, section: section1) }

        it "deletableカラムが false の場合falseが返ること" do
          genre1.update_attribute(:deletable, false)
          expect(genre1.deletable?(user)).to be_false
        end

        it "コピー先フォルダが存在する場合falseが返ること" do
          create(:genre, original: genre1, parent: genre3)
          expect(genre1.deletable?(user)).to be_false
        end

        it "配下に削除不可なページが一つでも存在する場合falseが返ること" do
          allow(
            genre1.descendants_pages.find {|r| r.id == g1_page1.id }
          ).to receive(:deletable?).and_return(false)
          expect(genre1.deletable?(user)).to be_false
        end

        it "配下のフォルダ内に削除不可なページが一つでも存在する場合falseが返ること" do
          allow(
            genre1.descendants_pages.find {|r| r.id == child_page1.id }
          ).to receive(:deletable?).and_return(false)
          expect(genre1.deletable?(user)).to be_false
        end

        it "異なる所属である場合falseが返ること" do
          expect(genre2.deletable?(user)).to be_false
        end

        it "同じ所属である場合falseが返ること" do
          expect(genre1.deletable?(user)).to be_false
        end

        it "親と同じ所属である場合falseが返ること" do
          expect(child_genre1.deletable?(user)).to be_false
        end

        it "親と異なる所属である場合falseが返ること" do
          expect(child_genre2.deletable?(user)).to be_false
        end
      end
    end

    describe "#editable?" do
      before do
        @division = create(:division)
        @sections = create_list(:section, 3, division: @division)

        @admin = create(:user, section: @sections[0])
        @authorizer_1 = create(:section_user, section: @sections[1])
        @authorizer_2 = create(:section_user, section: @sections[2])
        @editor_1 = create(:normal_user, section: @sections[1])

        @genre_1 = create(:genre, path: "/", section_id: @sections[0], deletable: false)
        @genre_2 = create(:genre, parent_id: @genre_1.id, path: "/genre2", section: @sections[1], deletable: true)
        @genre_3 = create(:genre, parent_id: @genre_1.id, path: "/genre3", section: @sections[2], deletable: true)
      end

      context "運用管理者の場合" do
        it "trueが返ること" do
          expect(@genre_1.editable?(@admin)).to be_true
        end

        it "異なる所属のフォルダの場合、trueが返ること" do
          expect(@genre_2.editable?(@admin)).to be_true
        end
      end

      context "情報提供管理者の場合" do
        it "所属が一致するフォルダの場合trueが返ること" do
          expect(@genre_2.editable?(@authorizer_1)).to be_true
        end

        it "所属が一致しないフォルダの場合falseが返ること" do
          expect(@genre_3.editable?(@authorizer_1)).to be_false
        end
      end

      context "ホームページ担当者の場合" do
        it "所属が一致するフォルダの場合trueが返ること" do
          expect(@genre_2.editable?(@editor_1)).to be_true
        end

        it "所属が一致しないフォルダの場合falseが返ること" do
          expect(@genre_3.editable?(@editor_1)).to be_false
        end
      end
    end

    describe "#has_permission?" do
      before do
        @genre  = create(:top_genre)
        @user = create(:user)
      end

      subject{@genre.has_permission?(@user)}

      context "ユーザが管理者の場合" do
        before do
          @user.stub( :admin? ).and_return(true)
        end

        it "trueを返す。" do
          expect(subject).to eq(true)
        end
      end

      context "ユーザ管理者以外の場合" do
        before do
          @user.stub( :admin? ).and_return(false)
        end

        context "選択したフォルダの所属がユーザの所属と等しい場合" do
          before do
            @user.stub(:section_id).and_return(1)
            @genre.stub(:section_id).and_return(1)
          end

          it "trueを返す。" do
            expect(subject).to eq(true)
          end
        end

        context "選択したフォルダの所属がユーザの所属と等しくない場合" do
          before do
            @user.stub(:section_id).and_return(1)
            @genre.stub(:section_id).and_return(2)
          end

          it "falseを返す。" do
            expect(subject).to eq(false)
          end
        end
      end
    end

    describe "has_children?" do
      before do
        @genre = create(:top_genre)
      end

      subject{ @genre.has_children? }

      it "genreに対してchildrenが存在する場合、trueを返す。" do
        @genre.stub_chain( :children, :exists? ).and_return(true)
        expect(subject).to be_true
      end

      it "genreに対してchildrenが存在しない場合、falseを返す。" do
        @genre.stub_chain( :children, :exists? ).and_return(false)
        expect(subject).to be_false
      end
    end

    describe "#movable?" do
      let!(:root) { create(:top_genre) }
      let!(:grandparent) { create(:genre, parent: root) }
      let!(:parent) { create(:genre, parent: grandparent) }
      let!(:me) { create(:genre, parent: parent) }
      let!(:child1)  { create(:genre, parent: me) }
      let!(:child2) { create(:genre, parent: me) }
      let!(:grandchild)  { create(:genre, parent: child2) }
      let!(:uncle) { create(:genre, parent: grandparent) }
      let!(:cousin1) { create(:genre, parent: uncle) }
      let!(:cousin2) { create(:genre, parent: uncle) }

      subject{ me.reload.movable? }

      it '自身のアクセス制御が有効の場合は false が返ること' do
        me.update_attribute(:auth, true)
        expect(subject).to be_false
      end

      it '子ジャンルのアクセス制御が有効の場合は false が返ること' do
        child1.update_attribute(:auth, true)
        expect(subject).to be_false
      end

      it '孫ジャンルのアクセス制御が有効の場合は false が返ること' do
        grandchild.update_attribute(:auth, true)
        expect(subject).to be_false
      end

      it '親ジャンルのアクセス制御が有効の場合は false が返ること' do
        parent.update_attribute(:auth, true)
        expect(subject).to be_false
      end

      it '祖父母ジャンルのアクセス制御が有効の場合は false が返ること' do
        grandparent.update_attribute(:auth, true)
        expect(subject).to be_false
      end

      it '叔父ジャンルのアクセス制御が有効の場合は true が返ること' do
        uncle.update_attribute(:auth, true)
        expect(subject).to be_true
      end

      it 'いとこジャンルのアクセス制御が有効の場合は true が返ること' do
        cousin1.update_attribute(:auth, true)
        expect(subject).to be_true
      end

      it '子ジャンルに公開待ちページが存在する場合は false が返ること' do
        create(:page_waiting, genre: child1)
        expect(subject).to be_false
      end

      it '子ジャンルに公開中ページ(公開期限有り)が存在する場合は false が返ること' do
        create(:page_publish, genre: child1)
        expect(subject).to be_false
      end

      it '子ジャンルに公開中ページ(公開期限有り)が存在しない場合は true が返ること' do
        create(:page_publish_without_term, genre: child1)
        expect(subject).to be_true
      end

      it '孫ジャンルに公開待ちページが存在する場合は false が返ること' do
        create(:page_waiting, genre: grandchild)
        expect(subject).to be_false
      end

      it '孫ジャンルに公開中ページ(公開期限有り)が存在する場合は false が返ること' do
        create(:page_publish, genre: grandchild)
        expect(subject).to be_false
      end

      it '孫ジャンルに公開中ページ(公開期限有り)が存在しない場合は true が返ること' do
        create(:page_publish_without_term, genre: grandchild)
        expect(subject).to be_true
      end

      context '引数に validate: true を指定する場合' do
        subject{ me.reload.movable?(validate: true) }

        context 'アクセス制限が有効である場合' do
          before do
            me.update_attribute(:auth, true)
          end

          it 'false を返すこと' do
            expect(subject).to be_false
          end

          it '#errors にエラーメッセージが格納されること' do
            subject
            expect(me.errors.full_messages).to include(
              I18n.t('activerecord.errors.models.genre.attributes.base.move/auth')
            )
          end
        end

        context '公開待ちページが存在する場合' do
          before do
            create(:page_waiting, genre: me)
          end

          it 'false を返すこと' do
            expect(subject).to be_false
          end

          it '#errors にエラーメッセージが格納されること' do
            subject
            expect(me.errors.full_messages).to include(
              I18n.t('activerecord.errors.models.genre.attributes.base.move/waiting_page')
            )
          end
        end

        context 'エラー条件に当てはまらない場合' do
          it 'true を返すこと' do
            expect(subject).to be_true
          end

          it '#errors は空であること' do
            subject
            expect(me.errors.full_messages).to be_empty
          end
        end
      end

      context '引数に validate: true を指定しない場合' do
        subject{ me.reload.movable? }

        context 'アクセス制限が有効である場合' do
          before do
            me.update_attribute(:auth, true)
          end

          it 'false を返すこと' do
            expect(subject).to be_false
          end

          it '#errors は空であるること' do
            subject
            expect(me.errors.full_messages).to be_empty
          end
        end

        context '公開待ちページが存在する場合' do
          before do
            create(:page_waiting, genre: me)
          end

          it 'false を返すこと' do
            expect(subject).to be_false
          end

          it '#errors は空であるること' do
            subject
            expect(me.errors.full_messages).to be_empty
          end
        end

        context 'エラー条件に当てはまらない場合' do
          it 'true を返すこと' do
            expect(subject).to be_true
          end

          it '#errors は空であること' do
            subject
            expect(me.errors.full_messages).to be_empty
          end
        end
      end
    end

    describe "#move_to!" do
      let!(:from_genre) { create(:genre).reload }
      let!(:to_genre)   { create(:genre).reload }
      let(:from_genre_path) { Pathname(from_genre.path) }
      let(:to_genre_path)   { Pathname(to_genre.path) }
      let(:dest_path) { to_genre_path.join(from_genre.name) }

      subject { from_genre }

      it "move_folder ジョブが追加されていること" do
        expect do
          subject.move_to!(to_genre)
        end.to change{ Job.where(action: 'move_folder').count }.from(0).to(1)
      end

      it "ページリンクが移動先のパスに更新されること" do
        page = create(:page)
        page_content = create(:page_content_publish, page: page)

        expected_page_links = []
        FactoryGirl.with_options(page_content_id: page_content.id) do |f|
          [ [from_genre_path.dirname.join('index.html'), from_genre_path.dirname.join('index.html')],
            [from_genre_path.dirname.join('page.html'),  from_genre_path.dirname.join('page.html')],
            [from_genre_path.join('index.html'),         dest_path.join('index.html')],
            [from_genre_path.join('page.html'),          dest_path.join('page.html')],
            [from_genre_path.join('child01/index.html'), dest_path.join('child01/index.html')],
            [from_genre_path.join('child01/page.html'),  dest_path.join('child01/page.html')],
          ].each do |(before_path, after_path)|
            expected_page_links << f.create(:page_link, link: before_path.to_s).reload.clone
            expected_page_links[-1].link = after_path.to_s
          end
        end

        expect do
          subject.move_to!(to_genre)
        end.to change{ PageLink.count }.by(0)

        expect( PageLink.all.to_a ).to match_array(expected_page_links)
      end

      it "ページリンクに紐づいているページの<a>タグ、<img>タグのリンクが移動先のパスに更新されること" do
        content =
          %{<a href="#{from_genre_path.join('page.html')}">更新される</a>} +
          %{<a href="#{from_genre_path.join('child01/page.html')}">子フォルダ内のページも更新される</a>} +
          %{<a href="#{from_genre_path.dirname.join('page.html')}">親フォルダ内のページは更新されない</a>} +
          %{<img src="#{from_genre_path.join('page.html')}" alt="更新される" />} +
          %{<img src="#{from_genre_path.join('child01/page.html')}" alt="子フォルダ内のページも更新される" />} +
          %{<img src="#{from_genre_path.dirname.join('page.html')}" alt="親フォルダ内のページは更新されない" />}

        page = create(:page)
        page_content = create(:page_content, page: page, content: content)
        create(:page_link, page_content_id: page_content.id, link: from_genre_path.join('page.html').to_s)

        result = nil

        expect do
          result = subject.move_to!(to_genre)
        end.to change{ PageContent.count }.by(0)

        expect(page_content.reload.content).to eq(
          %{<a href="#{dest_path.join('page.html')}">更新される</a>} +
          %{<a href="#{dest_path.join('child01/page.html')}">子フォルダ内のページも更新される</a>} +
          %{<a href="#{from_genre_path.dirname.join('page.html')}">親フォルダ内のページは更新されない</a>} +
          %{<img src="#{dest_path.join('page.html')}" alt="更新される" />} +
          %{<img src="#{dest_path.join('child01/page.html')}" alt="子フォルダ内のページも更新される" />} +
          %{<img src="#{from_genre_path.dirname.join('page.html')}" alt="親フォルダ内のページは更新されない" />}
        )
      end

      it "ページリンクに紐づいていないページの<a>タグ、<img>タグのリンクが移動先のパスに更新されないこと" do
        content =
          %{<a href="#{from_genre_path.join('page.html')}">更新される</a>} +
          %{<a href="#{from_genre_path.join('child01/page.html')}">子フォルダ内のページも更新される</a>} +
          %{<a href="#{from_genre_path.dirname.join('page.html')}">親フォルダ内のページは更新されない</a>} +
          %{<img src="#{from_genre_path.join('page.html')}" alt="更新される" />} +
          %{<img src="#{from_genre_path.join('child01/page.html')}" alt="子フォルダ内のページも更新される" />} +
          %{<img src="#{from_genre_path.dirname.join('page.html')}" alt="親フォルダ内のページは更新されない" />}

        page = create(:page)
        page_content = create(:page_content, page: page, content: content)
        PageLink.delete_all

        expect do
          subject.move_to!(to_genre)
        end.to change{ PageContent.count }.by(0)

        expect(page_content.reload.content).to eq(content)
      end

      it "移動元フォルダ内のページと移動元フォルダ内のページに対してリンクしているページの create_page ジョブが追加されること" do
        child_genre   = create(:genre, parent: from_genre).reload        # 子フォルダ
        sibling_genre = create(:genre, parent: from_genre.parent).reload # 兄弟フォルダ
        other_genre = create(:genre).reload                              # その他フォルダ

        update_pages = []
        non_update_pages = []
        update_pages << create(:page_publish, genre: from_genre)
        update_pages << create(:page_publish, genre: child_genre)
        non_update_pages << create(:page_publish, genre: sibling_genre)

        linked_page = create(:page_publish, genre: other_genre)
        create(:page_link, page_content_id: linked_page.content_ids.last, link: from_genre.path)
        update_pages << linked_page

        tz_now = Time.zone.at(Time.zone.now.to_i)
        allow(Time).to receive(:now).and_return(tz_now)

        subject.move_to!(to_genre)

        expected = Job.where.not(action: 'move_folder').to_a.map{|r| r.attributes.except('id') }
        expect( expected ).to match_array(
          update_pages.map do |page|
            {datetime: tz_now, action: 'create_page', arg1: page.id.to_s, arg2: nil, queue: Job.queues[:move_export]}.stringify_keys
          end
        )
      end
    end

    describe "#section_top?" do
      context "section.top_gerne_idとgenre.idが同じ場合" do
        it "trueを返すこと" do
          section = create(:section)
          genre = create(:genre, section_id: section.id)
          section.update_attributes(top_genre_id: genre.id)

          expect(genre.section_top?).to be_true
        end
      end

      context "section.top_gerne_idとgenre.id異なる場合" do
        it "falseを返す場合" do
          section = create(:section)
          genre1 = create(:genre, section_id: section.id)
          genre2 = create(:genre, section_id: section.id)
          section.update_attributes(top_genre_id: genre2.id)

          expect(genre1.section_top?).to be_false
        end
      end
    end

    describe "#add_create_genre_jobs" do
      before do
        big_genre = create(:genre)
        middle_genre = create(:genre, parent_id: big_genre.id)
        @small_genre = create(:genre, parent_id: middle_genre.id)
      end

      it "Jobの数が増えていること" do
        old_count = Job.count
        expect{@small_genre.add_create_genre_jobs}.to change{Job.count}.from(old_count).to(old_count + 2)
      end
    end

    describe "#add_auth_job" do
      let(:genre) { create(:genre, path: '/shoshika/') }

      before do
        @web_monitors = 3.times.map{ create(:web_monitor, genre_id: genre.id, state: WebMonitor.status[:edited]) }
        genre.add_auth_job
      end

      it "stateがREGISTEREDになっていること" do
        @web_monitors.each do |w|
          expect(w.reload.state).to eq(WebMonitor.status[:registered])
        end
      end
    end

    describe "#descendants" do
      before do
        @genres = []
        @genres << @big_genre = create(:genre)

        @genres << middle_genre = create(:genre, parent_id: @big_genre.id)

        @genres << create(:genre, parent_id: middle_genre.id)
      end

      it "フォルダ以下の全てのページを取得していること" do
        expect(@big_genre.descendants).to eq(@genres)
      end
    end

    describe "#descendants_pages" do
      before do
        @big_genre = create(:genre)
        middle_genre = create(:genre, parent_id: @big_genre.id)
        small_genre = create(:genre, parent_id: middle_genre.id)

        @pages = []
        @pages << create(:page, genre_id: @big_genre.id)
        @pages << create(:page, genre_id: middle_genre.id)
        @pages << create(:page, genre_id: small_genre.id)
      end

      it "フォルダ以下の全てのページを取得していること" do
        expect(@big_genre.descendants_pages).to eq(@pages)
      end
    end

    describe "#section_expect_super" do
      context "sectionのtop_gerne_idがある場合" do
        let(:genre) { create(:genre, section_id: section.id) }
        let(:section) { create(:section, top_genre_id: 1) }

        it "sectionを返却すること" do
          expect(genre.section_except_super).to eq(section)
        end
      end

      context "section_idがスーパーセクション以外の場合" do
        let(:genre) { create(:genre, section_id: section.id) }
        let(:section) { create(:section, code: Settings.section.admin_code + "1", top_genre_id: nil) }

        it "sectionを返却すること" do
          expect(genre.section_except_super).to eq(section)
        end
      end

      context "sectionが無い場合" do
        let(:genre) { create(:genre, section: nil) }

        it "sectionを返却すること" do
          expect(genre.section_except_super).to eq(nil)
        end
      end
    end

    describe "#each_from_parent" do
      let(:name) { "each_genre_name" }
      before do
        @genres = []
        @genres << big_genre = create(:genre)
        @genres << middle_genre = create(:genre, parent_id: big_genre.id)
        @small_genre = create(:genre, parent_id: middle_genre.id)
        @small_genre.each_from_parent do |g|
          g.name = name
          g.save
        end
      end

      it "自分から親要素まで更新がかかっていること" do
        @genres.each do |g|
          expect(g.reload.name).to eq(name)
        end
      end
    end

    describe "#link_uri" do
      let(:uri) { 'uri' }

      context "uriが空の場合" do
        let(:genre) { create(:genre, uri: nil) }

        it "pathを返却すること" do
          expect(genre.link_uri).to eq(genre.path)
        end
      end

      context "uriが空で無い場合" do
        let(:genre) { create(:genre, uri: uri) }

        it "pathを返却すること" do
          expect(genre.link_uri).to eq(genre.uri)
        end
      end
    end

    describe "#section_name_except_super" do
      let(:genre) { create(:genre, section_id: section.id) }
      let(:section) { create(:section) }

      before do
        genre.stub(:section_except_admin).and_return(section)
      end

      it "sectionのnameを返すこと" do
        expect(genre.section_name_except_super).to eq(section.name)
      end

      context "section_except_adminの返り値がnilの場合" do
        before do
          genre.stub(:section_except_super).and_return(nil)
        end

        it "空文字を返すこと" do
          expect(genre.section_name_except_super).to eq('')
        end
      end
    end

    describe "#analytics_code_also_parent" do
      context "tracking_codeが存在する場合" do
        let(:tracking_code) { 'tracking_code' }
        let(:genre) { create(:genre, tracking_code: tracking_code) }

        it "tracking_codeを返すこと" do
          expect(genre.analytics_code_also_parent).to eq(tracking_code)
        end
      end

      context "tracking_codeが存在しない場合" do
        let(:genre) { create(:genre) }

        it "nilを返すこと" do
          expect(genre.analytics_code_also_parent).to eq(nil)
        end
      end
    end

    describe "#all_children" do
      before do
        @all_genres = []
        @all_genres << @big_genre = create(:genre)
        @all_genres << middle_genre = create(:genre, parent_id: @big_genre.id)
        @all_genres << create(:genre, parent_id: middle_genre.id)
      end

      it "自分のフォルダ以下のGenreを取得していること" do
        expect(@big_genre.all_children).to match_array(@all_genres)
      end
    end

    describe "#all_pages" do
      before do
        @big_genre = create(:genre)
        middle_genre = create(:genre, parent_id: @big_genre.id)
        small_genre = create(:genre, parent_id: middle_genre.id)

        @all_pages = []
        @all_pages << create(:page, genre_id: @big_genre.id)
        @all_pages << create(:page, genre_id: middle_genre.id)
        @all_pages << create(:page, genre_id: small_genre.id)
      end

      it "自分のフォルダ以下のPageを取得していること" do
        expect(@big_genre.all_contained_pages.flatten).to match_array(@all_pages)
      end
    end

    describe "#has_publish_content?" do
      before do
        @big_genre = create(:genre)
        middle_genre = create(:genre, parent_id: @big_genre.id)
        create(:genre, parent_id: middle_genre.id)
      end

      context "フォルダ以下に公開ページを持っている場合" do
        before do
          create(:page, :publish, genre_id: @big_genre.id)
        end

        it "trueが返ること" do
          expect(@big_genre.has_publish_content?).to be_true
        end
      end

      context "公開ページを持っていない場合" do
        it "trueが返ること" do
          expect(@big_genre.has_publish_content?).to be_false
        end
      end
    end

    describe "#copyable?" do
      let!(:root) { create(:top_genre) }
      let!(:grandparent) { create(:genre, parent: root) }
      let!(:parent) { create(:genre, parent: grandparent) }
      let!(:me) { create(:genre, parent: parent) }
      let!(:child1)  { create(:genre, parent: me) }
      let!(:child2) { create(:genre, parent: me) }
      let!(:grandchild)  { create(:genre, parent: child2) }
      let!(:uncle) { create(:genre, parent: grandparent) }
      let!(:cousin1) { create(:genre, parent: uncle) }
      let!(:cousin2) { create(:genre, parent: uncle) }

      subject{ me.reload.copyable? }

      it '自身のアクセス制御が有効の場合は false が返ること' do
        me.update_attribute(:auth, true)
        expect(subject).to be_false
      end

      it '子ジャンルのアクセス制御が有効の場合は false が返ること' do
        child1.update_attribute(:auth, true)
        expect(subject).to be_false
      end

      it '孫ジャンルのアクセス制御が有効の場合は false が返ること' do
        grandchild.update_attribute(:auth, true)
        expect(subject).to be_false
      end

      it '親ジャンルのアクセス制御が有効の場合は false が返ること' do
        parent.update_attribute(:auth, true)
        expect(subject).to be_false
      end

      it '祖父母ジャンルのアクセス制御が有効の場合は false が返ること' do
        grandparent.update_attribute(:auth, true)
        expect(subject).to be_false
      end

      it '叔父ジャンルのアクセス制御が有効の場合は true が返ること' do
        uncle.update_attribute(:auth, true)
        expect(subject).to be_true
      end

      it 'いとこジャンルのアクセス制御が有効の場合は true が返ること' do
        cousin1.update_attribute(:auth, true)
        expect(subject).to be_true
      end

      context '引数に validate: true を指定する場合' do
        subject{ me.reload.copyable?(validate: true) }

        context 'アクセス制限が有効である場合' do
          before do
            me.update_attribute(:auth, true)
          end

          it 'false を返すこと' do
            expect(subject).to be_false
          end

          it '#errors にエラーメッセージが格納されること' do
            subject
            expect(me.errors.full_messages).to include(
              I18n.t('activerecord.errors.models.genre.attributes.base.copy/auth')
            )
          end
        end

        context 'エラー条件に当てはまらない場合' do
          it 'true を返すこと' do
            expect(subject).to be_true
          end

          it '#errors は空であること' do
            subject
            expect(me.errors.full_messages).to be_empty
          end
        end
      end

      context '引数に validate: true を指定しない場合' do
        subject{ me.reload.copyable? }

        context 'アクセス制限が有効である場合' do
          before do
            me.update_attribute(:auth, true)
          end

          it 'false を返すこと' do
            expect(subject).to be_false
          end

          it '#errors は空であるること' do
            subject
            expect(me.errors.full_messages).to be_empty
          end
        end

        context 'エラー条件に当てはまらない場合' do
          it 'true を返すこと' do
            expect(subject).to be_true
          end

          it '#errors は空であること' do
            subject
            expect(me.errors.full_messages).to be_empty
          end
        end
      end
    end

    describe "copy!" do
      let(:top) { create(:top_genre) }
      let(:org) { create(:genre, parent: top) }
      let(:dest) { create(:genre, parent: top) }
      let(:user) { create(:user, section: org.section) }

      subject { org.copy!(user, dest) }

      context "正常系" do
        before do
          org.children += create_list(:genre, 2,  parent: org)
          @org_children = org.children.to_a
          @org_gchildren = []
          @org_children.each { |c| @org_gchildren << create(:genre,  parent: c) }
          @org_children.each(&:reload)
        end

        it "trueが返ること" do
          expect(subject).to be_true
        end

        it "コピーした数だけGenreレコードが登録されること" do
          subject
          expect(Genre.where(['original_id IS NOT NULL']).size).to eq(5)
        end

        it "dest配下にorgのコピーが作成されること" do
          subject
          dest.reload
          assets_copy_genre(org, dest.children.first, dest)

          @org_children.each do |org_child|
            copy_child = Genre.where(original_id: org_child.id).first
            expect(copy_child).not_to be_nil
            org_child.children.each do |org_gchild|
              copy_gchild = Genre.where(original_id: org_gchild.id).first
              expect(copy_gchild).not_to be_nil
            end
          end
        end

        it "コピーしたフォルダのcreate_genreジョブが追加されること" do
          expect{ subject }.to change(Job, :count).by(5)
          Genre.where(['original_id IS NOT NULL']).each do |genre|
            job = Job.where(action: Job::CREATE_GENRE, arg1: genre.id.to_s)
            expect(job.present?).to be_true
          end
        end

        context " コピー元のフォルダにページがある場合" do
          context "公開待ち、公開中のページがない場合" do
            before do
              @org_pages = create_list(:page_editing, 2, genre: org)
              @org_children_pages = []
              @org_gchildren_pages = []
              @org_children.each { |g| @org_children_pages << create_list(:page_editing, 2, genre: g) }
              @org_gchildren.each { |g| @org_gchildren_pages << create_list(:page_editing, 2, genre: g) }

              subject
            end

            it "create_page, cancel_page ジョブが登録されないこと" do
              expect(Job.where(action: Job::CREATE_PAGE).size).to eq(0)
              expect(Job.where(action: Job::CANCEL_PAGE).size).to eq(0)
            end

            it "コピーした数だけPageレコードが登録されること" do
              expect(Page.where(['original_id IS NOT NULL']).size).to eq(5*2)
            end

            it "コピーしたページの内容が正しいこと" do
              (@org_pages+@org_children_pages+@org_gchildren_pages).flatten.each do |org_page|
                org_page.copies.each do |dest_page|
                  assets_copy_page(org_page, dest_page)
                end
              end
            end
          end

          context "公開待ちのページがある場合" do
            before do
              @org_pages = create_list(:page_waiting, 2, genre: org)
              subject
            end

            it "create_page, cancel_page ジョブが登録されること" do
              @org_pages.each do |org_page|
                org_page.copies.each do |dest_page|
                  expect(Job.where(action: Job::CREATE_PAGE, arg1: dest_page.id.to_s).size).to eq(1)
                  expect(Job.where(action: Job::CANCEL_PAGE, arg1: dest_page.id.to_s).size).to eq(1)
                end
              end
            end
          end

          context "公開中のページがある場合" do
            before do
              @org_pages = create_list(:page_publish, 2, genre: org)
              subject
            end

            it "create_page, cancel_page ジョブが登録されること" do
              @org_pages.each do |org_page|
                org_page.copies.each do |dest_page|
                  expect(Job.where(action: Job::CREATE_PAGE, arg1: dest_page.id.to_s).size).to eq(1)
                  expect(Job.where(action: Job::CANCEL_PAGE, arg1: dest_page.id.to_s).size).to eq(1)
                end
              end
            end
          end
          context "公開待ち・公開中両方のコンテンツを持つページがある場合" do
            before do
              @org_page = create(:page, genre: org)
              @org_page_content_publish = create(:page_content_publish, page: @org_page, begin_date: nil, end_date: nil)
              @org_page_content_waiting = create(:page_content_waiting, page: @org_page)
              subject
            end

            it "create_page, cancel_page ジョブが登録されること" do
              @org_page.copies.each do |dest_page|
                expect(Job.where(action: Job::CREATE_PAGE, arg1: dest_page.id.to_s).size).to eq(2)
                expect(Job.where(action: Job::CANCEL_PAGE, arg1: dest_page.id.to_s).size).to eq(1)
              end
            end
          end
        end
      end

      context "異常系" do
        context "コピー元のアクセス権限を持たない場合" do
          let(:user) { create(:normal_user, section: dest.section) }

          before do
            org.section_id += 1
          end

          it "falseが返ること" do
            expect(subject).to be_false
            expect(org.errors[:base]).to eq([I18n.t('activerecord.errors.models.genre.org_no_permission')])
          end
        end

        context "移動先のフォルダの権限を持たない場合" do
          let(:user) { create(:normal_user, section: org.section) }

          before do
            dest.section_id += 1
          end

          it "falseが返ること" do
            expect(subject).to be_false
            expect(org.errors[:base]).to eq([I18n.t('activerecord.errors.models.genre.dest_no_permission')])
          end
        end

        context "移動先のフォルダと移動元のフォルダが同じ場合" do
          let(:dest) { org.parent }

          it "falseが返ること" do
            expect(subject).to be_false
            expect(org.errors[:base]).to eq([I18n.t('activerecord.errors.models.genre.no_same_parent')])
          end
        end

        context "移動先のフォルダが移動元のフォルダの子孫の場合" do
          let(:dest) { create(:genre, parent: org).tap{ org.reload } }

          it "falseが返ること" do
            expect(subject).to be_false
            expect(org.errors[:base]).to eq([I18n.t('activerecord.errors.models.genre.no_descendants')])
          end
        end
      end
    end

    describe ".root_treeview" do
      before do
        @admin = create(:user)
        @user_1  = create(:normal_user, section_id: 10)
        @user_2  = create(:normal_user, section_id: 20)

        Genre.delete_all

        @top = create(:top_genre, section_id: 1)
        @child_1 = create(:genre, parent_id: @top.id, section_id: 10, no: 1)
        @child_2 = create(:genre, parent_id: @top.id, section_id: 20, no: 2)
        @gchild_1 = create(:genre, parent_id: @child_1.id, section_id: 10, no: 1)
        @gchild_2 = create(:genre, parent_id: @child_2.id, section_id: 10, no: 2)
      end

      context "運用管理者の場合" do
        it "トップフォルダとその直下のフォルダが取得できること" do
          expect(Genre.root_treeview(@admin)).to eq([{
            id: @top.id,
            title: @top.title,
            folder: true,
            active: false,
            path: @top.path,
            expanded: true,
            lazy: false,
            children: [{
              id: @child_1.id,
              title: @child_1.title,
              folder: true,
              active: false,
              path: @child_1.path,
              expanded: false,
              lazy: true
            },
            {
              id: @child_2.id,
              title: @child_2.title,
              folder: true,
              active: false,
              path: @child_2.path,
              expanded: false,
              lazy: true
            }]
          }]
        )
        end
      end

      context "運用管理者以外の場合" do
        it "所属のルートフォルダが取得できること" do
          expect(Genre.root_treeview(@user_1)).to eq(
           [{
              id: @top.id,
              title: @top.title,
              folder: true,
              active: false,
              path: @top.path,
              expanded: true,
              lazy: false,
              no_permission: true,
              extraClasses: 'unselectable',
              children: [{
                id: @child_1.id,
                title: @child_1.title,
                folder: true,
                active: false,
                path: @child_1.path,
                expanded: false,
                lazy: true
              },
              { id: @child_2.id,
                title: @child_2.title,
                folder: true,
                active: false,
                path: @child_2.path,
                expanded: true,
                lazy: false,
                no_permission: true,
                extraClasses: 'unselectable',
                children: [{
                  id: @gchild_2.id,
                  title: @gchild_2.title,
                  folder: true,
                  active: false,
                  path: @gchild_2.path,
                  expanded: false,
                  lazy: false
                }]
              }]
            }]
          )
        end
      end
    end
  end

  def assets_copy_genre(org, dest, dest_parent)
    expect(dest.name).to eq(org.name)
    expect(dest.title).to eq(org.title)
    expect(dest.parent_id).to eq(dest_parent.id)
    expect(dest.original_id).to eq(org.id)
  end

  def assets_copy_page(org, dest)
    expect(dest.name).to eq(org.name)
    expect(dest.title).to eq(org.title)
    expect(dest.genre.original).to eq(org.genre)
    expect(dest.original_id).to eq(org.id)
  end

  def treeview_data(genre, active=false, unselectable=false, expanded=false, has_children=false)
    data = {
      id: genre.id,
      title: genre.title,
      folder: true,
      active: active,
      path: genre.path,
      expanded: expanded
    }

    if unselectable
      data[:no_permission] = true
      data[:extraClasses] = 'unselectable'
    end

    if has_children
      if expanded
        data[:lazy] = false
      else
        data[:lazy] = true
      end
    else
      data[:lazy] = false
    end
    data
  end

end
