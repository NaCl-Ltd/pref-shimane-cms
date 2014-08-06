class Job < ActiveRecord::Base
  include Concerns::Job::Association
  include Concerns::Job::Validation
  include Concerns::Job::Method
end
