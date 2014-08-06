require 'spec_helper'


describe Susanoo::Exports::Helpers::JobHelper do
  include Susanoo::Exports::Helpers::JobHelper

  describe "メソッド" do
    describe "#add_jobs_for_section_news" do
      let(:page) { create(:page_publish_section_news) }

      before do
        allow_any_instance_of(Susanoo::Exports::Helpers::JobHelper).to receive(:section_top_page_update)
        allow_any_instance_of(Susanoo::Exports::Helpers::JobHelper).to receive(:emergency_update)
        allow_any_instance_of(Susanoo::Exports::Helpers::JobHelper).to receive(:add_jobs_for_static_news_page)
      end

      it "#section_top_page_updateメソッドを呼び出すこと" do
        datetime = 10.minutes.ago

        expect_any_instance_of(Susanoo::Exports::Helpers::JobHelper).to receive(:section_top_page_update).with(page, datetime)
        add_jobs_for_section_news(page, datetime)
      end

      it "#emergency_updateメソッドを呼び出すこと" do
        datetime = 10.minutes.ago

        expect_any_instance_of(Susanoo::Exports::Helpers::JobHelper).to receive(:emergency_update).with(page, datetime)
        add_jobs_for_section_news(page, datetime)
      end

      context "ページが設定されているニュースページの場合" do
        let(:top_genre) { create(:top_genre) }
        let(:page) { create(:page_publish_section_news, genre_id: top_genre.id) }

        it "#add_news_page_jobsメソッドを呼び出していること" do
          datetime = 10.minutes.ago

          expect_any_instance_of(Susanoo::Exports::Helpers::JobHelper).to receive(:add_jobs_for_static_news_page).with(page, datetime)
          add_jobs_for_section_news(page, datetime)
        end
      end
    end

    describe "#add_jobs_for_ancestors" do
      subject { add_jobs_for_ancestors(page, datetime) }

      let(:top_genre) { create(:top_genre) }
      let(:child_genre) { create(:genre, parent: top_genre) }
      let(:grandchild_genre) { create(:genre, parent: child_genre) }
      let(:page) { create(:page, genre: grandchild_genre) }
      let(:datetime) { 10.minutes.ago.round }

      before do
        Job.delete_all
      end

      it "2つのジョブが追加されること" do
        expect{subject}.to change{ Job.count }.by(2)
      end

      it "grandchild_genre の create_genre ジョブが追加されること" do
        job = Job.where(action: 'create_genre', arg1: grandchild_genre.id.to_s, datetime: datetime)
        subject
        expect(job).to exist
      end

      it "child_genre の create_genre ジョブが追加されること" do
        job = Job.where(action: 'create_genre', arg1: child_genre.id.to_s, datetime: datetime)
        subject
        expect(job).to exist
      end

      it "top_genre の create_genre ジョブが追加されないこと" do
        job = Job.where(action: 'create_genre', arg1: top_genre.id.to_s)
        subject
        expect(job).to_not exist
      end

      it ".find_or_create_byメソッドでジョブを追加していること" do
        stub_const('Job', double('Job').as_null_object)
        expect(Job).to receive(:find_or_create_by).twice
        subject
      end
    end

    describe "#add_jobs_for_static_news_page" do
      subject{ add_jobs_for_static_news_page(page, Time.now) }

      let(:top_genre) { create(:top_genre) }
      let(:bousai_info_genre) { create(:genre, name: 'bousai_info', parent_id: top_genre.id) }
      let!(:bousai_news_page) { create(:page, name: 'bousai_news', genre_id: top_genre.id) }

      let!(:page) { create(:page, genre_id: bousai_info_genre.id) }

      context "引数で渡されたページが、ニュースページとして設定されているジャンルのページの場合" do
        it "Jobが1件増えること" do
          expect{subject}.to change(Job, :count).by(1)
        end
      end
    end

    describe "#section_top_page_update" do
      subject{ section_top_page_update(page, Time.now) }

      let!(:top_genre) { create(:top_genre) }
      let!(:genre) { create(:genre, parent_id: top_genre.id) }
      let!(:page) { create(:page, genre_id: genre.id) }

      context "所属トップフォルダが存在する場合" do
        let!(:section_top_genre) { create(:section_top_genre, parent: top_genre, section: genre.section) }

        before do
          page.reload
        end

        context "Jobが存在する場合" do
          before do
            create(:job, action: 'create_genre', arg1: section_top_genre.id.to_s)
          end

          it "Jobが増えないこと" do
            expect{subject}.to change(Job, :count).by(0)
          end
        end

        context "Jobが存在しない場合" do
          it "Jobが1件増えること" do
            expect{subject}.to change(Job, :count).by(1)
          end
        end
      end

      context "所属トップフォルダが存在しない場合" do
        it "Jobが増えないこと" do
          expect{subject}.to change(Job, :count).by(0)
        end
      end
    end

    describe "#emergency_update" do
      subject{ emergency_update(page, Time.now) }

      let(:top_genre) { create(:top_genre) }

      context "引数で渡されたページが緊急情報のページの場合" do
        let(:emergency_genre) { create(:genre, name: 'emergency', parent_id: top_genre.id) }
        let!(:page) { create(:page, genre_id: emergency_genre.id) }

        it "Jobが1件増えること" do
          expect{subject}.to change(Job, :count).by(1)
        end
      end

      context "引数で渡されたページが緊急情報のページ以外の場合" do
        let!(:page) { create(:page, genre_id: top_genre.id) }

        it "Jobが増えないこと" do
          expect{subject}.to change(Job, :count).by(0)
        end
      end
    end
  end
end
