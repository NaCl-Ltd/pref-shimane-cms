require 'spec_helper'

describe Susanoo::Export do
  describe "メソッド" do
    let(:export) { Susanoo::Export.new }

    before do
      allow_any_instance_of(Susanoo::Exports::Creator::Base).to receive(:sync)
    end

    describe ".action_methods" do
      it "Export処理のアクションが登録されていること" do
        expect(Susanoo::Export.action_methods.to_a).to include(*%w[
          all_page
          create_genre
          create_page
          cancel_page
          delete_page
          move_page
          delete_folder
          move_folder
          synchronize_folder
          create_htaccess
          create_htpasswd
          destroy_htaccess
          destroy_htpasswd
          remove_from_htpasswd
          create_all_section_page
          remove_attachment
          enable_remove_attachment
        ])
      end
    end

    describe "#run" do
      describe "例外処理" do
        let(:lock_file) { Tempfile.open('export_lock') }
        let(:select_jobs) { [] }

        before do
          allow(export).to receive(:lock_file).and_return(lock_file)

          allow(export).to receive(:select_jobs).and_return(
              *Array(select_jobs).map{|j| Job.where(id: j.id) },
              Job.where(id: nil)
            )
        end

        after do
          lock_file.close!
        end

        context "発生する例外が ActiveRecord::RecordNotFound, Errno::ENOENT 以外の場合" do
          before do
            allow(export).to receive(:create_page).and_raise(RuntimeError)
          end

          context "Job#datetime が nil の場合" do
            let!(:page) { create(:page_publish) }
            let!(:job1) { create(:job, action: 'create_page', arg1: page.id.to_s) }
            let!(:select_jobs) { [job1] }

            it "ジョブは削除されること" do
              expect do
                export.run
              end.to change{ Job.count }.by(-1)

              expect(Job.where(id: job1.id)).to_not exist
            end
          end

          context "Job#datetime が nil でない場合" do
            let!(:page) { create(:page_publish) }
            let!(:job1) { create(:job, action: 'create_page', arg1: page.id.to_s, datetime: Time.zone.now) }
            let!(:select_jobs) { [job1] }

            context "10分以内に同じページのジョブが存在しない場合" do
              let!(:schduled_job) { create(:job, action: 'create_page', arg1: page.id.to_s, datetime: 11.minutes.since) }

              around do |example|
                Timecop.freeze do
                  example.call
                end
              end

              it "datetime は現時刻から10分後の時間に更新されること" do
                expect do
                  export.run
                end.to change{ Job.count }.by(0)

                old_job1_attrs = {}.merge(job1.attributes)
                job1.reload

                cmp_attrs = %w[id action arg1 arg2]
                expect(job1.attributes.slice(*cmp_attrs)).to include old_job1_attrs.slice(*cmp_attrs)
                expect(job1.datetime.to_i).to eq 10.minutes.since.to_i
                  # タイムスタンプの精度問題で失敗する時があるため、起算からの経過秒数で比較する
              end
            end

            context "10分以内に同じページのジョブが存在する場合" do
              let!(:schduled_job) { create(:job, action: 'create_page', arg1: page.id.to_s, datetime: 10.minutes.since) }

              it "ジョブは削除されること" do
                expect do
                  export.run
                end.to change{ Job.count }.by(-1)

                expect(Job.where(id: job1.id)).to_not exist
              end
            end
          end
        end
      end
    end

    describe "#create_genre" do
      let(:genre) { create(:genre) }

      it "PageCreatorでページをmakeしていること" do
        expect_any_instance_of(Susanoo::Exports::PageCreator).to receive(:make)
        export.create_genre(genre.id)
      end

      context "ジャンルレコードが存在しない場合" do
        before do
          Genre.stub(:find).and_raise ActiveRecord::RecordNotFound
        end

        it "例外処理は行わないこと" do
          expect {
            export.create_genre(genre.id)
          }.to raise_error(ActiveRecord::RecordNotFound)
        end
      end

      context "パスを持たないジャンルレコードの場合" do
        before do
          allow_any_instance_of(Genre).to receive(:path).and_return(nil)
        end

        it "ログを出力していること" do
          expect_any_instance_of(Susanoo::Export).to receive(:log)
          export.create_genre(genre.id)
        end
      end
    end

    describe "#create_page" do
      let(:top_genre) { create(:top_genre) }
      let(:page) { create(:page, genre_id: top_genre.id) }

      before do
        allow_any_instance_of(Susanoo::Exports::PageCreator).to receive(:make).and_return(true)
      end

      it "PageCreatorでページをmakeしていること" do
        expect_any_instance_of(Susanoo::Exports::PageCreator).to receive(:make)
        export.create_page(page.id)
      end

      context "makeに成功した場合" do
        before do
          allow_any_instance_of(Susanoo::Exports::PageCreator).to receive(:make).and_return(true)
        end

        it "add_jobs_for_ancestorsメソッドを呼び出すこと" do
          expect_any_instance_of(Susanoo::Export).to receive(:add_jobs_for_ancestors).with(page)
          export.create_page(page.id)
        end

        it "disable_remove_attachmentメソッドを呼び出さないこと" do
          expect_any_instance_of(Susanoo::Export).to_not receive(:disable_remove_attachment)
          export.create_page(page.id)
        end

        it "Page#clear_duplication_latestメソッドを呼び出すこと" do
          expect_any_instance_of(Page).to receive(:clear_duplication_latest)
          export.create_page(page.id)
        end
      end

      context "makeに失敗した場合" do
        before do
          allow_any_instance_of(Susanoo::Exports::PageCreator).to receive(:make).and_return(false)
        end

        it "add_jobs_for_ancestorsメソッドを呼び出さないこと" do
          expect_any_instance_of(Susanoo::Export).to_not receive(:add_jobs_for_ancestors)
          export.create_page(page.id)
        end

        it "disable_remove_attachmentメソッドを呼び出すこと" do
          expect_any_instance_of(Susanoo::Export).to receive(:disable_remove_attachment).with(page.path)
          export.create_page(page.id)
        end

        it "Page#clear_duplication_latestメソッドを呼び出さないこと" do
          expect_any_instance_of(Page).to_not receive(:clear_duplication_latest)
          export.create_page(page.id)
        end
      end

      context "新着掲載" do
        context "SesctionNewsレコードが追加された場合" do
          before do
            SectionNews.delete_all

            allow_any_instance_of(Susanoo::Exports::PageCreator).to receive(:make) do
              create(:section_news, page_id: page.id)
              true
            end
          end

          it "add_jobs_for_section_newsメソッドを呼び出すこと" do
            expect_any_instance_of(Susanoo::Export).to receive(:add_jobs_for_section_news).with(page)
            export.create_page(page.id)
          end
        end

        context "SesctionNewsレコードが削除された場合" do
          before do
            section_news = create(:section_news, page_id: page.id)

            allow_any_instance_of(Susanoo::Exports::PageCreator).to receive(:make) do
              section_news.destroy
              true
            end
          end

          it "add_jobs_for_section_newsメソッドを呼び出すこと" do
            expect_any_instance_of(Susanoo::Export).to receive(:add_jobs_for_section_news).with(page)
            export.create_page(page.id)
          end
        end

        context "PageCreator#make でSesctionNewsに登録済みのまま、変更が無い場合" do
          before do
            create(:section_news, page_id: page.id)
          end

          it "add_jobs_for_section_newsメソッドを呼び出さないこと" do
            expect_any_instance_of(Susanoo::Export).to_not receive(:add_jobs_for_section_news)
            export.create_page(page.id)
          end
        end

        context "PageCreator#make でSesctionNewsに未登録のまま、変更が無い場合" do
          before do
            SectionNews.delete_all
          end

          it "add_jobs_for_section_newsメソッドを呼び出さないこと" do
            expect_any_instance_of(Susanoo::Export).to_not receive(:add_jobs_for_section_news)
            export.create_page(page.id)
          end
        end
      end

      context "Pageレコードが存在しない場合" do
        before do
          Page.stub(:find).and_raise ActiveRecord::RecordNotFound
        end

        it "例外処理は行わないこと" do
          expect {
            export.create_page(page.id)
          }.to raise_error(ActiveRecord::RecordNotFound)
        end
      end
    end

    describe "#cancel_page" do
      let(:top_genre) { create(:top_genre) }
      let(:page) { create(:page, genre_id: top_genre.id) }

      before do
        allow_any_instance_of(Susanoo::Exports::PageCreator).to receive(:cancel)
      end

      it "PageCreatorでページををcancelしていること" do
        expect_any_instance_of(Susanoo::Exports::PageCreator).to receive(:cancel)
        export.cancel_page(page.id)
      end

      it "destroy_remove_attachmentメソッドを呼び出していること" do
        expect_any_instance_of(Susanoo::Export).to receive(:destroy_remove_attachment).with(page.path)
        export.cancel_page(page.id)
      end

      it "add_jobs_for_ancestorsメソッドを呼び出していること" do
        expect_any_instance_of(Susanoo::Export).to receive(:add_jobs_for_ancestors).with(page)
        export.cancel_page(page.id)
      end

      context "新着掲載" do
        context "SesctionNewsレコードが追加された場合" do
          before do
            SectionNews.delete_all

            allow_any_instance_of(Susanoo::Exports::PageCreator).to receive(:cancel) do
              create(:section_news, page_id: page.id)
              true
            end
          end

          it "add_jobs_for_section_newsメソッドを呼び出すこと" do
            expect_any_instance_of(Susanoo::Export).to receive(:add_jobs_for_section_news).with(page)
            export.cancel_page(page.id)
          end
        end

        context "SesctionNewsレコードが削除された場合" do
          before do
            section_news = create(:section_news, page_id: page.id)

            allow_any_instance_of(Susanoo::Exports::PageCreator).to receive(:cancel) do
              section_news.destroy
              true
            end
          end

          it "add_jobs_for_section_newsメソッドを呼び出すこと" do
            expect_any_instance_of(Susanoo::Export).to receive(:add_jobs_for_section_news).with(page)
            export.cancel_page(page.id)
          end
        end

        context "PageCreator#make でSesctionNewsに登録済みのまま、変更が無い場合" do
          before do
            create(:section_news, page_id: page.id)
          end

          it "add_jobs_for_section_newsメソッドを呼び出さないこと" do
            expect_any_instance_of(Susanoo::Export).to_not receive(:add_jobs_for_section_news)
            export.cancel_page(page.id)
          end
        end

        context "PageCreator#make でSesctionNewsに未登録のまま、変更が無い場合" do
          before do
            SectionNews.delete_all
          end

          it "add_jobs_for_section_newsメソッドを呼び出さないこと" do
            expect_any_instance_of(Susanoo::Export).to_not receive(:add_jobs_for_section_news)
            export.cancel_page(page.id)
          end
        end
      end

      context "Pageレコードが存在しない場合" do
        before do
          Page.stub(:find).and_raise ActiveRecord::RecordNotFound
        end

        it "例外処理は行わないこと" do
          expect {
            export.cancel_page(page.id)
          }.to raise_error(ActiveRecord::RecordNotFound)
        end
      end
    end

    describe "#delete_page" do
      let(:top_genre) { create(:top_genre) }
      let(:page) { create(:page, genre_id: top_genre.id) }

      it "PageCreatorでページをdeleteしていること" do
        expect_any_instance_of(Susanoo::Exports::PageCreator).to receive(:delete)
        export.delete_page(page.path)
      end

      it "destroy_remove_attachmentメソッドを呼び出していること" do
        expect_any_instance_of(Susanoo::Export).to receive(:destroy_remove_attachment)
        export.delete_page(page.path)
      end
    end

    describe "#move_page" do
      let(:top_genre) { create(:top_genre) }
      let(:page) { create(:page, name: 'index', genre_id: top_genre.id) }

      let(:to_genre) { create(:genre, parent_id: top_genre.id) }

      it "PageCreatorでページをmoveしていること" do
        expect_any_instance_of(Susanoo::Exports::PageCreator).to receive(:move)
        export.move_page(top_genre.path, page.path)
      end

      context "移動元のGenreレコードが存在する場合" do
        it "Genre#add_genre_jobs_to_parentを呼び出してること" do
          expect_any_instance_of(Genre).to receive(:add_genre_jobs_to_parent)
          export.move_page(top_genre.path, page.path)
        end
      end
    end

    describe "#delete_folder" do
      let(:top_genre) { create(:top_genre) }
      let(:genre) { create(:genre, parent_id: top_genre.id) }

      it "PageCreatorでページをdelete_dirしていること" do
        expect_any_instance_of(Susanoo::Exports::PageCreator).to receive(:delete_dir)
        export.delete_folder(genre.path)
      end

      it "destroy_remove_attachmentメソッドを呼び出していること" do
        expect_any_instance_of(Susanoo::Export).to receive(:destroy_remove_attachment)
        export.delete_folder(genre.path)
      end
    end

    describe "#move_folder" do
      let(:top_genre) { create(:top_genre) }
      let(:from_genre) { create(:genre, parent: top_genre).reload }
      let(:to_genre) { create(:genre, parent: top_genre).reload }


      it "PageCreatorでページをmove_dirしていること" do
        expect_any_instance_of(Susanoo::Exports::PageCreator).to receive(:move_dir)
        export.move_folder(to_genre.path, from_genre.path)
      end

      it "synchronize_folder ジョブが追加されること" do
        expect do
          export.move_folder(to_genre.path, from_genre.path)
        end.to change{ Job.where(action: 'synchronize_folder', arg1: from_genre.path).count }.by(1)
      end
    end

    describe "#synchronize_folder" do
      let(:top_genre) { create(:top_genre) }
      let(:genre) { create(:genre, parent_id: top_genre.id) }

      it "Susanoo::Exports::PageCreator#sync_docroot メソッドを呼び出すこと" do
        expect_any_instance_of(Susanoo::Exports::PageCreator).to receive(:sync_docroot).with(File.join(genre.path, '/')).once
        export.synchronize_folder(genre.path)
      end
    end

    describe "#create_htaccess" do
      let(:genre) { create(:genre) }

      it "makeメソッドを呼び出していること" do
        expect_any_instance_of(Susanoo::Exports::Creator::BasicAuth::Apache).to receive(:make)
        export.create_htaccess(genre.id)
      end
    end

    describe "#create_htpasswd" do
      let(:genre) { create(:genre) }

      it "make_htpasswdメソッドを呼び出していること" do
        expect_any_instance_of(Susanoo::Exports::Creator::BasicAuth::Apache).to receive(:make_htpasswd)
        export.create_htpasswd(genre.id)
      end
    end

    describe "#destroy_htaccess" do
      let(:genre) { create(:genre) }

      it "deleteメソッドを呼び出していること" do
        expect_any_instance_of(Susanoo::Exports::Creator::BasicAuth::Apache).to receive(:delete)
        export.destroy_htaccess(genre.id)
      end
    end

    describe "#destroy_htpasswd" do
      let(:genre) { create(:genre) }

      it "delete_htpasswdメソッドを呼び出していること" do
        expect_any_instance_of(Susanoo::Exports::Creator::BasicAuth::Apache).to receive(:delete_htpasswd)
        export.destroy_htpasswd(genre.id)
      end
    end

    describe "#remove_from_htpasswd" do
      let(:genre) { create(:genre) }

      it "delete_htpasswd_with_loginメソッドを呼び出していること" do
        expect_any_instance_of(Susanoo::Exports::Creator::BasicAuth::Apache).to receive(:delete_htpasswd_with_login)
        export.remove_from_htpasswd(genre.id, 'login')
      end
    end

    describe "#create_all_section_page" do
      let(:section) { create(:section) }

      it "delete_htpasswd_with_loginメソッドを呼び出していること" do
        expect_any_instance_of(Susanoo::Export).to receive(:create_section_genre_pages_jobs).with(section.id)
        export.create_all_section_page(section.id)
      end
    end

    describe "#remove_attachment" do
      let(:genre) { create(:genre, path: 'export_test') }
      let(:page) { create(:page, genre: genre, name: 'index') }
      let(:file_path) { Rails.root.join(Settings.export.docroot, genre.path, "#{page.name}.data") }
      before do
        FileUtils.mkdir_p file_path
        FileUtils.cp File.join(Rails.root, "spec/files/rails.png"), file_path
      end
      after do
        FileUtils.rm_rf file_path
      end

      it "remove_attachmentメソッドを呼び出していること" do
        expect_any_instance_of(Susanoo::Export).to receive(:remove_attachment).with(file_path.join("rails.png"))
        export.remove_attachment(file_path.join("rails.png"))
      end

      it "添付ファイルが削除されること" do
        export.remove_attachment(file_path.join("rails.png"))
        expect(file_path.join("rails.png")).not_to exist
      end
    end

  end
end

