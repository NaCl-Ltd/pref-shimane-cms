class Job < ActiveRecord::Base
  include Concerns::Job::Association
  include Concerns::Job::Validation
  include Concerns::Job::Method

  def self.next_mp3
    datetime_arel = self.arel_table[:datetime]
    self.where(action: 'create_mp3').
      where(datetime_arel.lteq(Time.now).or(datetime_arel.eq(nil))).
      order(:id).
      first
  end
end
