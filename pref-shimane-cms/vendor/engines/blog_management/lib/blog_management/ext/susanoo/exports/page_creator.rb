# ブログページのrssを作成する
Susanoo::Exports::PageCreator # これが無いとうまく拡張できない
class Susanoo::Exports::PageCreator
  private

  #
  #=== ブログページのrssを作成する
  #
  def rss_create_with_blog
    rss_create_without_blog
    page = @page || begin
        Page.index_page(Genre.find_by(path: "#{@path.dirname}/"))
      end
    if page.genre.blog_folder_type == ::Genre.blog_folder_types[:top]
      resources = []
      blog_page_ids = page.genre.blog_top_folder.blog_page_ids
      Page.where(id: blog_page_ids).order("blog_date desc").each do |page|
        resources << page if page.visitor_content
        # rssはブログ新着(日付）最新１０件
        break if resources.size == 10
      end
      rss_creator = ::Susanoo::Exports::RssCreator.new(page, resources)
      rss_creator.make
    end
  end

  alias_method_chain :rss_create, :blog
end
