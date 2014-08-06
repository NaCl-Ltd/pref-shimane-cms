require 'spec_helper'

describe BlogManagement::Susanoo::PageContentsController do
  describe "アクション" do
    before do
      @division = create(:division)
      @sections = create_list(:section, 3, division: @division)
      @user = create(:user, section: @sections[0])

      # ブログトップ、年、月のジャンルを作成
      @blog_top_genre = create(:top_genre, blog_folder_type: Genre.blog_folder_types[:top])
      @blog_top_genre.create_year_month_folder!
      @blog_year_genre = @blog_top_genre.children.first
      @blog_month_genre = @blog_year_genre.children.first

      # ブログトップ、年、月のインデックスページを作成
      @blog_top_page = create(:page, name: "index", genre: @blog_top_genre)
      @blog_year_page = create(:page, name: "index", genre: @blog_year_genre)
      @blog_month_page = create(:page, name: "index", genre: @blog_month_genre)

      # ブログページを作成
      @blog_page = create(:page, name: Date.today.day.to_s, genre: @blog_month_genre, blog_date: Date.today)

      controller.stub(:enable_engine_required).and_return(true)
      login(@user)
    end

    describe "GET new" do
      describe "正常系" do
        subject { get :new, page_id: @blog_page.id, use_route: :blog_management }

        it "newをrenderしていること" do
          expect(subject).to render_template(:new)
        end

        it "page_contentオブジェクトが取得できていること" do
          subject
          expect(assigns[:page_content]).to be_a(PageContent)
        end

        it "pageオブジェクトが新規インスタンスであること" do
          subject
          expect(assigns[:page_content].new_record?).to be_true
        end
      end
    end

    describe "POST create" do
      let(:page_content_attributes) {
        {
          content: %Q(<div class="editable data-type-h"><h1>1</h1></div><button class="editable data-type-plugin" name="page_list" value="1,2">plugin</button>),
          mobile: %Q(<div class="editable data-type-h"><h1>1</h1></div><button class="editable data-type-plugin" name="page_list" value="1,2">plugin</button>),
          page_id: @blog_page.id
        }
      }
      let(:post_parameters) { {page_content: page_content_attributes, use_route: :blog_management} }

      describe "正常系" do
        subject { xhr :post, :create,  post_parameters }

        it "page_contentsテーブルにレコードが4件追加されていること" do
          expect{subject}.to change(PageContent, :count).by(4)
        end

        it "createをrenderしていること" do
          expect(subject).to render_template(:create)
        end

        describe "一時保存" do
          context "パラメータに'_save_temporarily'要素がある場合" do
            before do
              post_parameters.update(_save_temporarily: '')
            end

            context "保存ボタンで保存した場合" do
              before do
                post_parameters.update(commit: 'save')
              end

              it "PageContent#edit_required は false であること" do
                subject
                new_page_content = PageContent.last
                expect(new_page_content.edit_required).to be_false
              end
            end

            context "一時保存ボタンで保存した場合" do
              before do
                post_parameters.update(commit: 'save_temporarily')
              end

              it "PageContent#edit_required は true であること" do
                subject
                new_page_content = PageContent.last
                expect(new_page_content.edit_required).to be_true
              end
            end
          end

          context "パラメータに'_save_temporarily'要素が無い場合" do
            context "保存ボタンで保存した場合" do
              before do
                post_parameters.update(commit: 'save')
              end

              it "PageContent#edit_required は false であること" do
                subject
                new_page_content = PageContent.last
                expect(new_page_content.edit_required).to be_false
              end
            end

            context "一時保存ボタンで保存した場合" do
              before do
                post_parameters.update(commit: 'save_temporarily')
              end

              it "PageContent#edit_required は false であること" do
                subject
                new_page_content = PageContent.last
                expect(new_page_content.edit_required).to be_false
              end
            end
          end
        end
      end

      describe "異常系" do
        context "バリデーションに失敗した場合" do
          before do
            page_content_attributes.merge!(content: "")
          end

          subject { xhr :post, :create,  post_parameters }

          it "create_errorをrenderしていること" do
            expect(subject).to render_template("create_error")
          end

          it "page_contentsテーブルにレコードが追加されないこと" do
            expect{subject}.to change(Page, :count).by(0)
          end
        end
      end
    end

    describe "PATCH update" do
      let(:page) { @blog_page }
      let(:page_content) { create(:page_content_editing, page: page) }
      let(:post_parameters) { {id: page_content.id, page_content: page_content_attributes, use_route: :blog_management} }
      subject { xhr :patch, :update, post_parameters }

      describe "正常系" do
        let(:page_content_attributes) {
          {
            content: %Q(<div class="editable data-type-h"><h1>1</h1></div><button class="editable data-type-plugin" name="page_list" value="1,2">plugin</button>),
            mobile: %Q(<div class="editable data-type-h"><h1>1</h1></div><button class="editable data-type-plugin" name="page_list" value="1,2">plugin</button>),
          }
        }

        context "一時保存されたページコンテンツ" do
          before do
            page_content.update_attribute(:edit_required, true)
            page_content.reload
          end

          context "パラメータに'_save_temporarily'要素がある場合" do
            before do
              post_parameters.update(_save_temporarily: '')
            end

            context "保存ボタンで保存した場合" do
              before do
                post_parameters.update(commit: 'save')
              end

              it "PageContent#edit_required は false であること" do
                subject
                expect(page_content.reload.edit_required).to be_false
              end
            end

            context "一時保存ボタンで保存した場合" do
              before do
                post_parameters.update(commit: 'save_temporarily')
              end

              it "PageContent#edit_required は true であること" do
                subject
                expect(page_content.reload.edit_required).to be_true
              end
            end
          end

          context "パラメータに'_save_temporarily'要素が無い場合" do
            context "保存ボタンで保存した場合" do
              before do
                post_parameters.update(commit: 'save')
              end

              it "PageContent#edit_required は true であること" do
                subject
                expect(page_content.reload.edit_required).to be_true
              end
            end

            context "一時保存ボタンで保存した場合" do
              before do
                post_parameters.update(commit: 'save_temporarily')
              end

              it "PageContent#edit_required は true であること" do
                subject
                expect(page_content.reload.edit_required).to be_true
              end
            end
          end
        end

        context "一時保存でないページコンテンツ" do
          before do
            page_content.update_attribute(:edit_required, false)
            page_content.reload
          end

          context "パラメータに'_save_temporarily'要素がある場合" do
            before do
              post_parameters.update(_save_temporarily: '')
            end

            context "保存ボタンで保存した場合" do
              before do
                post_parameters.update(commit: 'save')
              end

              it "PageContent#edit_required は false であること" do
                subject
                expect(page_content.reload.edit_required).to be_false
              end
            end

            context "一時保存ボタンで保存した場合" do
              before do
                post_parameters.update(commit: 'save_temporarily')
              end

              it "PageContent#edit_required は true であること" do
                subject
                expect(page_content.reload.edit_required).to be_true
              end
            end
          end

          context "パラメータに'_save_temporarily'要素が無い場合" do
            context "保存ボタンで保存した場合" do
              before do
                post_parameters.update(commit: 'save')
              end

              it "PageContent#edit_required は false であること" do
                subject
                expect(page_content.reload.edit_required).to be_false
              end
            end

            context "一時保存ボタンで保存した場合" do
              before do
                post_parameters.update(commit: 'save_temporarily')
              end

              it "PageContent#edit_required は false であること" do
                subject
                expect(page_content.reload.edit_required).to be_false
              end
            end
          end
        end
      end
    end

    describe "GET edit_private_page_status" do
      let(:page_content) { create(:page_content_base, :editing, page: @blog_page) }

      describe "正常系" do
        subject { get :edit_private_page_status, id: page_content.id, use_route: :blog_management }

        it "edit_private_page_statusをrenderしていること" do
          expect(subject).to render_template(:edit_private_page_status)
        end

        it "page_contentオブジェクトが取得できていること" do
          subject
          expect(assigns[:page_content]).to be_a(PageContent)
        end

        it "pageオブジェクトが新規インスタンスでないこと" do
          subject
          expect(!assigns[:page_content].new_record?).to be_true
        end
      end
    end

    describe "PATCH update_private_page_status" do
      before do
        @page_content = create(:page_content_base, :editing, page: @blog_page, email: "abc")
      end

      describe "正常系" do
        describe "admissionを公開中にした場合" do
          describe "前後の月に公開ページがない場合" do
            subject { patch :update_private_page_status, id: @page_content.id, page_content: {admission: PageContent.page_status[:publish]}, use_route: :blog_management }

            it "admissionが公開中に変わること" do
              subject
              expect(@page_content.reload.admission).to eq PageContent.page_status[:publish]
            end

            it "Jobが5件追加されていること" do
              expect{subject}.to change(Job, :count).by(5)
            end

            it "blog_management/pages/showにリダイレクトすること" do
              expect(subject).to redirect_to(susanoo_page_path(@blog_page))
            end
          end

          describe "前後の月に公開ページがある場合" do
            before do
              [Date.today.prev_year, Date.today.next_year].each do |date|
                # 年、月のジャンルを作成
                @blog_top_genre.create_year_month_folder!(date)
                blog_year_genre = @blog_top_genre.children.where(name: date.year.to_s).first
                blog_month_genre = blog_year_genre.children.where(name: date.month.to_s).first
                # 年、月のインデックスページを作成
                blog_year_page = create(:page, name: "index", genre: blog_year_genre)
                blog_month_page = create(:page, name: "index", genre: blog_month_genre)
                # ブログページを作成
                blog_page = create(:page, name: Date.today.day.to_s, genre: blog_month_genre, blog_date: date)
                # ブログページコンテントを作成
                create(:page_content_base, :publish, page: blog_page, email: "abc")
              end
            end

            subject { patch :update_private_page_status, id: @page_content.id, page_content: {admission: PageContent.page_status[:publish]}, use_route: :blog_management }

            it "admissionが公開中に変わること" do
              subject
              expect(@page_content.reload.admission).to eq PageContent.page_status[:publish]
            end

            it "ページ作成Jobが9件追加されていること" do
              expect{subject}.to change { Job.where(action: Job::CREATE_PAGE).count }.by(9)
            end

            it "blog_management/pages/showにリダイレクトすること" do
              expect(subject).to redirect_to(susanoo_page_path(@blog_page))
            end
          end
        end
      end

      describe "異常系" do
        subject { patch :update_private_page_status, id: @page_content.id,
          page_content: {admission: nil}, use_route: :blog_management }

        it "admissionが編集中のまま変わらないこと" do
          subject
          expect(@page_content.reload.admission).to eq PageContent.page_status[:editing]
        end

        it "Jobが追加されていないこと" do
          expect{subject}.to change(Job, :count).by(0)
        end

        it "edit_private_page_statusをrenderしていること" do
          expect(subject).to render_template(:edit_private_page_status)
        end
      end
    end

    describe "PATCH update_public_page_status" do
      before do
        @page_content = create(:page_content_base, :publish, page: @blog_page, email: "abc")
      end

      describe "正常系" do
        describe "admissionを公開停止にした場合" do
          describe "前後の月に公開ページがない場合" do
            subject { patch :update_public_page_status, id: @page_content.id, page_content: {admission: PageContent.page_status[:cancel]}, use_route: :blog_management }
            it "admissionが公開停止に変わること" do
              expect{ subject }.to change { @page_content.reload.admission }
                .from(PageContent.page_status[:publish])
                .to(PageContent.page_status[:cancel])
            end

            it "ページ削除Jobが1件追加されていること" do
              expect{subject}.to change { Job.where(action: Job::CANCEL_PAGE).count }.by(1)
            end

            it "ページ作成Jobが4件追加されていること" do
              expect{subject}.to change { Job.where(action: Job::CREATE_PAGE).count }.by(4)
            end

            it "blog_management/pages/showにリダイレクトすること" do
              expect(subject).to redirect_to(susanoo_page_path(@blog_page))
            end
          end

          describe "前後の月に公開ページがある場合" do
            before do
              [Date.today.prev_year, Date.today.next_year].each do |date|
                # 年、月のジャンルを作成
                @blog_top_genre.create_year_month_folder!(date)
                blog_year_genre = @blog_top_genre.children.where(name: date.year.to_s).first
                blog_month_genre = blog_year_genre.children.where(name: date.month.to_s).first
                # 年、月のインデックスページを作成
                blog_year_page = create(:page, name: "index", genre: blog_year_genre)
                blog_month_page = create(:page, name: "index", genre: blog_month_genre)
                # ブログページを作成
                blog_page = create(:page, name: Date.today.day.to_s, genre: blog_month_genre, blog_date: date)
                # ブログページコンテントを作成
                create(:page_content_base, :publish, page: blog_page, email: "abc")
              end
            end

            subject { patch :update_public_page_status, id: @page_content.id, page_content: {admission: PageContent.page_status[:cancel]}, use_route: :blog_management }

            it "admissionが公開停止に変わること" do
              subject
              expect(@page_content.reload.admission).to eq PageContent.page_status[:cancel]
            end

            it "ページ削除Jobが4件追加されていること" do
              expect{subject}.to change { Job.where(action: Job::CANCEL_PAGE).count }.by(1)
            end

            it "ページ作成Jobが8件追加されていること" do
              # 月、年、ブログトップのインデックスページのcreate_pageジョブ
              # 前後のそれぞれ近い月ジャンルとその年ジャンルのインデックスページのcreate_pageジョブ
              expect{subject}.to change { Job.where(action: Job::CREATE_PAGE).count }.by(8)
            end

            it "blog_management/pages/showにリダイレクトすること" do
              expect(subject).to redirect_to(susanoo_page_path(@blog_page))
            end
          end
        end
      end

      describe "異常系" do
        subject { patch :update_public_page_status, id: @page_content.id,
          page_content: {admission: nil}, use_route: :blog_management }

        it "admissionが公開中のまま変わらないこと" do
          subject
          expect(@page_content.reload.admission).to eq PageContent.page_status[:publish]
        end

        it "Jobが追加されていないこと" do
          expect{subject}.to change(Job, :count).by(0)
        end

        it "edit_public_page_statusをrenderしていること" do
          expect(subject).to render_template(:edit_public_page_status)
        end
      end
    end
  end
end
