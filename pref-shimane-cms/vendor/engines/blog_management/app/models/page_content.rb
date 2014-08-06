class PageContent < ActiveRecord::Base
  include Concerns::PageContent::Association
  include Concerns::PageContent::Validation
  include Concerns::PageContent::Method

  before_create :generate_blog_index_page_content,
                  :if => lambda { self.page.blog_date }

  # 公開のブログページコンテンツを編集したときに呼ばれる
  def update_as_public_for_blog(page_content_params)
    # 公開停止、公開中のどちらかの状態であれば、インデックスページを作り直す
    # また、前後の月のジャンルのインデックスページも同様に作りなおす
    if publish? || cancel?
      if month_page = self.page.genre.pages.where(name: "index").first
        month_page.add_blog_index_page_job
      end

      if year_page = self.page.genre.parent.pages.where(name: "index").first
        year_page.add_blog_index_page_job
      end

      if top_page = self.page.genre.parent.parent.pages.where(name: "index").first
        top_page.add_blog_index_page_job
      end

      self.page.add_blog_index_page_jobs(page_content_params[:begin_date] || Time.now)

      true
    end
  end

  # 非公開のブログページコンテンツを編集したときに呼ばれる
  def update_as_private_for_blog(page_content_params)
    # 公開、にしたとき以外は何もしない
    return true if page_content_params[:admission].to_i != ::PageContent.page_status[:publish]

    #　月インデックスページの編集処理
    if month_page = self.page.genre.pages.where(name: "index").first
      if month_page_content = month_page.private_content
        month_page_content.update_as_private_for_blog_index(page_content_params)
      end
    end

    #　年インデックスページの編集処理
    if year_page = self.page.genre.parent.pages.where(name: "index").first
      if year_page_content = year_page.private_content
        year_page_content.update_as_private_for_blog_index(page_content_params)
      end
    end

    #　ブログトップインデックスページの編集処理
    if top_page = self.page.genre.parent.parent.pages.where(name: "index").first
      if top_page_content = top_page.private_content
        top_page_content.update_as_private_for_blog_index(page_content_params)
      end
    end

    self.page.add_blog_index_page_jobs(page_content_params[:begin_date] || Time.now)
    return true
  end

  def update_as_private_for_blog_index(page_content_params)
    self.attributes = page_content_params
    self.last_modified = Time.now if publish?
    self.section_news = PageContent.section_news_status[:no]
    self.end_date = nil  # 一旦公開されたインデックスページは非公開にしない

    begin
      self.transaction do
        self.last_modified = Time.now if publish?
        self.save!
        publish! if publish?
      end
      return true
    rescue => e
      logger.debug(%Q!#{$!} : #{$@.join("\n")}!)
      return false
    end
  end

  private

  def generate_blog_index_page_content
    attr = {
      admission: page_status[:editing], top_news: top_news_status[:no],
      format_version: current_format_version, last_modified: Time.zone.now
    }

    # 月フォルダのindexページコンテントを作成
    month_page = Page.where(genre_id: self.page.genre_id, name: "index").first
    month_attr = attr.merge({page_id: month_page.id})
    PageContent.create! month_attr.merge(content: " ") unless PageContent.exists? month_attr

    # 年フォルダのindexページコンテントを作成
    year_page = Page.where(genre_id: self.page.genre.parent_id, name: "index").first
    year_attr = attr.merge({page_id: year_page.id})
    PageContent.create! year_attr.merge(content: " ") unless PageContent.exists? year_attr

    # ブログトップフォルダのindexページコンテントを作成
    blog_page = Page.where(genre_id: self.page.genre.parent.parent_id, name: "index").first
    top_attr = attr.merge({page_id: blog_page.id})
    PageContent.create! top_attr.merge(content: " ") unless PageContent.exists? top_attr
  end
end
