module Concerns::Info::Method
  extend ActiveSupport::Concern

  included do
  end

  module ClassMethods

  	#=== トップページに表示するお知らせ
  	def top_page_infos
  		Info.order("last_modified DESC").page()
  	end
  end
end
