require 'spec_helper'

describe PageContent do
  describe "メソッド" do
    let(:top_event) { create(:genre, event_folder_type: Genre.event_folder_types[:top], parent: create(:top_genre)) }
    let(:event_page) { create(:page, genre: top_event, begin_event_date: Date.today, end_event_date: Date.today) }
    let(:event_page_content) { create(:page_content_editing, page: event_page) }

    describe "#add_create_event_page_job" do
      subject { event_page_content.update_attributes!(admission: PageContent.page_status[:publish], end_date: Time.now.tomorrow) }

      it "create_event_pageジョブが1件追加されること" do
        expect { subject }.to change { Job.where(action: Job::CREATE_EVENT_PAGE).count }.by(1)
      end

      it "cancel_event_pageジョブが1件追加されること" do
        expect { subject }.to change { Job.where(action: Job::CANCEL_EVENT_PAGE).count }.by(1)
      end
    end

    describe "#add_event_job_on_cancel" do
      subject { event_page_content.update_attributes!(admission: PageContent.page_status[:cancel]) }

      it "cancel_event_pageジョブが1件追加されること" do
        expect { subject }.to change { Job.where(action: Job::CANCEL_EVENT_PAGE).count }.by(1)
      end
    end
  end
end
