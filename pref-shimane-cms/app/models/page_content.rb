#
#== page_contents テーブルのモデルクラス
#
# +begin_date+ が +NULL+ の場合、公開終了日以前は常に公開中として扱う
# +end_date+ が +NULL+ の場合、公開開始日以降は常に公開中として扱う
#
class PageContent < ActiveRecord::Base
  include Concerns::PageContent::Association
  include Concerns::PageContent::Validation
  include Concerns::PageContent::Method
end
