class PageContent < ActiveRecord::Base
  include Concerns::PageContent::Association
  include Concerns::PageContent::Validation
  include Concerns::PageContent::Method

  after_save :add_event_job_on_public, :if => lambda { self.publish? && self.page.event? }
  after_save :add_event_job_on_cancel, :if => lambda { self.cancel? && self.page.event? }
  after_save :regist_event_refer

  private

  # イベントページを公開するときの特有の処理を行うJobを追加する
  def add_event_job_on_public
    page = self.page
    return true if self.page.name == "index"
    Job.create(action: Job::CREATE_EVENT_PAGE, arg1: self.page_id.to_s, datetime: self.begin_date || Time.now)
    Job.create(action: Job::CANCEL_EVENT_PAGE, arg1: self.page_id.to_s, datetime: self.end_date) if self.end_date
  end

  # イベントページを公開停止にするときの特有の処理を行うJobを追加する
  def add_event_job_on_cancel
    return true if self.page.name == "index"
    Job.create(action: Job::CANCEL_EVENT_PAGE, arg1: self.page_id.to_s, datetime: Time.now)
  end

  # イベント関係のプラグインが埋め込まれているかチェックし、あれば登録する
  def regist_event_refer
    ::EventReferer.regist(self.page.path) if self.publish?
  end
end
