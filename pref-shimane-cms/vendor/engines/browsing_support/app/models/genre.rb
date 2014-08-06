class Genre < ActiveRecord::Base
  include Concerns::Genre::Association
  include Concerns::Genre::Validation
  include Concerns::Genre::Method

  def clean_jobs_with_mp3
    clean_jobs_without_mp3
    _path = self.path + "%"
    Job.where(["(action = :create_mp3 OR action = :move_mp3) AND arg1 LIKE :path",
               {create_mp3: "create_mp3", move_mp3: "move_mp3", path: _path}]).delete_all
  end

  alias_method_chain :clean_jobs, :mp3
end
