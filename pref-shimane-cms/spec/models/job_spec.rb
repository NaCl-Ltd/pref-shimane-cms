require 'spec_helper'

describe Job do
  describe "メソッド" do
    describe "クラスメソッド" do
      describe ".create_page" do
        let(:page) { create(:page) }

        before { Timecop.freeze(Time.new(2013,4,1)) }
        after  { Timecop.return }

        subject { Job.create_page(page, page_content) }

        context "コンテンツが公開中でない場合" do
          let(:page_content) { create(:page_content_editing) }

          it "Jobが登録されないこと" do
            expect{ subject }.to change(Job, :count).by(0)
          end
        end

        context "コンテンツが公開中の場合" do

          shared_examples_for "ジョブ登録確認" do |count|
            it "Jobが#{count}件登録されること" do
              expect{ subject }.to change(Job, :count).by(count)
            end
          end

          shared_examples_for "ジョブ内容確認" do |action, datetime|
            before do
              subject
              @job = Job.where(action: action).first
            end

            it "Jobの引数がページIDであること" do
              expect(@job.arg1).to eq(page.id.to_s)
            end

            it "Jobのdatetimeが正しいこと" do
              expect(@job.datetime.to_s).to eq(datetime.to_s)
            end
          end

          context "公開終了日が設定されていない場合" do
            context "公開開始日が設定されている場合" do
              context "公開開始日が現在時刻以前の場合" do
                let(:begin_date) { Time.new(2012,4,1) }
                let(:page_content) { create(:page_content_publish, page: page, begin_date: begin_date, end_date: nil) }

                it_behaves_like("ジョブ登録確認",1)
                it_behaves_like("ジョブ内容確認", Job::CREATE_PAGE, Time.new(2013,4,1))
              end

              context "公開開始日が現在時刻以降の場合" do
                let(:begin_date) { Time.new(2015,4,1) }
                let(:page_content) { create(:page_content_publish, page: page, begin_date: begin_date, end_date: nil) }

                it_behaves_like("ジョブ登録確認",1)
                it_behaves_like("ジョブ内容確認", Job::CREATE_PAGE, Time.new(2015,4,1))
              end
            end
            context "公開開始日が設定されていない場合" do
              let(:begin_date) { nil }
              let(:page_content) { create(:page_content_publish, page: page, begin_date: begin_date, end_date: nil) }

              it_behaves_like("ジョブ登録確認",1)
              it_behaves_like("ジョブ内容確認", Job::CREATE_PAGE, Time.new(2013,4,1))
            end
          end

          context "公開終了日が設定されている場合" do
            let(:end_date) { Time.new(2015,4,1) }
            let(:page_content) { create(:page_content_publish, page: page, begin_date: nil, end_date: end_date) }

            it_behaves_like("ジョブ登録確認", 2)
            it_behaves_like("ジョブ内容確認", Job::CREATE_PAGE, Time.new(2013,4,1))
            it_behaves_like("ジョブ内容確認", Job::CANCEL_PAGE, Time.new(2015,4,1))
          end
        end
      end
    end
  end
end
