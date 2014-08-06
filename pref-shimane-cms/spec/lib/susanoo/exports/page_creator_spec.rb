require 'spec_helper'

describe Susanoo::Exports::PageCreator do
  before do
    Page.any_instance.stub(:begin_event_date)
  end

  describe "メソッド" do
    before do
      allow_any_instance_of(Susanoo::Exports::Creator::Base).to receive(:rsync)
    end

    describe "#initialize" do
      context "ディレクトリのルートが引数で渡された場合" do
        let(:path) { '/test/' }

        before do
          @page_creator = Susanoo::Exports::PageCreator.new(path)
        end

        it "@pathのファイル名にindex.htmlを設定すること" do
          expect(@page_creator.instance_eval{ @path }.to_s).to eq("#{path}index.html")
        end
      end

      context "引数にファイルパスが指定された場合" do
        let(:path) { '/test/test1.html' }

        before do
          @page_creator = Susanoo::Exports::PageCreator.new(path)
        end

        it "@pathを正しく設定してること" do
          expect(@page_creator.instance_eval{ @path }.to_s).to eq(path)
        end
      end
    end

    describe "#make" do
      let(:top_genre) { create(:top_genre) }
      let(:page) { create(:page_publish_without_private, genre_id: top_genre.id) }

      before do
        @page_creator = Susanoo::Exports::PageCreator.new(page.path)
        @path = @page_creator.instance_eval{ @path }
      end

      context "コンテンツ作成に成功した場合" do
        before do
          allow_any_instance_of(Susanoo::Exports::PageCreator).to receive(:create_normal_page).and_return(true)
        end

        it "#create_mobile_page を呼び出していること" do
          expect(@page_creator).to receive(:create_mobile_page)

          @page_creator.make
        end

        it "#sync_docrootを正しく呼び出していること" do
          page_path = Pathname(page.path)
          src = "#{File.join(page_path.dirname, page_path.basename('.*'))}.*"
          expect(@page_creator).to receive(:sync_docroot).with(src)

          @page_creator.make
        end

        it "trueを返すこと" do
          expect(@page_creator.make).to be_true
        end
      end

      context "コンテンツ作成に失敗した場合" do
        before do
          allow_any_instance_of(Susanoo::Exports::PageCreator).to receive(:create_normal_page).and_return(false)
        end

        it "#create_mobile_page を呼び出さないこと" do
          expect(@page_creator).to_not receive(:create_mobile_page)

          @page_creator.make
        end

        it "#sync_docroot は呼び出されないこと" do
          expect(@page_creator).to_not receive(:sync_docroot)

          @page_creator.make
        end

        it "falseをかえすこと" do
          expect(@page_creator.make).to be_false
        end
      end
    end

    describe "#move" do
      let(:top_genre) { create(:top_genre) }
      let(:page) { create(:page, genre_id: top_genre.id) }

      let(:to_genre) { create(:genre, parent_id: top_genre.id) }

      before do
        @page_creator = Susanoo::Exports::PageCreator.new(page.path)
      end

      it "#mv_fileメソッドを呼び出していること" do
        file_path = "#{Settings.export.docroot}/#{page.name}"
        File.open("#{file_path}.html", 'w') {|f| f.print('test')}

        expect(@page_creator).to receive(:mv_file).with(Dir.glob("#{file_path}.*"), to_genre.path)
        @page_creator.move(to_genre.path)
      end

      it "#add_remove_file_listメソッドを呼び出していること" do
        @path = @page_creator.instance_eval{ @path }

        expect(@page_creator).to receive(:add_remove_file_list).with(@path)
        @page_creator.move(to_genre.path)
      end

      it "#sync_docroot メソッドを正しく呼び出していること" do
        page_path = Pathname(page.path)
        src = "#{File.join(page_path.dirname, page_path.basename('.*'))}.*"
        expect(@page_creator).to receive(:sync_docroot).ordered.with(src)

        dest = "#{File.join(to_genre.path, page_path.basename('.*'))}.*"
        expect(@page_creator).to receive(:sync_docroot).ordered.with(dest)

        @page_creator.move(to_genre.path)
      end
    end

    describe "#cancel" do
      let(:top_genre) { create(:top_genre) }
      let(:page) { create(:page, genre_id: top_genre.id) }

      before do
        @page_creator = Susanoo::Exports::PageCreator.new(page.path)
        @path = @page_creator.instance_eval{ @path }
      end

      it "#deleteを呼び出していること" do
        expect(@page_creator).to receive(:delete)
        @page_creator.cancel
      end

      it "#add_remove_file_listを呼び出していること" do
        expect(@page_creator).to receive(:add_remove_file_list).with(@path)
        @page_creator.cancel
      end
    end

    describe "#delete" do
      let(:top_genre) { create(:top_genre) }
      let(:page) { create(:page, genre_id: top_genre.id) }

      before do
        @page_creator = Susanoo::Exports::PageCreator.new(page.path)
        @path = @page_creator.instance_eval{ @path }
      end

      it "remove_rfメソッドを正しく呼んでいること" do
        file_path = "#{Settings.export.docroot}/#{page.name}"
        File.open("#{file_path}.html", 'w') {|f| f.print('test')}
        expect(@page_creator).to receive(:remove_rf).with(Dir.glob("#{file_path}.*"))
        @page_creator.delete
      end

      it "#sync_docrootメソッドを正しく呼んでいること" do
        page_path = Pathname(page.path)
        src = "#{File.join(page_path.dirname, page_path.basename('.*'))}.*"
        expect(@page_creator).to receive(:sync_docroot).with(src)

        @page_creator.delete
      end
    end

    describe "#delete_dir" do
      let(:top_genre) { create(:top_genre) }
      let(:page) { create(:page, genre_id: top_genre.id) }

      before do
        @page_creator = Susanoo::Exports::PageCreator.new(page.path)
        @path = @page_creator.instance_eval{ @path }
      end

      it "#remove_rfメソッドを正しく呼び出していること" do
        allow(@page_creator).to receive(:remove_rf)
        expect(@page_creator).to receive(:remove_rf).with([@path.dirname])

        @page_creator.delete_dir
      end

      it "#add_remove_file_listメソッドを正しく呼び出していること" do
        allow(@page_creator).to receive(:add_remove_file_list)

        expect(@page_creator).to receive(:add_remove_file_list).with(@path.dirname)
        @page_creator.delete_dir
      end

      it "SectionNews.destroy_all_by_pathを呼び出していること" do
        allow(SectionNews).to receive(:destroy_all_by_path)

        expect(SectionNews).to receive(:destroy_all_by_path).with(@path.dirname.to_s)
        @page_creator.delete_dir
      end

      it "#sync_docrootメソッドを正しく呼んでいること" do
        page_path = Pathname(page.path)
        src = "#{File.join(page_path.dirname, '/')}"
        expect(@page_creator).to receive(:sync_docroot).with(src)

        @page_creator.delete_dir
      end
    end

    describe "#move_dir" do
      let(:top_genre) { create(:top_genre) }
      let(:from_genre) { create(:genre, parent_id: top_genre.id) }
      let(:to_genre)   { create(:genre, parent_id: top_genre.id) }

      before do
        @page_creator = Susanoo::Exports::PageCreator.new(from_genre.path)
        @path = @page_creator.instance_eval{ @path }
      end

      it "#remove_rfメソッドを正しく呼び出していること" do
        path = Pathname(from_genre.path).cleanpath
        expect(@page_creator).to receive(:remove_rf).with([path])
        @page_creator.move_dir(to_genre.path)
      end

      it "#add_remove_file_listメソッドを正しく呼び出していること" do
        path = Pathname(from_genre.path).cleanpath
        expect(@page_creator).to receive(:add_remove_file_list).with(path)
        @page_creator.move_dir(to_genre.path)
      end

      it "SectionNews.destroy_all_by_path は呼び出されないこと" do
        expect(SectionNews).to_not receive(:destroy_all_by_path)
        @page_creator.move_dir(to_genre.path)
      end

      it "#sync_docroot は呼び出されないこと" do
        expect(@page_creator).to_not receive(:sync_docroot)
        @page_creator.move_dir(to_genre.path)
      end
    end
  end

  describe "プライベート" do
    describe "#create_normal_page" do
      let(:top_genre) { create(:top_genre) }

      before do
        @app = ActionDispatch::Integration::Session.new(PrefShimaneCms::Application)
      end

      context '通常ページを処理する場合' do
        let(:page) { create(:page_publish, genre_id: top_genre.id) }

        before do
          @page_creator = Susanoo::Exports::PageCreator.new(page.path)
          @path = @page_creator.instance_eval{ @path }
        end

        context "HTMLのファイルへの書き込みに成功した場合" do
          it "正しいHTMLを書き込んでいること" do
            @app.get(page.path)
            expect(@page_creator).to receive(:write_file).with(@path, @app.body)

            @page_creator.send(:create_normal_page)
          end

          it "#create_or_remove_counterが正しく呼ばれていること" do
            @app.get(page.path)

            allow_any_instance_of(Susanoo::Exports::PageCreator).to receive(:write_file).and_return(@app.body)
            expect(@page_creator).to receive(:create_or_remove_counter).with(@app.body, @path)
            @page_creator.send(:create_normal_page)
          end

          it "#rss_createが正しく呼ばれていること" do
            allow_any_instance_of(Susanoo::Exports::PageCreator).to receive(:write_file).and_return("")
            expect(@page_creator).to receive(:rss_create)
            @page_creator.send(:create_normal_page)
          end

          it "#qr_createが正しく呼ばれていること" do
            allow_any_instance_of(Susanoo::Exports::PageCreator).to receive(:write_file).and_return("")
            expect(@page_creator).to receive(:qr_create)
            @page_creator.send(:create_normal_page)
          end
        end

        context "HTMLのファイルへの書き込みに失敗した場合" do
          before do
            allow_any_instance_of(Susanoo::Exports::PageCreator).to receive(:write_file).and_return(false)
          end

          it "falseをかえすこと" do
            expect(@page_creator.send(:create_normal_page)).to be_false
          end
        end
      end

      context 'ジャンルから自動作成されるindex.html を処理する場合' do
        let(:genre) { create(:genre, parent_id: top_genre.id) }

        before do
          @page_creator = Susanoo::Exports::PageCreator.new(genre.path)
          @path = @page_creator.instance_eval{ @path }
        end

        context "HTMLのファイルへの書き込みに成功した場合" do
          it "正しいHTMLを書き込んでいること" do
            @app.get(genre.path)
            expect(@page_creator).to receive(:write_file).with(@path, @app.body)

            @page_creator.send(:create_normal_page)
          end

          it "#create_or_remove_counterが正しく呼ばれていること" do
            @app.get(genre.path)

            allow_any_instance_of(Susanoo::Exports::PageCreator).to receive(:write_file).and_return(@app.body)
            expect(@page_creator).to receive(:create_or_remove_counter).with(@app.body, @path)
            @page_creator.send(:create_normal_page)
          end

          it "#rss_createは呼ばれこと" do
            allow_any_instance_of(Susanoo::Exports::PageCreator).to receive(:write_file).and_return("")
            expect(@page_creator).to_not receive(:rss_create)
            @page_creator.send(:create_normal_page)
          end

          it "#qr_createが正しく呼ばれていること" do
            allow_any_instance_of(Susanoo::Exports::PageCreator).to receive(:write_file).and_return("")
            expect(@page_creator).to receive(:qr_create)
            @page_creator.send(:create_normal_page)
          end
        end

        context "HTMLのファイルへの書き込みに失敗した場合" do
          before do
            allow_any_instance_of(Susanoo::Exports::PageCreator).to receive(:write_file).and_return(false)
          end

          it "falseをかえすこと" do
            expect(@page_creator.send(:create_normal_page)).to be_false
          end
        end
      end

      context 'HTTPステータスが200以外の場合' do
        let!(:page) { create(:page_publish, genre_id: top_genre.id) }
        let!(:page_creator) { Susanoo::Exports::PageCreator.new(page.path) }
        let(:path) { page_creator.instance_eval{ @path } }
        let(:app) { page_creator.instance_eval{ @app } }

        before do
          allow_any_instance_of(Susanoo::VisitorsController).to receive(:view).and_raise(RuntimeError)
        end

        around do |example|
          orig = PrefShimaneCms::Application.env_config["action_dispatch.show_exceptions"]
          begin
            PrefShimaneCms::Application.env_config["action_dispatch.show_exceptions"] = true
            example.call
          ensure
            PrefShimaneCms::Application.env_config["action_dispatch.show_exceptions"] = orig
          end
        end

        it "false を返すこと" do
          expect(page_creator.send(:create_normal_page)).to be_false
        end

        it "HTMLのファイルへの書き込みは行わないこと" do
          expect(page_creator).to_not receive(:write_file)

          page_creator.send(:create_normal_page)
        end
      end
    end

    describe "#create_mobile_page" do
      let(:top_genre) { create(:top_genre) }

      before do
        @app = ActionDispatch::Integration::Session.new(PrefShimaneCms::Application)
      end

      context '通常ページを処理する場合' do
        let!(:page) { create(:page_publish, genre_id: top_genre.id) }

        before do
          @page_creator = Susanoo::Exports::PageCreator.new(page.path)
          @path = @page_creator.instance_eval{ @path }
        end

        it "モバイルページをファイルに書き込んでいること" do
          path = Pathname("#{@path}.i")
          @app.get(path.to_s)
          expect(@page_creator).to receive(:write_file).with(path, NKF.nkf('-Ws --oc=cp932', @app.body), "w", {encoding: "cp932"})

          @page_creator.send(:create_mobile_page)
        end
      end

      context 'ジャンルから自動作成されるindex.html を処理する場合' do
        let(:genre) { create(:genre, parent_id: top_genre.id) }

        before do
          @page_creator = Susanoo::Exports::PageCreator.new(genre.path)
          @path = @page_creator.instance_eval{ @path }
        end

        it "モバイルページをファイルに書き込んでいること" do
          path = Pathname("#{@path}.i")
          @app.get(path.to_s)
          expect(@page_creator).to receive(:write_file).with(path, NKF.nkf('-Ws --oc=cp932', @app.body), "w", {encoding: "cp932"})

          @page_creator.send(:create_mobile_page)
        end
      end

      context 'HTTPステータスが200以外の場合' do
        let!(:page) { create(:page_publish, genre_id: top_genre.id) }
        let!(:page_creator) { Susanoo::Exports::PageCreator.new(page.path) }
        let(:path) { page_creator.instance_eval{ @path } }
        let(:app)  { page_creator.instance_eval{ @app } }

        before do
          allow_any_instance_of(Susanoo::VisitorsController).to receive(:view).and_raise(RuntimeError)
        end

        around do |example|
          orig = PrefShimaneCms::Application.env_config["action_dispatch.show_exceptions"]
          begin
            PrefShimaneCms::Application.env_config["action_dispatch.show_exceptions"] = true
            example.call
          ensure
            PrefShimaneCms::Application.env_config["action_dispatch.show_exceptions"] = orig
          end
        end

        it "false を返すこと" do
          expect(page_creator.send(:create_mobile_page)).to be_false
        end

        it "HTMLのファイルへの書き込みは行わないこと" do
          expect(page_creator).to_not receive(:write_file)

          page_creator.send(:create_mobile_page)
        end
      end
    end

    describe "#rss_create" do
      let(:top_genre) { create(:top_genre) }

      before do
        rss_page = create(:page_publish, genre_id: top_genre.id)
        publish_content = rss_page.publish_content
        publish_content.update(content: "<%= plugin('news') %>")

        @page_creator = Susanoo::Exports::PageCreator.new(rss_page.path)
        @page_creator.instance_eval{ @page = rss_page }
      end

      it "RssCreatorでmakeしていること" do
        expect_any_instance_of(Susanoo::Exports::RssCreator).to receive(:make)

        @page_creator.send(:rss_create)
      end
    end

    describe "#qr_create" do
      let(:top_genre) { create(:top_genre) }

      context "パスがTOPページの場合" do
        let(:page) { create(:page_publish, name: 'index', genre_id: top_genre.id) }

        before do
          @page_creator = Susanoo::Exports::PageCreator.new(page.path)
        end

        it "QrCodeCreatorでmakeしていること" do
          expect_any_instance_of(Susanoo::Exports::QrCodeCreator).to receive(:make)

          @page_creator.send(:qr_create)
        end
      end

      context "パスがTOPページ以外の場合" do
        let(:page) { create(:page_publish, genre_id: top_genre.id) }

        before do
          @page_creator = Susanoo::Exports::PageCreator.new(page.path)
        end

        it "QrCodeCreatorでmakeされないこと" do
          expect_any_instance_of(Susanoo::Exports::QrCodeCreator).to_not receive(:make)

          @page_creator.send(:qr_create)
        end

        it "trueが返ること" do
          expect(@page_creator.send(:qr_create)).to be_true
        end
      end
    end
  end
end
