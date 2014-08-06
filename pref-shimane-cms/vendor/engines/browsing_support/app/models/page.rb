class Page < ActiveRecord::Base
  include Concerns::Page::Association
  include Concerns::Page::Validation
  include Concerns::Page::Method

  def clean_jobs_with_mp3
    clean_jobs_without_mp3
    Job.where(["(action = :create_mp3 OR action = :move_mp3) AND arg1 = :path",
               {create_mp3: "create_mp3", move_mp3: "move_mp3", path: self.path}]).delete_all
  end

  alias_method_chain :clean_jobs, :mp3
end
