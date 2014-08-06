#
# page_contentsテーブルで、10件より古いデータを削除するタスク
#
namespace :page_content do
  task clear_histories: :environment do
    pages_count = Page.all.size
    loop_count = 0

    while loop_count <= pages_count do
      pages = Page.all.order("id asc").limit(1000).offset(loop_count)

      pages.each do |page|
        histories_ids = PageContent.select(:id).where("page_id = ? AND (admission = 3 OR admission = 4)", page.id).order("id DESC").map(&:id)
        next if histories_ids.empty?

        ActiveRecord::Base.connection.execute("UPDATE page_contents SET latest = True WHERE id = #{histories_ids.first}")
        if histories_ids.size >= 10
          PageLink.where('page_content_id IN (?)', histories_ids[10..-1]).delete_all
          PageContent.where('id IN (?)', histories_ids[10..-1]).delete_all
        end
      end

      str = loop_count
      loop_count += 1000
      p "#{loop_count}/#{pages_count}"
    end

  end
end
