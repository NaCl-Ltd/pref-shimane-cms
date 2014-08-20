require 'spec_helper'

describe Susanoo::PageContentsController do
  describe "アクション" do
    before do
      @division = create(:division)
      @section = create(:section, division: @division)
      @user = create(:user, section: @section)
      @genre = create(:genre, path: "/", section_id: @section.id)
      login(@user)
    end

    describe "GET new" do
      describe "正常系" do
        let(:page) { create(:page, genre: @genre) }
        subject { get :new, page_id: page.id  }

        it "newをrenderしていること" do
          expect(subject).to render_template(:new)
        end

        it "ページがロックされること" do
          expect{ subject }.to change(PageLock,:count).by(1)
        end

        it "page_contentが新規インスタンスであること" do
          subject
          expect(assigns[:page_content].new_record?).to be_true
        end

        context "指定したページが未公開のコンテンツを持つ場合" do
          let(:page) { create(:page_editing, genre: @genre) }

          it "page_contentが未公開コンテンツと一致すること" do
            subject
            expect(assigns[:page_content]).to eq(page.private_content)
          end
        end

        context "指定したページが公開のコンテンツのみ持つ場合" do
          let(:page) { create(:page_publish_without_private, genre: @genre) }

          it "page_contentが公開コンテンツをコピー編集中コンテンツであること" do
            subject
            expect(assigns[:page_content].content).to eq(page.publish_content.content)
            expect(assigns[:page_content].admission).to eq(PageContent.page_status[:editing])
          end
        end
      end
    end

    describe "POST create" do
      let(:page) { create(:page, genre: @genre) }

      describe "正常系" do
        let(:page_content_attributes) {
          {
            content: %Q(<div class="editable data-type-h"><h1>1</h1></div><button class="editable data-type-plugin" name="page_list" value="1,2">plugin</button>),
            mobile: %Q(<div class="editable data-type-h"><h1>1</h1></div><button class="editable data-type-plugin" name="page_list" value="1,2">plugin</button>),
            page_id: page.id
          }
        }
        let(:post_parameters) { {page_content: page_content_attributes} }
        subject { xhr :post, :create,  post_parameters }

        it "page_contentsテーブルにレコードが1件追加されていること" do
          expect{subject}.to change(PageContent, :count).by(1)
        end

        it "createをrenderしていること" do
          expect(subject).to render_template(:create)
        end

        it "コンテンツが整形されること" do
          expect_content = %Q(<h1>1</h1>\n<%= plugin('page_list', '1', '2') %>)
          subject
          new_page_content = PageContent.last
          expect(new_page_content.content).to eq(expect_content)
          expect(new_page_content.mobile).to eq(expect_content)
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

          let(:page_content_attributes) { { content: "①", page_id: page.id }}
          subject { xhr :post, :create,  page_content: page_content_attributes }

          before do
            allow_any_instance_of(PageContent).to receive(:valid?).and_return(false)
          end

          it "create_errorをrenderしていること" do
            expect(subject).to render_template("create_error")
          end

          it "page_contentsテーブルにレコードが追加されないこと" do
            expect{subject}.to change(PageContent, :count).by(0)
          end
        end
      end
    end

    describe "PATCH update" do
      let!(:page) { create(:page_editing, genre: @genre) }
      let!(:page_content) {
        c = page.contents.first
        c.content = %Q(<h1>1</h1>\n<%= plugin('page_list', '1', '2') %>)
        c.mobile = %Q(<h1>1</h1>\n<%= plugin('page_list', '1', '2') %>)
        c.save
        c
      }
      let!(:post_parameters) { {id: page_content.id, page_content: page_content_attributes} }
      subject { xhr :patch, :update, post_parameters }

      describe "正常系" do
        let(:page_content_attributes) {
          {
            content: %Q(<div class="editable data-type-h"><h1>1</h1></div><button class="editable data-type-plugin" name="page_list" value="3,4">plugin</button>)
          }
        }

        it "createをrenderしていること" do
          expect(subject).to render_template(:create)
        end

        context "PCページ編集の場合" do
          it "PC用コンテンツが更新されること" do
            expect_content = %Q(<h1>1</h1>\n<%= plugin('page_list', '3', '4') %>)
            subject
            new_page_content = PageContent.find(page.contents.first.id)
            expect(new_page_content.content).to eq(expect_content)
          end

          it "携帯用コンテンツが更新されないこと" do
            expect_content = %Q(<h1>1</h1>\n<%= plugin('page_list', '3', '4') %>)
            subject
            new_page_content = PageContent.find(page.contents.first.id)
            expect(new_page_content.mobile).to eq(page_content.mobile)
          end
        end

        context "携帯ページ編集の場合" do
          let(:page_content_attributes) {
            {
              mobile: %Q(<div class="editable data-type-h"><h1>1</h1></div><button class="editable data-type-plugin" name="page_list" value="3,4">plugin</button>)
            }
          }

          it "携帯用コンテンツが更新されること" do
            expect_content = %Q(<h1>1</h1>\n<%= plugin('page_list', '3', '4') %>)
            subject
            new_page_content = PageContent.find(page.contents.first.id)
            expect(new_page_content.mobile).to eq(expect_content)
          end

          it "PC用コンテンツが更新されないこと" do
            expect_content = %Q(<h1>1</h1>\n<%= plugin('page_list', '3', '4') %>)
            subject
            new_page_content = PageContent.find(page.contents.first.id)
            expect(new_page_content.content).to eq(page_content.content)
          end
        end

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

      describe "異常系" do
        context "バリデーションに失敗した場合" do
          let(:page_content_attributes) { { content: "①" }}

          before do
            allow_any_instance_of(PageContent).to receive(:valid?).and_return(false)
          end

          it "create_errorをrenderしていること" do
            expect(subject).to render_template("create_error")
          end

          it "コンテンツが更新されないこと" do
            old_content = page_content.content
            subject
            expect(page_content.reload.content).to eq(old_content)
          end
        end
      end
    end

    describe "GET edit_private_page_status" do
      let(:page) { create(:page, genre: @genre) }
      let(:page_content) { create(:page_content_editing, page: page) }

      describe "正常系" do
        subject { get :edit_private_page_status, id: page_content.id  }

        it "edit_private_page_status を render していること" do
          expect(subject).to render_template(:edit_private_page_status)
        end

        it "page_contentオブジェクトが取得できていること" do
          subject
          expect(assigns[:page_content]).to be_a(PageContent)
        end

        context "コンテンツの新着タイトルが空の場合" do
          let(:page_content) { create(:page_content_editing, page: page, news_title: '') }
          it "新着タイトルがページタイトルに設定されること" do
            subject
            expect(assigns[:page_content].news_title).to eq(page.title)
          end
        end

        context "コンテンツの新着タイトルが空でない場合" do
          let(:page_content) { create(:page_content_editing, page: page, news_title: 'aaaa') }
          it "新着タイトルがページタイトルに設定されること" do
            subject
            expect(assigns[:page_content].news_title).to eq('aaaa')
          end
        end

        context "コンテンツの所属新着が空の場合" do
          let(:page_content) { create(:page_content_editing, page: page, section_news: '') }
          it "新着掲載しないに設定されること" do
            subject
            expect(assigns[:page_content].section_news).to eq( PageContent.section_news_status[:no])
          end
        end

        context "コンテンツの所属新着が空でない場合" do
          let(:page_content) { create(:page_content_editing, page: page, section_news:  PageContent.section_news_status[:yes]) }
          it "新着タイトルがページタイトルに設定されること" do
            subject
            expect(assigns[:page_content].section_news).to eq(PageContent.section_news_status[:yes])
          end
        end
      end
    end

    describe "PATCH update_private_page_status" do
      let(:page) { create(:page, genre: @genre) }
      let(:page_content) { create(:page_content_editing, page: page, email: 'test') }

      describe "正常系" do
        subject {
          patch :update_private_page_status,
          id: page_content.id,
          page_content: page_content_attributes
        }

        shared_examples_for "JOB登録確認" do
          it "Jobが1件追加されていること" do
            expect{subject}.to change(Job, :count).by(1)
          end
        end

        shared_examples_for "公開JOB登録なし" do
          it "Jobが追加されていないこと" do
            expect{subject}.to change(Job, :count).by(0)
          end
        end

        shared_examples_for "リダイレクト先確認" do
          it "ページ詳細画面にリダイレクトすること" do
            expect(subject).to redirect_to(susanoo_page_path(page))
          end
        end

        describe "公開中に変更" do
          let(:page_content_attributes) { {admission: PageContent.page_status[:publish]} }

          it "admissionが公開中に変わること" do
            subject
            expect(page_content.reload.admission).to eq PageContent.page_status[:publish]
          end

          it_behaves_like("JOB登録確認")
          it_behaves_like("リダイレクト先確認")
        end

        describe "公開依頼に変更" do
          let(:page_content_attributes) { {admission: PageContent.page_status[:request]} }
          it "admissionが公開依頼に変わること" do
            subject
            expect(page_content.reload.admission).to eq PageContent.page_status[:request]
          end
          it_behaves_like("公開JOB登録なし")
          it_behaves_like("リダイレクト先確認")
        end


        describe "公開依頼却下に変更" do
          let(:page_content_attributes) { {admission: PageContent.page_status[:reject]} }
          it "admissionが公開却下に変わること" do
            subject
            expect(page_content.reload.admission).to eq PageContent.page_status[:reject]
          end
          it_behaves_like("公開JOB登録なし")
          it_behaves_like("リダイレクト先確認")
        end

        describe "キャンセル" do
          let(:page_content_attributes) { nil }
          subject {
            patch :update_private_page_status,
            id: page_content.id,
            page_content: page_content_attributes,
            cancel: 'true'
          }
          it_behaves_like("リダイレクト先確認")
        end
      end

      describe "異常系" do
        subject { patch :update_private_page_status, id: page_content.id,
          page_content: { admission: nil } }

        it "admissionが編集中のまま変わらないこと" do
          subject
          expect(page_content.reload.admission).to eq PageContent.page_status[:editing]
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
      let(:page) { create(:page, genre: @genre) }
      let(:page_content) { create(:page_content_publish, page: page, email: 'test') }

      describe "正常系" do
        subject {
          patch :update_public_page_status,
          id: page_content.id,
          page_content: page_content_attributes
        }

        shared_examples_for "JOB登録確認" do
          it "Jobが1件追加されていること" do
            expect{subject}.to change(Job, :count).by(1)
          end
        end

        shared_examples_for "公開JOB登録なし" do
          it "Jobが追加されていないこと" do
            expect{subject}.to change(Job, :count).by(0)
          end
        end

        shared_examples_for "リダイレクト先確認" do
          it "ページ詳細画面にリダイレクトすること" do
            expect(subject).to redirect_to(susanoo_page_path(page))
          end
        end

        describe "公開停止に変更" do
          let(:page_content_attributes) { {admission: PageContent.page_status[:cancel]} }

          it "admissionが公開停止に変わること" do
            subject
            expect(page_content.reload.admission).to eq PageContent.page_status[:cancel]
          end
          it_behaves_like("JOB登録確認")
          it_behaves_like("リダイレクト先確認")
        end

        describe "公開却下に変更" do
          let(:page_content_attributes) { {admission: PageContent.page_status[:reject]} }

          it "admissionが公開却下に変わること" do
            subject
            expect(page_content.reload.admission).to eq PageContent.page_status[:reject]
          end
          it_behaves_like("JOB登録確認")
          it_behaves_like("リダイレクト先確認")
        end

        describe "公開に変更" do
          let(:page_content) { create(:page_content_cancel, page: page, email: 'test') }
          let(:page_content_attributes) { {admission: PageContent.page_status[:publish]} }

          it "admissionが公開中に変わること" do
            subject
            expect(page_content.reload.admission).to eq PageContent.page_status[:publish]
          end
          it "Jobが2件追加されていること" do
            expect{subject}.to change(Job, :count).by(2)
          end
          it_behaves_like("リダイレクト先確認")
        end
      end

      describe "異常系" do
        subject { patch :update_public_page_status, id: page_content.id,
          page_content: { admission: nil }  }

        it "admissionが公開中のまま変わらないこと" do
          subject
          expect(page_content.reload.admission).to eq PageContent.page_status[:publish]
        end

        it "Jobが追加されていないこと" do
          expect{subject}.to change(Job, :count).by(0)
        end

        it "edit_public_page_statusをrenderしていること" do
          expect(subject).to render_template(:edit_public_page_status)
        end
      end
    end

    describe "GET destroy_public_term" do
      describe "正常系" do
        let!(:page_content) { create(:page_content_waiting) }
        subject { get :destroy_public_term, id: page_content.id  }

        it "ページ詳細画面にリダイレクトすること" do
          expect(subject).to redirect_to(susanoo_page_path(page_content.page))
        end

        it "flash[:notice]にメッセージが設定されていること" do
          subject
          expect(flash[:notice]).to be
        end

        it "destory_public_term が正しく呼ばれること" do
          expect_any_instance_of(PageContent).to receive(:destroy_public_term)
          subject
        end
      end
    end
  end
end
