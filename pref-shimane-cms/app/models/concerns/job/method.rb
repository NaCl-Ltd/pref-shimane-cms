module Concerns::Job::Method
  extend ActiveSupport::Concern

  included do
    scope :eq_remove_attachment_with_path, ->(path){
      where('action = ? AND arg1 LIKE ?', ::Job::REMOVE_ATTACHMENT, "#{path}%")
    }

    scope :eq_enable_remove_attachment_with_path, ->(path){
      where('action = ? AND arg1 LIKE ?', ::Job::ENABLE_REMOVE_ATTACHMENT, "#{path}%")
    }

    scope :datetime_is_nil_or_le, ->(time) {
      datetime_attr = self.arel_table[:datetime]
      where(datetime_attr.eq(nil).or(datetime_attr.lteq(time)))
    }

    scope :datetime_le, ->(time) {
      datetime_attr = self.arel_table[:datetime]
      where(datetime_attr.lteq(time))
    }

    scope :queue_eq, ->(value) {
      where(queue: self.queues[value])
    }
  end

  module ClassMethods
    def queues
      @queus ||= {
        export: 0,        # Default
        move_export: 1,   # MEMO: 名前を変える
      }.with_indifferent_access.freeze
    end

    #
    #=== ページ作成ジョブを登録する
    #
    def create_page(page, page_content)
      return if page_content.admission != PageContent.page_status[:publish]

      now = Time.now
      if page_content.begin_date
        begin_date = (page_content.begin_date >= now) ? page_content.begin_date : now
      else
        begin_date = now
      end
      Job.create(action: Job::CREATE_PAGE, arg1: page.id.to_s, datetime: begin_date)
      Job.create(action: Job::CANCEL_PAGE, arg1: page.id.to_s, datetime: page_content.end_date) if page_content.end_date
    end

    #
    #=== path以下にある全ページを対象にcreate_pageジョブを作成する
    #
    def create_all_pages(path)
      genre = Genre.find_by_path(path)
      return nil unless genre

      genre.descendants_pages.each do |page|
        # visitor_contentが存在し、かつ時刻指定なしのcreate_pageが存在しないとき
        if page.visitor_content && !Job.where(action: Job::CREATE_PAGE, datetime: nil, arg1: page.id.to_s).exists?
          Job.create(action: Job::CREATE_PAGE, arg1: page.id.to_s)
        end
      end
    end
  end
end
