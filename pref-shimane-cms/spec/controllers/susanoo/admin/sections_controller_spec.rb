require 'spec_helper'

describe Susanoo::Admin::SectionsController do
  describe "フィルタ" do
    describe "admin_required" do
      shared_examples_for "未ログイン時のアクセス制限" do |met, act|
        it "#{met.upcase} #{act}にアクセスしたとき、ログイン画面が表示されること" do
          expect(response).to redirect_to(login_susanoo_users_path)
        end
      end

      shared_examples_for "運用管理者ログイン時のアクセス制限"  do |met, act|
        before{@user = login(create(:user))}
        it "#{met.upcase} #{act}にアクセスしたとき、okが返ること" do
          expect(response.body).to eq("ok")
        end
      end

      shared_examples_for "情報提供責任者ログイン時のアクセス制限"  do |met, act|
        before{@user = login(create(:section_user))}
        it "#{met.upcase} #{act}にアクセスしたとき、トップページへリダイレクトされること" do
          expect(response).to redirect_to(susanoo_dashboards_path)
        end
      end

      shared_examples_for "一般ユーザログイン時のアクセス制限" do |met, act|
        before{@user = login(create(:normal_user))}
        it "#{met.upcase} #{act}にアクセスしたとき、トップページへリダイレクトされること" do
          expect(response).to redirect_to(susanoo_dashboards_path)
        end
      end

      controller do
        %w(index new create edit update destroy update_sort).each do |act|
          define_method(act) do
            render text: "ok"
          end
        end
      end

      before do
        # 他のフィルタを停止
        controller.stub(:set_section).and_return(true)
        @routes.draw do
          resources :anonymous do
            collection do
              post :update_sort
            end
          end
        end
        @section = create(:section)
      end

      context "未ログイン状態" do
        it_behaves_like("未ログイン時のアクセス制限", :get, :index)         {before{get :index}}
        it_behaves_like("未ログイン時のアクセス制限", :get, :new)           {before{get :new}}
        it_behaves_like("未ログイン時のアクセス制限", :post, :create)       {before{post :create}}
        it_behaves_like("未ログイン時のアクセス制限", :get, :edit)          {before{get :edit, id: @section.id}}
        it_behaves_like("未ログイン時のアクセス制限", :patch, :update)      {before{patch :update, id: @section.id}}
        it_behaves_like("未ログイン時のアクセス制限", :delete, :destroy)    {before{delete :destroy, id: @section.id}}
        it_behaves_like("未ログイン時のアクセス制限", :post, :update_sort)  {before{post :update_sort}}
      end

      context "ログイン状態" do
        context "運用管理者の場合" do
          it_behaves_like("運用管理者ログイン時のアクセス制限", :get, :index)         {before{get :index}}
          it_behaves_like("運用管理者ログイン時のアクセス制限", :get, :new)           {before{get :new}}
          it_behaves_like("運用管理者ログイン時のアクセス制限", :post, :create)       {before{post :create}}
          it_behaves_like("運用管理者ログイン時のアクセス制限", :get, :edit)          {before{get :edit, id: @section.id}}
          it_behaves_like("運用管理者ログイン時のアクセス制限", :patch, :update)      {before{patch :update, id: @section.id}}
          it_behaves_like("運用管理者ログイン時のアクセス制限", :delete, :destroy)    {before{delete :destroy, id: @section.id}}
          it_behaves_like("運用管理者ログイン時のアクセス制限", :post, :update_sort)  {before{post :update_sort}}
        end

        context "情報提供責任者の場合" do
          it_behaves_like("情報提供責任者ログイン時のアクセス制限", :get, :index)         {before{get :index}}
          it_behaves_like("情報提供責任者ログイン時のアクセス制限", :get, :new)           {before{get :new}}
          it_behaves_like("情報提供責任者ログイン時のアクセス制限", :post, :create)       {before{post :create}}
          it_behaves_like("情報提供責任者ログイン時のアクセス制限", :get, :edit)          {before{get :edit, id: @section.id}}
          it_behaves_like("情報提供責任者ログイン時のアクセス制限", :patch, :update)      {before{patch :update, id: @section.id}}
          it_behaves_like("情報提供責任者ログイン時のアクセス制限", :delete, :destroy)    {before{delete :destroy, id: @section.id}}
          it_behaves_like("情報提供責任者ログイン時のアクセス制限", :post, :update_sort)  {before{post :update_sort}}
        end

        context "一般ユーザの場合" do
          it_behaves_like("一般ユーザログイン時のアクセス制限", :get, :index)         {before{get :index}}
          it_behaves_like("一般ユーザログイン時のアクセス制限", :get, :new)           {before{get :new}}
          it_behaves_like("一般ユーザログイン時のアクセス制限", :post, :create)       {before{post :create}}
          it_behaves_like("一般ユーザログイン時のアクセス制限", :get, :edit)          {before{get :edit, id: @section.id}}
          it_behaves_like("一般ユーザログイン時のアクセス制限", :patch, :update)      {before{patch :update, id: @section.id}}
          it_behaves_like("一般ユーザログイン時のアクセス制限", :delete, :destroy)    {before{delete :destroy, id: @section.id}}
          it_behaves_like("一般ユーザログイン時のアクセス制限", :post, :update_sort)  {before{post :update_sort}}
        end
      end
    end

    describe "set_section" do
      controller do
        %w(edit update destroy).each do |act|
          define_method(act) do
            render text: "ok"
          end
        end
      end

      before do
        # 他のフィルタを停止
        controller.stub(:admin_required).and_return(true)
        @routes.draw do
          resources :anonymous do
            collection do
              post :update_sort
            end
          end
        end
        @section = create(:section)
      end

      shared_examples_for "インスタンス変数@sectionが正しく設定されているかの検証" do
        it "インスタンス変数@sectionがSectionクラスのインスタンスであること" do
          expect(assigns[:section]).to be_kind_of(Section)
        end

        it "インスタンス変数@sectionのidがパラメータ:idで送った値と等しいこと" do
          expect(assigns[:section].id).to eq(@section.id)
        end
      end

      context "GET editにアクセスしたとき" do
        before do
          get :edit, id: @section.id
        end
        it_behaves_like "インスタンス変数@sectionが正しく設定されているかの検証"
      end

      context "PATCH updateにアクセスしたとき" do
        before do
          patch :update, id: @section.id
        end
        it_behaves_like "インスタンス変数@sectionが正しく設定されているかの検証"
      end

      context "DELETE destroyにアクセスしたとき" do
        before do
          delete :destroy, id: @section.id
        end
        it_behaves_like "インスタンス変数@sectionが正しく設定されているかの検証"
      end
    end
  end

  describe "アクション" do
    describe "GET index" do
      before do
        controller.stub(:admin_required).and_return(true)
      end

      describe "正常系" do
        context "通常のアクセスの場合（非Ajax）" do
          before do
            20.times do
              create(:section)
            end
          end

          subject{get :index}

          it "indexがrenderされること" do
            expect(subject).to render_template(:index)
          end

          it "Sectionがdivision_id順、number順で全件取得できていること" do
            subject
            lists = Section.order("division_id, number").page(0)
            expect(assigns[:sections]).to eq(lists)
          end

          it "@display_navigationがtrueであること" do
            subject
            expect(assigns[:display_navigation]).to be_true
          end

          it "@sectionsが１０件以上ある場合ページネートされていること" do
            subject
            expect(assigns[:sections].count).to eq(10)
          end
        end

        context "Ajaxアクセスの場合" do
          before do
            @division = create(:division)
            20.times do
              create(:section, division_id: @division.id)
            end
          end

          context "params[:division_id]がある場合（部局絞り込み時）" do
            subject{xhr :get, :index, division_id: @division.id}

            it "_searchがrenderされること" do
              expect(subject).to render_template(:_search)
            end

            it "@display_navigationがfalseであること" do
              subject
              expect(assigns[:display_navigation]).to be_false
            end

            it "@sectionsが送られた部局IDにひもづくデータであること" do
              subject
              assigns[:sections].should_not be_empty
              expect(assigns[:sections].all?{|s|s.division_id == @division.id}).to be_true
            end
          end

          context "params[:division_id]が無い場合(全部局表示)" do
            subject{xhr :get, :index}

            it "_searchがrenderされること" do
              expect(subject).to render_template(:_search)
            end

            it "@display_navigationがtrueであること" do
              subject
              expect(assigns[:display_navigation]).to be_true
            end

            it "@sectionsがnumber順で取得されていること" do
              subject
              lists = Section.order("number").page(0)
              expect(assigns[:sections]).to eq(lists)
            end
          end
        end
      end
    end

    describe "GET new" do
      before do
        controller.stub(:admin_required).and_return(true)

        @section = create(:section)
        top_genre = create(:top_genre, section: @section)
        create_list(:second_genre, 2, section: @section, parent: top_genre)
      end

      context "正常系" do
        subject{get :new}

        it "newがrenderされること" do
          expect(subject).to render_template("new")
        end

        it "@sectionがSectionモデルのインスタンスであること" do
          subject
          expect(assigns[:section]).to be_kind_of(Section)
        end

        it "@sectionが新規インスタンスであること" do
          subject
          expect(assigns[:section].new_record?).to be_true
        end
      end
    end

    describe "GET edit" do
      before do
        controller.stub(:admin_required).and_return(true)
        @section = create(:section)
        @section = create(:section)
        top_genre = create(:top_genre, section: @section)
        create(:second_genre, section: @section, parent: top_genre)
      end

      context "正常系" do
        subject{get :edit, id: @section.id}

        it "editがrenderされること" do
          expect(subject).to render_template("edit")
        end

        it "@sectionがSectionモデルのインスタンスであること" do
          subject
          expect(assigns[:section]).to be_kind_of(Section)
        end

        it "@sectionは既存のレコードのインスタンスであること" do
          subject
          expect(assigns[:section].new_record?).to be_false
        end
      end
    end

    describe "POST create" do
      before do
        controller.stub(:admin_required).and_return(true)
        @section = create(:section)
        @section = create(:section)
        top_genre = create(:top_genre, section: @section)
        create(:second_genre, section: @section, parent: top_genre)

        @division = Division.first
        @genre = Genre.top_genre.children.first
      end

      context "正常系" do
        context "バリデーションに成功した場合" do
          before do
            Section.any_instance.stub(:valid?).and_return(true)
          end

          subject{post :create, section_params(genre: {id: @genre.id})}

          it "Sectionレコードが１件増えていること" do
            expect{subject}.to change(Section, :count).by(1)
          end

          it "numberに選択した部署に登録されている所属のnumberの最大値+1の値がセットされること" do
            expect{subject}.to change{@division.sections.maximum(:number)}.by(1)
          end

          context "保存に成功した場合" do
            before do
              Section.any_instance.stub(:save!).and_return(true)
            end

            it "所属一覧にリダイレクトすること" do
              expect(subject).to redirect_to(susanoo_admin_sections_path)
            end
          end

          context "保存に失敗した場合" do
            before do
              Section.any_instance.stub(:save!).and_raise
            end

            subject{post :create, section_params(genre: {id: @genre.id})}

            it "再度作成画面が描画されること" do
              expect(subject).to render_template("new")
            end
          end

          context "params[:genre][:name]が入力された場合" do
            let(:name){"section_top_folder"}
            subject{post :create, section_params(genre: {name: name})}

            it "フォルダが１つ追加されていること" do
              expect{subject}.to change(Genre, :count).by(1)
            end

            context "作成されたフォルダの検証" do
              it "フォルダのtitleが所属のnameと同じであること" do
                subject
                section = Section.last
                genre = Genre.last
                expect(genre.title).to eq(section.name)
              end

              it "フォルダのnameがparams[:genre][:name]と同じであること" do
                subject
                section = Section.last
                genre = Genre.last
                expect(genre.name).to eq(name)
              end

              it "フォルダのsection_idが作成したSectionのidと同じであること" do
                subject
                section = Section.last
                genre = Genre.last
                expect(genre.section_id).to eq(section.id)
              end

              it "作成されたSectionのtop_genre_idが追加されたフォルダとなっていること" do
                subject
                section = Section.last
                genre = Genre.last
                expect(section.top_genre_id).to eq(genre.id)
              end
            end
          end
        end
      end

      describe "異常系" do
        context "バリデーションに失敗した場合" do
          before do
            Section.any_instance.stub(:valid?).and_return(false)
          end

          subject{post :create, section_params(genre: {id: @genre.id})}

          it "再度作成画面が描画されること" do
            expect(subject).to render_template("new")
          end

          it "レコードが追加されていないこと" do
            expect{subject}.to change(Section, :count).by(0)
          end
        end

        context "パラメータ:sectionにnumberがセットされた場合" do
          let(:number){50000}
          subject{post :create, section_params(genre: {id: @genre.id}, section: {number: number})}

          it "number項目に値がセットされないこと" do
            expect(Section.maximum(:number)).to_not eq(number)
          end
        end
      end
    end

    describe "PATCH update" do
      before do
        controller.stub(:admin_required).and_return(true)

        @section = create(:section)
        top_genre = create(:top_genre, section: @section)
        create_list(:second_genre, 2, section: @section, parent: top_genre)
        @division = Division.first
      end

      context "正常系" do
        before do
          @genre = Genre.top_genre.children.first
        end

        context "バリデーションに成功した場合" do
          before do
            Section.any_instance.stub(:valid?).and_return(true)
          end

          subject{patch :update, section_params(id: @section.id, genre: {id: @genre.id})}

          it "所属一覧にリダイレクトすること" do
            expect(subject).to redirect_to(susanoo_admin_sections_path)
          end

          context "params[:genre][:id]が入力された場合" do
            it "選択したフォルダが所属のトップフォルダが割り当てられること" do
              subject
              expect(@section.reload.top_genre_id).to eq(@genre.id)
            end
          end

          context "params[:genre][:id]が指定無しの場合" do
            subject{patch :update, section_params(id: @section.id, genre: {id: nil})}

            it "対象の所属のトップフォルダをnilにする" do
              subject
              expect(@section.reload.top_genre_id).to be_nil
            end
          end
        end
      end

      describe "異常系" do
        context "バリデーションに失敗した場合" do
          before do
            Section.any_instance.stub(:valid?).and_return(false)
          end

          subject{patch :update, section_params(id: @section.id, genre: {id: nil})}

          it "再度作成画面が描画されること" do
            expect(subject).to render_template("edit")
          end

          it "editが呼ばれること" do
            controller.should_receive(:edit)
            subject
          end
        end

        context "パラメータ:sectionにnumberがセットされた場合" do
          let(:number){50000}
          subject{patch :update, section_params(id: @section.id, genre: {id: nil}, section: {number: number})}

          it "number項目に値がセットされないこと" do
            expect(Section.maximum(:number)).to_not eq(number)
          end
        end
      end
    end

    describe "DELETE destroy" do
      before do
        controller.stub(:admin_required).and_return(true)
        @section = create(:section)

        top_genre = create(:top_genre, section: @section)
        create_list(:second_genre, 2, section: @section, parent: top_genre)

        @division = Division.first
      end

      context "正常系" do
        context "削除処理に成功した場合" do
          before do
            @user = login(create(:user))
            @genre = Genre.top_genre.children.first
          end

          it "所属一覧にリダイレクトすること" do
            delete :destroy, id: @section.id
            response.should redirect_to(susanoo_admin_sections_path)
          end

          it "選択した所属が削除されていること" do
            expect do
              delete :destroy, id: @section.id
            end.to change(Section, :count).by(-1)
            Section.exists?(@section.id).should be_false
          end

          it "削除した所属のフォルダの所属がsuper_sectionの値に変わっていること" do
            super_section = create(:section, code: Settings.section.admin_code)

            genres = @section.genres
            genres.should_not be_empty
            genres.all?{|g|g.section_id == @section.id}
            delete :destroy, id: @section.id
            genres.reload.all?{|g|g.section_id == super_section.id}
          end
        end
      end

      context "異常系" do
        subject{delete :destroy, id: @section.id}

        context "削除処理に失敗した場合" do
          before do
            @user = login(create(:user))
            Section.any_instance.stub(:destroy).and_raise
          end

          it "所属一覧にリダイレクトすること" do
            expect(subject).to redirect_to(susanoo_admin_sections_path)
          end
        end

        context "所属に割り当てられているフォルダの更新に失敗した場合" do
          before do
            @user = login(create(:user))
            Section.any_instance.stub_chain(:genres, :update_all).and_raise
          end

          it "所属一覧にリダイレクトすること" do
            expect(subject).to redirect_to(susanoo_admin_sections_path)
          end
        end
      end
    end

    describe "POST update_sort" do
      before do
        controller.stub(:admin_required).and_return(true)
        @sections = create_list(:section, 3)
      end

      describe "正常系" do
        context "並び替え処理に成功した場合" do
          it "並び替え結果画面が描画されること" do
            post :update_sort, item: @sections.map(&:id)
            expect(response).to render_template("_sort")
          end

          it "送られたIDの順に並び替えられていること" do
            send_ids = @sections.sort_by(&:number).map(&:id).reverse
            post :update_sort, item: send_ids
            expect(Section.order("number").map(&:id)).to eq(send_ids)
          end
        end
      end

      describe "異常系" do
        context "並び替え処理に成功した場合" do
          let(:ids){@sections.map(&:id)}
          before do
            Section.where(id: ids).destroy_all
          end

          it "sort画面が描画されること" do
            post :update_sort, item: ids
            expect(response).to render_template("_sort")
          end

          it "@errorにエラーメッセージが設定されていること" do
            post :update_sort, item: ids
            result = I18n.t("susanoo.admin.sections.update_sort.failed")
            expect(assigns[:error]).to eq(result)
          end
        end
      end
    end
  end
end

def section_params(attr = {})
  section_attr = attr.delete(:section)
  {
    section: {
      name: "テスト",
      code: "code",
      division_id: @division.id,
      link: "http://localhost",
      ftp: "/contents/example"
    }.merge(section_attr || {})
  }.merge(attr || {})
end
