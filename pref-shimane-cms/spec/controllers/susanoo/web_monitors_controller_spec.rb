require 'spec_helper'

describe Susanoo::WebMonitorsController do

  let(:valid_attributes) { {  } }
  let(:valid_session) { {} }

  let!(:genre) { create(:genre) }

  describe "フィルタ" do
    controller do
      %w(index new create edit update destroy destroy_all import_csv reflect update_auth).each do |act|
        define_method(act) do
          render text: "ok"
        end
      end
    end

    before do
      @routes.draw do
        resources :anonymous do
          collection do
            delete :destroy_all
            post   :import_csv
            patch  :reflect
            patch  :update_auth
          end
        end
      end
    end

    describe "login_required" do
      let!(:user) { create(:user) }
      let(:web_monitor) { create(:web_monitor, genre: genre) }

      shared_examples_for "未ログイン時のアクセス制限" do |met, act|
        it "#{met.upcase} #{act}にアクセスしたとき、ログイン画面が表示されること" do
          expect(response).to redirect_to(login_susanoo_users_path)
        end
      end

      shared_examples_for "ログイン時のアクセス制限"  do |met, act|
        before { login(user) }
        it "#{met.upcase} #{act}にアクセスしたとき、okが返ること" do
          (response.body == "ok").should be_true
        end
      end

      context "未ログイン状態" do
        it_behaves_like("未ログイン時のアクセス制限", :get, :index) {before{get :index, genre_id: genre.id}}
        it_behaves_like("未ログイン時のアクセス制限", :get, :new) {before{get :new, genre_id: genre.id}}
        it_behaves_like("未ログイン時のアクセス制限", :post, :create) {before{post :create, genre_id: genre.id}}
        it_behaves_like("未ログイン時のアクセス制限", :get, :edit) {before{get :edit, genre_id: genre.id, id: web_monitor.id}}
        it_behaves_like("未ログイン時のアクセス制限", :patch, :update) {before{patch :update, genre_id: genre.id, id: web_monitor.id}}
        it_behaves_like("未ログイン時のアクセス制限", :delete, :destroy) {before{delete :destroy, genre_id: genre.id, id: user.id}}
        it_behaves_like("未ログイン時のアクセス制限", :delete, :destroy_all) {before{delete :destroy_all, genre_id: genre.id}}
        it_behaves_like("未ログイン時のアクセス制限", :post, :import_csv) {before{post :import_csv, genre_id: genre.id}}
        it_behaves_like("未ログイン時のアクセス制限", :patch, :reflect) {before{patch :reflect, genre_id: genre.id}}
        it_behaves_like("未ログイン時のアクセス制限", :patch, :update_auth) {before{patch :update_auth, genre_id: genre.id}}
      end

      context "ログイン状態" do
        it_behaves_like("ログイン時のアクセス制限", :get, :index) {before{get :index, genre_id: genre.id}}
        it_behaves_like("ログイン時のアクセス制限", :get, :new) {before{get :new, genre_id: genre.id}}
        it_behaves_like("ログイン時のアクセス制限", :post, :create) {before{post :create, genre_id: genre.id}}
        it_behaves_like("ログイン時のアクセス制限", :get, :edit) {before{get :edit, genre_id: genre.id, id: web_monitor.id}}
        it_behaves_like("ログイン時のアクセス制限", :patch, :update) {before{patch :update, genre_id: genre.id, id: web_monitor.id}}
        it_behaves_like("ログイン時のアクセス制限", :delete, :destroy) {before{delete :destroy, genre_id: genre.id, id: user.id}}
        it_behaves_like("ログイン時のアクセス制限", :delete, :destroy_all) {before{delete :destroy_all, genre_id: genre.id}}
        it_behaves_like("ログイン時のアクセス制限", :post, :import_csv) {before{post :import_csv, genre_id: genre.id}}
        it_behaves_like("ログイン時のアクセス制限", :patch, :reflect) {before{patch :reflect, genre_id: genre.id}}
        it_behaves_like("ログイン時のアクセス制限", :patch, :update_auth) {before{patch :update_auth, genre_id: genre.id}}
      end
    end
  end

  describe "アクション" do
    before { login(user) }
    let(:user) { create(:user) }
    let!(:genre) { create(:genre) }
    let(:action_params) { {} }
    let(:default_action_params) { {genre_id: genre.id} }

    describe "GET index" do
      subject { get :index, default_action_params.merge(action_params) }

      describe "正常系" do
        before do
          create_list(:web_monitor, 5, genre: genre)
          create_list(:web_monitor, 5)
          create_list(:web_monitor, 10, genre: genre)
        end

        context '通常アクセスの場合' do
          let(:action_params) { {} }

          it 'テンプレートindexがrenderされること' do
            expect(subject).to render_template(:index)
          end

          it '指定したフォルダと紐づいているモニタの1ページ目を取得すること' do
            subject
            expect(assigns[:web_monitors]).to eq WebMonitor.where(genre: genre).page(1)
          end

          it 'ページネーションの単位は10件であること' do
            subject
            expect(assigns[:web_monitors].count).to eq 10
          end
        end

        context 'ページ番号を指定してアクセスする場合' do
          let(:action_params) { {page: 2} }

          it 'テンプレートindexがrenderされること' do
            expect(subject).to render_template(:index)
          end

          it '指定したフォルダと紐づいているモニタの2ページ目を取得すること' do
            subject
            expect(assigns[:web_monitors]).to eq WebMonitor.where(genre: genre).page(2)
          end

          it '5件取得すること' do
            subject
            expect(assigns[:web_monitors].count).to eq 5
          end
        end
      end
    end

    describe "GET new" do
      subject { get :new, default_action_params.merge(action_params) }

      describe "正常系" do
        it 'テンプレートnewがrenderされること' do
          expect(subject).to render_template(:new)
        end

        it 'インスタンス@web_monitorにはフォルダと紐づいたモニタが設定されること' do
          subject
          expect(assigns[:web_monitor]).to be_a(WebMonitor)
          expect(assigns[:web_monitor].attributes).to eq WebMonitor.new(genre: genre).attributes
        end
      end
    end

    describe "POST create" do
      before { Kernel.stub(:rand).with(anything) { 1 } }
      subject { post :create, default_action_params.merge(action_params) }
      let(:web_monitor_attribute) { attributes_for(:web_monitor) }
      let(:action_params) { {web_monitor: web_monitor_attribute} }

      describe "正常系" do
        it '一覧画面にリダイレクトすること' do
          expect(subject).to redirect_to susanoo_genre_web_monitors_path(genre)
        end

        it 'メッセージが設定されること' do
          subject
          expect(flash[:notice]).to eq controller.t('.success')
        end

        it 'WebMonitorレコードが1件増えること' do
          expect{subject}.to change(WebMonitor, :count).by(1)
        end

        it '追加されたレコードには genre_id = genre.id, state = status[:edited] が設定されること' do
          subject
          expect(WebMonitor.last.attributes).to include({
            name: web_monitor_attribute[:name],
            login: web_monitor_attribute[:login],
            password: WebMonitor.htpasswd(web_monitor_attribute[:password]),
            genre_id: genre.id,
            state: WebMonitor.status[:edited]
          }.stringify_keys)
        end
      end

      describe "異常系" do
        context 'バリデーションに失敗する場合' do
          before do
            allow_any_instance_of(WebMonitor).to receive(:valid?).and_return(false)
          end

          it 'テンプレートnewがrenderされること' do
            expect(subject).to render_template(:new)
          end

          it 'WebMonitorレコードは増えないこと' do
            expect{subject}.to change(WebMonitor, :count).by(0)
          end

          it 'インスタンス@web_monitorには登録内容が反映されること' do
            subject
            expect(assigns[:web_monitor]).to be_a(WebMonitor)
            expect(assigns[:web_monitor].attributes).to include({
              name: web_monitor_attribute[:name],
              login: web_monitor_attribute[:login],
              password: web_monitor_attribute[:password],
              genre_id: genre.id,
              state: WebMonitor.status[:edited],
            }.stringify_keys)
          end
        end
      end
    end

    describe "GET edit" do
      let!(:web_monitor) { create(:web_monitor, genre: genre) }

      subject { get :edit, default_action_params.merge(action_params) }
      let(:default_action_params) { {genre_id: genre.id, id: web_monitor.id} }

      describe "正常系" do
        it 'テンプレートeditがrenderされること' do
          expect(subject).to render_template(:edit)
        end

        it 'インスタンス@web_monitorには指定したidのモニタが設定されること' do
          subject
          expect(assigns[:web_monitor]).to eq web_monitor
        end
      end

      describe "異常系" do
        context '指定したモニタがフォルダと紐づいていない場合' do
          let!(:web_monitor) { create(:web_monitor) }

          it 'ActiveRecord::RecordNotFound エラーが発生すること' do
            expect{ subject }.to raise_error(ActiveRecord::RecordNotFound)
          end
        end
      end
    end

    describe "PATCH update" do
      before { Kernel.stub(:rand).with(anything) { 1 } }
      let!(:web_monitor) do
        create(:web_monitor,
               password: 'a'*8, password_confirmation: 'a'*8,
               genre: genre, state: WebMonitor.status[:registered])
      end

      subject { patch :update, default_action_params.merge(action_params) }
      let(:web_monitor_attribute) { attributes_for(:web_monitor) }
      let(:default_action_params) { {genre_id: genre.id, id: web_monitor.id, web_monitor: web_monitor_attribute} }

      describe "正常系" do
        it '一覧画面にリダイレクトすること' do
          expect(subject).to redirect_to susanoo_genre_web_monitors_path(genre)
        end

        it 'メッセージが設定されること' do
          subject
          expect(flash[:notice]).to eq controller.t('.success')
        end

        it 'WebMonitorレコードは増えないこと' do
          expect{subject}.to change(WebMonitor, :count).by(0)
        end

        it 'レコードは更新されること' do
          subject
          expect(web_monitor.reload.attributes).to include({
            name: web_monitor_attribute[:name],
            login: web_monitor_attribute[:login],
            password: WebMonitor.htpasswd(web_monitor_attribute[:password]),
            genre_id: genre.id,
            state: WebMonitor.status[:edited]
          }.stringify_keys)
        end
      end

      describe "異常系" do
        context 'バリデーションに失敗する場合' do
          before do
            allow_any_instance_of(WebMonitor).to receive(:valid?).and_return(false)
          end

          it 'テンプレートeditがrenderされること' do
            expect(subject).to render_template(:edit)
          end

          it 'WebMonitorレコードは増えないこと' do
            expect{subject}.to change(WebMonitor, :count).by(0)
          end

          it 'レコードは更新されないこと' do
            expected = web_monitor.attributes
            subject
            expect(web_monitor.reload.attributes).to include(expected)
          end

          it 'インスタンス@web_monitorには登録内容が反映されること' do
            subject
            expect(assigns[:web_monitor]).to be_a(WebMonitor)
            expect(assigns[:web_monitor].attributes).to include({
              name: web_monitor_attribute[:name],
              login: web_monitor_attribute[:login],
              password: web_monitor_attribute[:password],
              genre_id: genre.id,
              state: WebMonitor.status[:registered],
            }.stringify_keys)
          end
        end

        context '指定したモニタがフォルダと紐づいていない場合' do
          let!(:web_monitor) { create(:web_monitor) }

          it 'ActiveRecord::RecordNotFound エラーが発生すること' do
            expect{ subject }.to raise_error(ActiveRecord::RecordNotFound)
          end
        end
      end
    end

    describe "DELETE destroy" do
      let!(:web_monitor) { create(:web_monitor, genre: genre) }

      subject { delete :destroy, default_action_params.merge(action_params) }
      let(:default_action_params) { {genre_id: genre.id, id: web_monitor.id} }

      describe "正常系" do
        it '一覧画面にリダイレクトすること' do
          expect(subject).to redirect_to susanoo_genre_web_monitors_path(genre)
        end

        it 'メッセージが設定されること' do
          subject
          expect(flash[:notice]).to eq controller.t('.success')
        end

        it 'WebMonitorレコードは減ること' do
          expect{subject}.to change(WebMonitor, :count).by(-1)
        end

        it '指定したレコードが削除されること' do
          subject
          expect(web_monitor.class.exists?(web_monitor.id)).to be_false
        end
      end

      describe "異常系" do
        context 'destroy中にエラーが発生した場合' do
          before do
            allow_any_instance_of(WebMonitor).to receive(:destroy).and_raise(RuntimeError)
          end

          it '一覧画面にリダイレクトすること' do
            expect(subject).to redirect_to susanoo_genre_web_monitors_path(genre)
          end

          it 'メッセージが設定されること' do
            subject
            expect(flash[:notice]).to eq controller.t('.failure', name: web_monitor.name)
          end

          it 'WebMonitorレコードは減らないこと' do
            expect{subject}.to change(WebMonitor, :count).by(0)
          end

          it '指定したレコードが削除されないこと' do
            subject
            expect(web_monitor.class.exists?(web_monitor.id)).to be_true
          end
        end

        context '指定したモニタがフォルダと紐づいていない場合' do
          let!(:web_monitor) { create(:web_monitor) }

          it 'ActiveRecord::RecordNotFound エラーが発生すること' do
            expect{ subject }.to raise_error(ActiveRecord::RecordNotFound)
          end
        end
      end
    end

    describe "DELETE destroy_all" do
      subject { delete :destroy_all, default_action_params.merge(action_params) }
      let(:default_action_params) { {genre_id: genre.id} }

      describe "正常系" do
        let!(:del_web_monitors) { create_list(:web_monitor, 5, genre: genre)}
        let!(:not_del_web_monitors) { create_list(:web_monitor, 3) }

        it '一覧画面にリダイレクトすること' do
          expect(subject).to redirect_to susanoo_genre_web_monitors_path(genre)
        end

        it 'メッセージが設定されること' do
          subject
          expect(flash[:notice]).to eq controller.t('.success')
        end

        it 'WebMonitorレコードは減ること' do
          expect{subject}.to change(WebMonitor, :count).by(-5)
        end

        it '指定したフォルダと紐づくレコードが削除されること' do
          subject
          expect(WebMonitor.where(id: del_web_monitors).count).to eq 0
        end

        it '指定したフォルダと紐づいていないレコードは削除されないこと' do
          subject
          expect(WebMonitor.where(id: not_del_web_monitors).count).to eq not_del_web_monitors.size
        end
      end

      describe "異常系" do
        context 'destroy中にエラーが発生した場合' do
          before do
            allow(WebMonitor).to receive(:destroy_all).and_raise(RuntimeError)
          end

          it '一覧画面にリダイレクトすること' do
            expect(subject).to redirect_to susanoo_genre_web_monitors_path(genre)
          end

          it 'メッセージが設定されること' do
            subject
            expect(flash[:notice]).to eq controller.t('.failure')
          end

          it 'WebMonitorレコードは減らないこと' do
            expect{subject}.to change(WebMonitor, :count).by(0)
          end
        end
      end
    end

    describe "POST import_csv" do
      subject { post :import_csv, default_action_params.merge(action_params) }
      let(:default_action_params) { {genre_id: genre.id} }

      let(:content_type) { 'text/csv' }
      let(:original_filename) { 'test.csv' }
      let(:csv_file) do
        _csv_file = nil
        Dir.mktmpdir do |dir|
          _csv_data = CSV.generate do |csv|
            csv_data.each {|data| csv << data }
          end
          original_file = File.join(dir, original_filename)
          File.write(original_file, NKF.nkf('-Ws', _csv_data))
          _csv_file = fixture_file_upload(original_file, content_type)
        end
        _csv_file
      end
      let(:csv_data) { [] }

      describe "正常系" do
        let(:csv_data) do
          [ %w(Aaron aaron password),
            %w(Quentin quentin 12345678),
            %w(Rails rails RubyonRails),
          ]
        end
        let(:original_filename) { 'test.csv' }
        let(:action_params) { {csv: csv_file} }

        context 'MIME Type が text/csv の場合' do
          let(:content_type) { 'text/csv' }

          it '一覧画面にリダイレクトすること' do
            expect(subject).to redirect_to susanoo_genre_web_monitors_path(genre)
          end

          it 'メッセージが設定されること' do
            subject
            expect(flash[:notice]).to eq controller.t('.success')
          end

          it 'WebMonitorレコードは増えること' do
            expect{subject}.to change{WebMonitor.where(genre: genre).count}.by(3)
          end
        end

        context 'MIME Type が application/octet-stream の場合' do
          let(:content_type) { 'application/octet-stream' }

          it '一覧画面にリダイレクトすること' do
            expect(subject).to redirect_to susanoo_genre_web_monitors_path(genre)
          end

          it 'メッセージが設定されること' do
            subject
            expect(flash[:notice]).to eq controller.t('.success')
          end

          it 'WebMonitorレコードは増えること' do
            expect{subject}.to change{WebMonitor.where(genre: genre).count}.by(3)
          end
        end
      end

      describe "異常系" do
        context 'CSVファイルをアップロードしない場合' do
          let(:action_params) { {} }

          it 'テンプレートnewがrenderされること' do
            expect(subject).to render_template(:new)
          end

          it 'メッセージが設定されないこと' do
            subject
            expect(flash[:notice]).to be_nil
          end

          it 'WebMonitorレコードは増えないこと' do
            expect{subject}.to change(WebMonitor, :count).by(0)
          end

          it 'インスタンス変装@csv_importerにメッセージが設定されること' do
            subject
            csv_importer = assigns[:csv_importer]
            expect(csv_importer).to be_a(WebMonitor)
            expect(csv_importer.errors[:base]).to include(generate_error_message(:base, controller.t('.file_not_found')))
          end
        end

        context 'CSVでないファイルをアップロードした場合' do
          let(:original_filename) { 'text.xls' }
          let(:action_params) { {csv: csv_file} }

          it 'テンプレートnewがrenderされること' do
            expect(subject).to render_template(:new)
          end

          it 'メッセージが設定されないこと' do
            subject
            expect(flash[:notice]).to be_nil
          end

          it 'WebMonitorレコードは増えないこと' do
            expect{subject}.to change(WebMonitor, :count).by(0)
          end

          it 'インスタンス変装@csv_importerにメッセージが設定されること' do
            subject
            csv_importer = assigns[:csv_importer]
            expect(csv_importer).to be_a(WebMonitor)
            expect(csv_importer.errors[:base]).to include(generate_error_message(:base, controller.t('.not_csv_file', name: original_filename)))
          end
        end

        context 'バリデーションに失敗した場合' do
          let(:action_params) { {csv: csv_file} }
          let(:csv_data) do
            [ %w(Aaron aaron password),
              %w(Quentin quentin 1),
              %w(Rails rails a),
            ]
          end

          it 'テンプレートnewがrenderされること' do
            expect(subject).to render_template(:new)
          end

          it 'メッセージが設定されないこと' do
            subject
            expect(flash[:notice]).to be_nil
          end

          it 'WebMonitorレコードは増えないこと' do
            expect{subject}.to change(WebMonitor, :count).by(0)
          end

          it 'インスタンス変装@csv_importerにメッセージが設定されること' do
            subject
            csv_importer = assigns[:csv_importer]
            expect(csv_importer).to be_a(WebMonitor)
            expect(csv_importer.name).to eq 'Quentin'
            expect(csv_importer.errors[:password]).to have_at_least(1).items
          end
        end

        context '例外が発生した場合' do
          let(:action_params) { {csv: csv_file} }
          let(:csv_data) do
            [ %w(Aaron aaron password),
              %w(Quentin quentin 12345678),
              %w(Rails rails RubyonRails),
            ]
          end

          before do
            allow_any_instance_of(WebMonitor).to receive(:after_save).and_raise(ActiveRecord::RecordNotSaved)
          end

          it '一覧画面にリダイレクトすること' do
            expect(subject).to redirect_to susanoo_genre_web_monitors_path(genre)
          end

          it 'メッセージが設定されること' do
            subject
            expect(flash[:notice]).to eq controller.t('.success')
          end
        end
      end
    end

    describe "PATCH reflect" do
      subject { patch :reflect, default_action_params.merge(action_params) }
      let(:default_action_params) { {genre_id: genre.id} }
      let!(:other_genre) { create(:genre) }

      before do
        FactoryGirl.with_options(genre: genre) do |f|
          f.create(:web_monitor, state: WebMonitor.status[:registered])
          f.create_list(:web_monitor, 2, state: WebMonitor.status[:edited])
        end
        FactoryGirl.with_options(genre: other_genre) do |f|
          f.create_list(:web_monitor, 2, state: WebMonitor.status[:edited])
        end
      end

      describe "正常系" do
        it '一覧画面にリダイレクトすること' do
          expect(subject).to redirect_to susanoo_genre_web_monitors_path(genre)
        end

        it 'メッセージが設定されること' do
          subject
          expect(flash[:notice]).to eq controller.t('.success')
        end

        it 'WebMonitorレコードに増減はないこと' do
          expect{subject}.to change(WebMonitor, :count).by(0)
        end

        it 'Jobレコードは増えること' do
          expect do
            expect do
              subject
            end.to change{Job.where(action: 'create_htpasswd', arg1: genre.id.to_s).count}.by(1)
          end.to change{Job.count}.by(1)
        end

        it 'フォルダに紐づくWebMonitorレコードのstate属性は :registered に設定されること' do
          expect do
            expect do
              subject
            end.to change{genre.web_monitors.eq_registered.count}.by(2)
          end.to change{other_genre.web_monitors.eq_registered.count}.by(0)
        end
      end

      describe "異常系" do
        context 'SQL発行に失敗する場合' do
          before do
            allow(WebMonitor.connection).to receive(:update).and_raise(RuntimeError)
          end

          it '一覧画面にリダイレクトすること' do
            expect(subject).to redirect_to susanoo_genre_web_monitors_path(genre)
          end

          it 'メッセージが設定されること' do
            subject
            expect(flash[:notice]).to eq controller.t('.failure')
          end

          it 'WebMonitorレコードに増減はないこと' do
            expect{subject}.to change(WebMonitor, :count).by(0)
          end

          it 'Jobレコードは増えないこと' do
            expect do
              subject
            end.to change{Job.count}.by(0)
          end

          it 'フォルダに紐づくWebMonitorレコードのstate属性は :registered に設定されないこと' do
            expect do
              expect do
                subject
              end.to change{genre.web_monitors.eq_registered.count}.by(0)
            end.to change{other_genre.web_monitors.eq_registered.count}.by(0)
          end
        end
      end
    end

    describe "PATCH update_auth" do
      subject { patch :update_auth, default_action_params.merge(action_params) }
      let(:default_action_params) { {genre_id: genre.id} }

      describe "正常系" do
        let!(:other_genre) { create(:genre) }

        before do
          FactoryGirl.with_options(genre: genre) do |f|
            f.create_list(:web_monitor, 1, state: WebMonitor.status[:registered])
            f.create_list(:web_monitor, 2, state: WebMonitor.status[:edited])
          end
          FactoryGirl.with_options(genre: other_genre) do |f|
            f.create_list(:web_monitor, 2, state: WebMonitor.status[:edited])
          end
        end

        context '無効から有効に変更する場合' do
          let(:action_params) { {genre: {auth: 'true'}} }

          before do
            genre.update_attribute(:auth, false)
          end

          it '一覧画面にリダイレクトすること' do
            expect(subject).to redirect_to susanoo_genre_web_monitors_path(genre)
          end

          it 'メッセージが設定されること' do
            subject
            expect(flash[:notice]).to eq controller.t('.success', auth: controller.t('.label.auth.true'))
          end

          it 'Genre#authは更新されること' do
            expect{ subject }.to change{ genre.reload.auth }.from(false).to(true)
          end

          it 'create_htaccessジョブが登録されること' do
            expect do
              expect do
                subject
              end.to change{ Job.where(action: Job::CREATE_HTACCESS, arg1: genre.id.to_s).count }.by(1)
            end.to change{ Job.where(action: Job::DESTROY_HTACCESS, arg1: genre.id.to_s).count }.by(0)
          end

          it 'Genreに紐づくWebMonitorレコードのstate属性がregisteredに設定されること' do
            expect do
              expect do
                subject
              end.to change{ genre.web_monitors.eq_registered.count }.by(2)
            end.to change{ other_genre.web_monitors.eq_registered.count }.by(0)
          end
        end

        context '有効から無効に変更する場合' do
          let(:action_params) { {genre: {auth: 'false'}} }

          before do
            genre.update_attribute(:auth, true)
          end

          it '一覧画面にリダイレクトすること' do
            expect(subject).to redirect_to susanoo_genre_web_monitors_path(genre)
          end

          it 'メッセージが設定されること' do
            subject
            expect(flash[:notice]).to eq controller.t('.success', auth: controller.t('.label.auth.false'))
          end

          it 'Genre#authは更新されること' do
            expect{ subject }.to change{ genre.reload.auth }.from(true).to(false)
          end

          it 'destroy_htaccessジョブが登録されること' do
            expect do
              expect do
                subject
              end.to change{ Job.where(action: Job::CREATE_HTACCESS, arg1: genre.id.to_s).count }.by(0)
            end.to change{ Job.where(action: Job::DESTROY_HTACCESS, arg1: genre.id.to_s).count }.by(1)
          end

          it 'Genreに紐づくWebMonitorレコードのstate属性がregisteredに設定されること' do
            expect do
              expect do
                subject
              end.to change{ genre.web_monitors.eq_registered.count }.by(2)
            end.to change{ other_genre.web_monitors.eq_registered.count }.by(0)
          end
        end

        context '有効から有効に変更する場合' do
          let(:action_params) { {genre: {auth: 'true'}} }

          before do
            genre.update_attribute(:auth, true)
          end

          it '一覧画面にリダイレクトすること' do
            expect(subject).to redirect_to susanoo_genre_web_monitors_path(genre)
          end

          it 'メッセージが設定されること' do
            subject
            expect(flash[:notice]).to eq controller.t('.success', auth: controller.t('.label.auth.true'))
          end

          it 'Genre#authは更新されないこと' do
            expect{ subject }.to_not change{ genre.reload.auth }
          end

          it 'create_htaccessジョブが登録されること' do
            expect do
              expect do
                subject
              end.to change{ Job.where(action: Job::CREATE_HTACCESS, arg1: genre.id.to_s).count }.by(1)
            end.to change{ Job.where(action: Job::DESTROY_HTACCESS, arg1: genre.id.to_s).count }.by(0)
          end

          it 'Genreに紐づくWebMonitorレコードのstate属性がregisteredに設定されること' do
            expect do
              expect do
                subject
              end.to change{ genre.web_monitors.eq_registered.count }.by(2)
            end.to change{ other_genre.web_monitors.eq_registered.count }.by(0)
          end
        end

        context '無効から無効に変更する場合' do
          let(:action_params) { {genre: {auth: 'false'}} }

          before do
            genre.update_attribute(:auth, false)
          end

          it '一覧画面にリダイレクトすること' do
            expect(subject).to redirect_to susanoo_genre_web_monitors_path(genre)
          end

          it 'メッセージが設定されること' do
            subject
            expect(flash[:notice]).to eq controller.t('.success', auth: controller.t('.label.auth.false'))
          end

          it 'Genre#authは更新されないこと' do
            expect{ subject }.to_not change{ genre.reload.auth }
          end

          it 'create_htaccessジョブ、destroy_htaccessジョブは登録されないこと' do
            expect do
              expect do
                subject
              end.to change{ Job.where(action: Job::CREATE_HTACCESS, arg1: genre.id.to_s).count }.by(0)
            end.to change{ Job.where(action: Job::DESTROY_HTACCESS, arg1: genre.id.to_s).count }.by(0)
          end

          it 'Genreに紐づくWebMonitorレコードのstate属性がregisteredに設定されないこと' do
            expect do
              expect do
                subject
              end.to change{ genre.web_monitors.eq_registered.count }.by(0)
            end.to change{ other_genre.web_monitors.eq_registered.count }.by(0)
          end
        end
      end

      describe "異常系" do
        let(:action_params) { {genre: {auth: 'true'}} }
        let!(:other_genre) { create(:genre) }

        before do
          FactoryGirl.with_options(genre: genre) do |f|
            f.create_list(:web_monitor, 1, state: WebMonitor.status[:registered])
            f.create_list(:web_monitor, 2, state: WebMonitor.status[:edited])
          end
          FactoryGirl.with_options(genre: other_genre) do |f|
            f.create_list(:web_monitor, 2, state: WebMonitor.status[:edited])
          end

          genre.update_column(:auth, false)

          allow_any_instance_of(Genre).to receive(:create_or_update).and_return(false)
        end

        it '一覧画面にリダイレクトすること' do
          expect(subject).to redirect_to susanoo_genre_web_monitors_path(genre)
        end

        it 'メッセージが設定されること' do
          subject
          expect(flash[:notice]).to eq controller.t('.failure')
        end

        it 'Genre#authは更新されないこと' do
          expect{ subject }.to_not change{ genre.reload.auth }
        end

        it 'create_htaccessジョブ、destroy_htaccessジョブは登録されないこと' do
          expect do
            expect do
              subject
            end.to change{ Job.where(action: Job::CREATE_HTACCESS, arg1: genre.id.to_s).count }.by(0)
          end.to change{ Job.where(action: Job::DESTROY_HTACCESS, arg1: genre.id.to_s).count }.by(0)
        end

        it 'Genreに紐づくWebMonitorレコードのstate属性はregisteredに設定されないこと' do
          expect do
            expect do
              subject
            end.to change{ genre.web_monitors.eq_registered.count }.by(0)
          end.to change{ other_genre.web_monitors.eq_registered.count }.by(0)
        end
      end
    end
  end

  def generate_error_message(attr, msg, options = {})
    ActiveModel::Errors.new(WebMonitor.new).send(:normalize_message, attr, msg, options)
  end
end
