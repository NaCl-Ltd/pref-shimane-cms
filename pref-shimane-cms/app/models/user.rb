#
#= ユーザクラス
#
class User < ActiveRecord::Base
  include Concerns::User::Association
  include Concerns::User::Validation
  include Concerns::User::Method
end
