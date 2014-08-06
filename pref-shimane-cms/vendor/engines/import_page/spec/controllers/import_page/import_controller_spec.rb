require 'spec_helper'

describe ImportPage::ImportController do
  describe "フィルタ" do
    controller do
      %w(show create destroy).each do |act|
        define_method(act) do
          render text: "ok"
        end
      end
    end

    before do
      @routes.draw do
        resource :anonymous do
        end
      end
    end

    describe "lonin_required" do
      before do
        controller.stub(:enable_engine_required).and_return(true)
      end

      shared_examples_for "未ログイン時のアクセス制限" do |met, act|
        it "#{met.upcase} #{act}にアクセスしたとき、ログイン画面が表示されること" do
          expect(response).to redirect_to(login_susanoo_users_path)
        end
      end

      shared_examples_for "ログイン時のアクセス制限"  do |met, act|
        before{@user = login(create(:user))}
        it "#{met.upcase} #{act}にアクセスしたとき、okが返ること" do
          (response.body == "ok").should be_true
        end
      end

      context "未ログイン状態" do
        it_behaves_like("未ログイン時のアクセス制限", :get, :show)       {before{get :show}}
        it_behaves_like("未ログイン時のアクセス制限", :post, :create)    {before{post :create}}
        it_behaves_like("未ログイン時のアクセス制限", :delete, :destroy) {before{delete :destroy}}
      end

      context "ログイン状態" do
        it_behaves_like("ログイン時のアクセス制限", :get, :show)       {before{get :show}}
        it_behaves_like("ログイン時のアクセス制限", :post, :create)    {before{post :create}}
        it_behaves_like("ログイン時のアクセス制限", :delete, :destroy) {before{delete :destroy}}
      end
    end


    describe "enable_engine_required" do
      before do
        controller.stub(:login_required).and_return(true)
      end

      shared_examples_for "エンジンが有効な場合のアクセス制限" do |met, act|
        before{EngineMaster.stub(:enable?).and_return(true)}
        it "#{met.upcase} #{act}にアクセスしたとき、okが返ること" do
          expect(response.body).to eq("ok")
        end
      end

      shared_examples_for "エンジンが無効な場合のアクセス制限"  do |met, act|
        before{EngineMaster.stub(:enable?).and_return(false)}
        it "#{met.upcase} #{act}にアクセスしたとき、トップページへリダイレクトすること" do
          expect(response).to redirect_to(susanoo_dashboards_path)
        end

        it "#{met.upcase} #{act}にアクセスしたとき、flash[:alert]にメッセージが設定されること" do
          expect(flash[:alert]).to eq(I18n.t("shared.engines.disable"))
        end
      end

      context "エンジンが有効な場合" do
        it_behaves_like("エンジンが有効な場合のアクセス制限", :get, :show)       {before{get :show, use_route: :import_page}}
        it_behaves_like("エンジンが有効な場合のアクセス制限", :post, :create)    {before{post :create, use_route: :import_page}}
        it_behaves_like("エンジンが有効な場合のアクセス制限", :delete, :destroy) {before{delete :destroy, use_route: :import_page}}
      end

      context "エンジンが無効な場合" do
        it_behaves_like("エンジンが無効な場合のアクセス制限", :get, :show)       {before{get :show, use_route: :import_page}}
        it_behaves_like("エンジンが無効な場合のアクセス制限", :post, :create)    {before{post :create, use_route: :import_page}}
        it_behaves_like("エンジンが無効な場合のアクセス制限", :delete, :destroy) {before{delete :destroy, use_route: :import_page}}
      end
    end
  end

  describe 'アクション' do
    # NOTE: redirect先が Engine でなくなるため
    routes { ImportPage::Engine.routes }

    before do
      controller.stub(:enable_engine_required).and_return(true)
      login(login_user)
      FileUtils.rm_rf(store_dir)
    end
    let(:login_user) { create(:user, password: 'password') }
    let(:action_params) { {} }
    let(:store_dir) { ImportPage::UploadFile.store_path(login_user.section_id) }

    describe 'GET show' do
      subject do
        get :show, action_params
      end

      describe '正常系' do
        let!(:genre) { create(:genre) }

        context '未アップロードの場合' do
          it 'レスポンスは200であること' do
            expect(subject).to be_success
          end

          it 'import が描画されること' do
            expect(subject).to render_template('show')
          end

          it 'インスタンス変数@upload_fileが設定されていること' do
            subject
            upload_file = assigns(:upload_file)
            expect(upload_file).to be_instance_of(ImportPage::UploadFile)
            expect(upload_file.section_id).to be_nil
            expect(upload_file.user_id).to be_nil
            expect(upload_file.genre_id).to be_nil
            expect(upload_file.file).to be_nil
            expect(upload_file.filename).to be_nil
          end
        end

        context 'アップロード済みの場合' do
        let(:zip_file) do
          Rack::Test::UploadedFile.new(
            ImportPage::Engine.root.join('spec/files/include_html_files.zip'),
            'application/zip')
        end
          before do
            upload_file = ImportPage::UploadFile.new
            upload_file.section_id = login_user.section_id
            upload_file.user_id = login_user.id
            upload_file.genre_id = genre.id
            upload_file.file = zip_file
            upload_file.filename = zip_file.original_filename
            upload_file.store
          end

          it 'レスポンスは200であること' do
            expect(subject).to be_success
          end

          it 'import が描画されること' do
            expect(subject).to render_template('show')
          end

          it 'インスタンス変数@upload_fileが設定されていること' do
            subject
            upload_file = assigns(:upload_file)
            expect(upload_file).to be_instance_of(ImportPage::UploadFile)
            expect(upload_file.section_id).to eq login_user.section_id
            expect(upload_file.user_id).to eq login_user.id
            expect(upload_file.genre_id).to eq genre.id
            #expect(upload_file.file).to be_nil
            expect(upload_file.filename).to eq zip_file.original_filename
          end
        end

        context 'インポート済みの場合' do
          before do
            FileUtils.mkdir_p(store_dir)
            FileUtils.touch(store_dir.join('errors'))
            File.write(store_dir.join('genre_id'), genre.id)
            File.write(store_dir.join('user_id'), login_user.id)
          end

          it 'レスポンスは200であること' do
            expect(subject).to be_success
          end

          it 'import が描画されること' do
            expect(subject).to render_template('show')
          end

          it 'インスタンス変数@upload_fileが設定されていること' do
            subject
            upload_file = assigns(:upload_file)
            expect(upload_file).to be_instance_of(ImportPage::UploadFile)
            expect(upload_file.section_id).to eq login_user.section_id
            expect(upload_file.user_id).to eq login_user.id
            expect(upload_file.genre_id).to eq genre.id
            expect(upload_file.file).to be_nil
            expect(upload_file.filename).to be_nil
          end
        end
      end
    end

    describe 'POST create' do
      subject do
        post :create, action_params
      end
      let!(:genre) { create(:genre) }
      let(:zip_file) do
        Rack::Test::UploadedFile.new(
          ImportPage::Engine.root.join('spec/files/include_html_files.zip'),
          'application/zip')
      end

      describe '正常系' do
        let(:action_params) do
          { upload_file: {
              genre_id: genre.id, file: zip_file},
          }
        end

        it 'インポート画面へリダイレクトされること' do
          expect(subject).to redirect_to(import_path)
        end

        it 'インスタンス変数@upload_fileが設定されていること' do
          subject
          upload_file = assigns(:upload_file)
          expect(upload_file).to be_instance_of(ImportPage::UploadFile)
          expect(upload_file.section_id).to eq login_user.section_id
          expect(upload_file.user_id).to eq login_user.id
          expect(upload_file.genre_id).to eq genre.id
          expect(upload_file.file).to eq zip_file
          expect(upload_file.filename).to eq zip_file.original_filename
        end

        it '<store_dir>/ ディレクトリが存在していること' do
          subject
          expect(store_dir.exist?).to be_true
        end

        it '<store_dir>/user_id ファイルにログインユーザのidが保存されていること' do
          subject
          user_id_file = store_dir.join('user_id')
          expect(user_id_file.exist?).to be_true
          expect(user_id_file.read).to eq "#{login_user.id}"
        end

        it '<store_dir>/genre_id ファイルにフォルダのidが保存されていること' do
          subject
          genre_id_file = store_dir.join('genre_id')
          expect(genre_id_file.exist?).to be_true
          expect(genre_id_file.read).to eq "#{genre.id}"
        end

        it '<store_dir>/*.zip ファイルが保存されていること' do
          subject
          file = store_dir.join(zip_file.original_filename)
          expect(file.exist?).to be_true
        end
      end

      describe '異常系' do
        context 'フォルダに通常フォルダでないフォルダを指定した場合' do
          before do
            allow_any_instance_of(Genre).to receive(:normal?).and_return(false)
          end

          let(:action_params) do
            { upload_file: {
                genre_id: genre.id, file: zip_file},
            }
          end

          it 'レスポンスは200であること' do
            expect(subject).to be_success
          end

          it 'import が描画されること' do
            expect(subject).to render_template('show')
          end

          it 'インスタンス変数@upload_fileが設定されていること' do
            subject
            upload_file = assigns(:upload_file)
            expect(upload_file).to be_instance_of(ImportPage::UploadFile)
            expect(upload_file.section_id).to eq login_user.section_id
            expect(upload_file.user_id).to eq login_user.id
            expect(upload_file.genre_id).to eq genre.id
            expect(upload_file.file).to eq zip_file
            expect(upload_file.filename).to eq zip_file.original_filename
          end
        end

        context '検証に失敗した場合' do
          let(:action_params) { { upload_file: {} } }

          it 'レスポンスは200であること' do
            expect(subject).to be_success
          end

          it 'import が描画されること' do
            expect(subject).to render_template('show')
          end

          it 'インスタンス変数@upload_fileが設定されていること' do
            subject
            upload_file = assigns(:upload_file)
            expect(upload_file).to be_instance_of(ImportPage::UploadFile)
            expect(upload_file.section_id).to eq login_user.section_id
            expect(upload_file.user_id).to eq login_user.id
            expect(upload_file.genre_id).to be_nil
            expect(upload_file.file).to be_nil
            expect(upload_file.filename).to be_nil
          end
        end
      end
    end

    describe 'DELETE destroy' do
      subject do
        delete :destroy, action_params
      end

      describe '正常系' do
        context '<store_dir> ディレクトリが存在している場合' do
          before do
            FileUtils.mkdir_p(store_dir)
          end

          it 'インポート画面へリダイレクトされること' do
            expect(subject).to redirect_to(import_path)
          end

          it '<store_dir> ディレクトリは削除されること' do
            subject
            expect(store_dir.exist?).to be_false
          end
        end

        context '<store_dir> ディレクトリが存在しない場合' do
          before do
            FileUtils.rm_rf(store_dir)
          end

          it 'インポート画面へリダイレクトされること' do
            expect(subject).to redirect_to(import_path)
          end
        end
      end
    end
  end
end
