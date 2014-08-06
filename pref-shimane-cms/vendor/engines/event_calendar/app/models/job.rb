class Job < ActiveRecord::Base
  include Concerns::Job::Association
  include Concerns::Job::Validation
  include Concerns::Job::Method

  CREATE_EVENT_PAGE = "create_event_page"
  CANCEL_EVENT_PAGE = "cancel_event_page"
  UPDATE_EVENT_PAGE_TITLE = "update_event_page_title"
end
