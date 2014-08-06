require 'spec_helper'

describe BrowsingSupport::WordsController do
  describe 'アクション' do
    # NOTE: redirect先が Engine でなくなるため
    routes { BrowsingSupport::Engine.routes }

    before do
      login(login_user)
    end
    let(:login_user) { create(:user, password: 'password') }
    let(:action_params) { {} }

    describe 'GET index' do
      subject do
        get :index, action_params
      end

      describe '正常系' do
        before do
          @word_AA = create(:word, base: 'かか', text: 'ああ')
          @word_AI = create(:word, base: 'かき', text: 'あい')
          @word_IA = create(:word, base: 'きか', text: 'いあ')
          @word_II = create(:word, base: 'きき', text: 'いい')
          @word_aa = create(:word, base: 'がが', text: 'ぁぁ')
          @word_ai = create(:word, base: 'がぎ', text: 'ぁぃ')
          @word_ia = create(:word, base: 'ぎが', text: 'ぃぁ')
          @word_ii = create(:word, base: 'ぎぎ', text: 'ぃぃ')
          create_list(:word, 10)
        end

        context 'パラメータ無しの場合' do
          it 'レスポンスは200であること' do
            expect(subject).to be_success
          end

          it 'index が描画されること' do
            expect(subject).to render_template('index')
          end

          it 'インスタンス変数@wordsが設定されていること' do
            subject
            expect(assigns(:words)).to be_a(Array)
            expect(assigns(:words)).to have(10).items
          end

          it 'インスタンス変数@searchが設定されていること' do
            subject
            expect(assigns(:search)).to be_false
          end

          it 'インスタンス変数@aueryが設定されていること' do
            subject
            expect(assigns(:auery)).to eq({})
          end
        end

        context '{query_text: "あ ぁ"} の場合' do
          let(:action_params) { {query_text: 'あ ぁ'} }

          it 'レスポンスは200であること' do
            expect(subject).to be_success
          end

          it 'index が描画されること' do
            expect(subject).to render_template('index')
          end

          it 'インスタンス変数@wordsが設定されていること' do
            subject
            expect(assigns(:words)).to be_a(Array)
            expect(assigns(:words)).to match_array([@word_AA, @word_AI, @word_aa, @word_ai])
          end

          it 'インスタンス変数@searchが設定されていること' do
            subject
            expect(assigns(:search)).to be_true
          end

          it 'インスタンス変数@aueryが設定されていること' do
            subject
            expect(assigns(:auery)).to eq({})
          end
        end

        context '{query_base: "か", search: "search"} の場合' do
          let(:action_params) { {query_base: 'か', search: 'search'} }

          it 'レスポンスは200であること' do
            expect(subject).to be_success
          end

          it 'index が描画されること' do
            expect(subject).to render_template('index')
          end

          it 'インスタンス変数@wordsが設定されていること' do
            subject
            expect(assigns(:words)).to be_a(Array)
            expect(assigns(:words)).to match_array([@word_AA, @word_AI, @word_IA])
          end

          it 'インスタンス変数@searchが設定されていること' do
            subject
            expect(assigns(:search)).to be_true
          end

          it 'インスタンス変数@aueryが設定されていること' do
            subject
            expect(assigns(:auery)).to include({query_base: 'か', search: 'search'})
          end
        end

        context '{query_base: "か", prefix_search: "prefix_search"} の場合' do
          let(:action_params) { {query_base: 'か', prefix_search: 'prefix_search'} }

          it 'レスポンスは200であること' do
            expect(subject).to be_success
          end

          it 'index が描画されること' do
            expect(subject).to render_template('index')
          end

          it 'インスタンス変数@wordsが設定されていること' do
            subject
            expect(assigns(:words)).to be_a(Array)
            expect(assigns(:words)).to match_array([@word_AA, @word_AI])
          end

          it 'インスタンス変数@searchが設定されていること' do
            subject
            expect(assigns(:search)).to be_true
          end

          it 'インスタンス変数@aueryが設定されていること' do
            subject
            expect(assigns(:auery)).to include({query_base: 'か', prefix_search: 'prefix_search'})
          end
        end

        context '{page: 1} の場合' do
          let(:action_params) { {page: 1} }

          it 'レスポンスは200であること' do
            expect(subject).to be_success
          end

          it 'index が描画されること' do
            expect(subject).to render_template('index')
          end

          it 'インスタンス変数@wordsが設定されていること' do
            subject
            expect(assigns(:words)).to be_a(Array)
            expect(assigns(:words)).to have(10).items
          end

          it 'インスタンス変数@searchが設定されていること' do
            subject
            expect(assigns(:search)).to be_false
          end

          it 'インスタンス変数@aueryが設定されていること' do
            subject
            expect(assigns(:auery)).to eq({})
          end
        end

        context '{page: 2} の場合' do
          let(:action_params) { {page: 2} }

          it 'レスポンスは200であること' do
            expect(subject).to be_success
          end

          it 'index が描画されること' do
            expect(subject).to render_template('index')
          end

          it 'インスタンス変数@wordsが設定されていること' do
            subject
            expect(assigns(:words)).to be_a(Array)
            expect(assigns(:words)).to have(8).items
          end

          it 'インスタンス変数@searchが設定されていること' do
            subject
            expect(assigns(:search)).to be_false
          end

          it 'インスタンス変数@aueryが設定されていること' do
            subject
            expect(assigns(:auery)).to eq({})
          end
        end
      end
    end

    describe 'GET new' do
      subject do
        get :new, action_params
      end
      let(:params) { {} }

      describe '正常系' do
        it 'レスポンスは200であること' do
          expect(subject).to be_success
        end

        it 'new が描画されること' do
          expect(subject).to render_template('new')
        end

        it 'インスタンス変数@wordが設定されていること' do
          subject
          expect(assigns(:word)).to be_a_new(Word)
        end
      end
    end

    describe 'POST create' do
      subject do
        post :create, action_params
      end

      describe '正常系' do
        let(:action_params) { {word: word_attrs} }
        let(:word_attrs) { attributes_for(:word) }

        it '一覧画面へリダイレクトされること' do
          expect(subject).to redirect_to(words_path)
        end

        it 'flash[:notice] が設定されていること' do
          subject
          expect(flash[:notice]).to eq(I18n.t('browsing_support.words.create.success'))
        end

        it 'インスタンス変数@wordが設定されていること' do
          subject
          expect(assigns(:word)).to_not be_a_new(Word)
          expect(assigns(:word).attributes).to include(
            { base: word_attrs[:base],
              text: BrowsingSupport::Filter.h2k(word_attrs[:text]),
              user_id: current_user,
            }.stringify_keys
          )
        end
      end

      describe '異常系' do
        # 同じ単語を登録しておき、ユニークのバリデーションを失敗させる
        context 'wordモデルのバリデーションに失敗する場合' do
          let(:action_params) { {word: word_attrs} }
          let(:word_attrs) { attributes_for(:word) }

          before do
            create(:word, base: word_attrs[:base])
          end

          it 'レスポンスは200であること' do
            expect(subject).to be_success
          end

          it 'new が描画されること' do
            expect(subject).to render_template('new')
          end

          it 'インスタンス変数@wordが設定されていること' do
            subject
            expect(assigns(:word)).to be_a_new(Word).with(
              base: word_attrs[:base],
              text: word_attrs[:text],
              user_id: current_user,
            )
          end

        it 'flash[:notice] が設定されていないこと' do
          subject
          expect(flash[:notice]).to be_nil
        end
        end
      end
    end

    describe 'GET edit' do
      subject do
        get :edit, action_params
      end

      describe '正常系' do
        let(:action_params) { {id: word.id} }
        let(:word) { create(:word) }

        it 'レスポンスは200であること' do
          expect(subject).to be_success
        end

        it 'edit が描画されること' do
          expect(subject).to render_template('edit')
        end

        it 'インスタンス変数@wordが設定されていること' do
          subject
          expect(assigns(:word)).to eq(word)
        end
      end
    end

    describe 'PUT update' do
      subject do
        put :update, action_params
      end
      let!(:word) { create(:word, user: create(:user)) }
      let(:action_params) { {id: word.id, word: word_attrs} }
      let(:word_attrs) { attributes_for(:word) }

      describe '正常系' do
        context '同じ所属のユーザが更新を行う場合' do
          let(:login_user) { create(:normal_user, password: 'password', section: word.user.section) }

          it '一覧画面へリダイレクトされること' do
            expect(subject).to redirect_to(words_path)
          end

          it 'flash[:notice] が設定されていること' do
            subject
            expect(flash[:notice]).to eq(I18n.t('browsing_support.words.update.success'))
          end

          it 'インスタンス変数@wordが設定されていること' do
            subject
            expect(assigns(:word)).to eq(word)
            expect(assigns(:word).attributes).to include(
              { base: word_attrs[:base],
                text: BrowsingSupport::Filter.h2k(word_attrs[:text]),
                user_id: current_user,
              }.stringify_keys
            )
          end
        end

        context '所属が異なる運用管理者が更新を行う場合' do
          let(:login_user) { create(:user, password: 'password') }

          it '一覧画面へリダイレクトされること' do
            expect(subject).to redirect_to(words_path)
          end

          it 'flash[:notice] が設定されていること' do
            subject
            expect(flash[:notice]).to eq(I18n.t('browsing_support.words.update.success'))
          end

          it 'インスタンス変数@wordが設定されていること' do
            subject
            expect(assigns(:word)).to eq(word)
            expect(assigns(:word).attributes).to include(
              { base: word_attrs[:base],
                text: BrowsingSupport::Filter.h2k(word_attrs[:text]),
                user_id: current_user,
              }.stringify_keys
            )
          end
        end
      end

      describe '異常系' do
        context 'wordモデルのバリデーションに失敗する場合' do
          let(:login_user) { create(:user, password: 'password', section: word.user.section) }
          let(:word_attrs) { attributes_for(:word, text: '①') }

          it 'レスポンスは200であること' do
            expect(subject).to be_success
          end

          it 'edit が描画されること' do
            expect(subject).to render_template('edit')
          end

          it 'インスタンス変数@wordが設定されていること' do
            subject
            expect(assigns(:word)).to eq(word)
            expect(assigns(:word).attributes).to include(
              { base: word_attrs[:base],
                text: word_attrs[:text],
                user_id: current_user,
              }.stringify_keys
            )
          end

          it 'flash[:notice] が設定されていないこと' do
            subject
            expect(flash[:notice]).to be_nil
          end
        end

        context '所属が異なるユーザが更新を行う場合' do
          let(:login_user) { create(:normal_user, password: 'password') }

          it 'レスポンスは200であること' do
            expect(subject).to redirect_to(words_path)
          end

          it 'インスタンス変数@wordが設定されていること' do
            subject
            expect(assigns(:word)).to eq(word)
            expect(assigns(:word).attributes).to include(
              { base: word.base,
                text: word.text,
                user_id: word.user_id,
              }.stringify_keys
            )
          end

          it 'flash[:notice] が設定されていること' do
            subject
            expect(flash[:notice]).to eq(I18n.t('browsing_support.words.update.not_editable'))
          end
        end
      end
    end

    describe 'DELETE destroy' do
      subject do
        delete :destroy, action_params
      end
      let!(:word) { create(:word, user: create(:normal_user)) }
      let(:action_params) { {id: word.id} }

      describe '正常系' do
        context '同じ所属のユーザが削除を行う場合' do
          let(:login_user) { create(:normal_user, password: 'password', section: word.user.section) }

          it 'レコードが削除されること' do
            expect(word.class.where(id: word.id)).to exist
            expect{ subject }.to change(Word, :count).by(-1)
            expect(word.class.where(id: word.id)).to_not exist
          end

          it '一覧画面へリダイレクトされること' do
            expect(subject).to redirect_to(words_path)
          end

          it 'flash[:notice] が設定されていること' do
            subject
            expect(flash[:notice]).to eq(I18n.t('browsing_support.words.destroy.success'))
          end
        end

        context '所属が異なる運用管理者が削除を行う場合' do
          let(:login_user) { create(:user, password: 'password') }

          it 'レコードが削除されること' do
            expect(word.class.where(id: word.id)).to exist
            expect{ subject }.to change(Word, :count).by(-1)
            expect(word.class.where(id: word.id)).to_not exist
          end

          it '一覧画面へリダイレクトされること' do
            expect(subject).to redirect_to(words_path)
          end

          it 'flash[:notice] が設定されていること' do
            subject
            expect(flash[:notice]).to eq(I18n.t('browsing_support.words.destroy.success'))
          end
        end
      end

      describe '異常系' do
        context '所属が異なるユーザが削除を行う場合' do
          let(:login_user) { create(:normal_user, password: 'password') }

          it 'レコードは削除されないこと' do
            expect(word.class.where(id: word.id)).to exist
            expect{ subject }.to change(Word, :count).by(0)
            expect(word.class.where(id: word.id)).to exist
          end

          it '一覧画面へリダイレクトされること' do
            expect(subject).to redirect_to(words_path)
          end

          it 'flash[:notice] が設定されていること' do
            subject
            expect(flash[:notice]).to eq(I18n.t('browsing_support.words.destroy.not_destroyable'))
          end
        end
      end
    end
  end
end
