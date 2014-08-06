#
#= 閲覧管理コントローラ
#
class Susanoo::VisitorsController < ApplicationController
  include Concerns::Susanoo::VisitorsController

  before_action :set_advertisement, only: %i(view preview), if: -> { @page_view && @page_view.top? }
  before_action :set_advertisement_page_view, only: %i(preview_virtual)
  before_action :set_advertisement_attach_file, only: %i(attach_file)

  private

    #
    #=== 広告画像をセットする
    #
    def set_advertisement
      @pref_ads = Advertisement.pref_published
      @corp_ads = Advertisement.corp_published
    end

    #
    #=== 擬似的に広告コンテンツを作成する
    #
    def set_advertisement_page_view
      if params[:mode] == "advertisement"
        @preview = true

        content = %Q!<%= plugin('banner') %>!
        page = Page.new(name: "preview", title: "プレビュー", genre: Genre.top_genre)
        page_content = PageContent.new(page: page, content: content)
        @page_view = ::Susanoo::PageView.new(page_content: page_content)
      end
    end

    #
    #=== 広告画像を返す
    #
    def set_advertisement_attach_file
      path = request.path
      dir = File.dirname(path)
      file = File.basename(path)

      if path =~ /^\/images\// && path =~ /advertisement/
        file = "advertisement/#{file}"
        file_path = Rails.root.join('public.', 'images', file).to_s
      elsif dir == '/advertisement.data'
        file_path = Rails.root.join(Advertisement::IMAGE_DIR, file).to_s
      end

      if file_path
        @attach_response = {type: :file, content: file_path}
      end
    end

end
