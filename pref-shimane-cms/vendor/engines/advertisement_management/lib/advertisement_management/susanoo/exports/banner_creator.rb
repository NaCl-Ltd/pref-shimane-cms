# -*- coding: utf-8 -*-

module AdvertisementManagement
  module Susanoo
    module Exports

      #
      #= 公開ページのバナーの作成を行うクラス
      #
      class BannerCreator < ::Susanoo::Exports::Creator::Base

        #
        #=== 初期化
        #
        def initialize
          @advertisement_lists = AdvertisementList.published
          @advertisement_corp_lists = AdvertisementList.corp_published
          @image_dest_dir = Settings.export.advertisement.image_dir
          @javascript_file_path = Settings.export.advertisement.javascript_file_path
        end

        #
        #=== バナー広告をコピーして、javascriptファイルを作成する
        #
        def make
          copy_advertisement
          remove_unknown_file
          make_javascript
          update_advertisement
          if page = Page.find_by_path(TOP_PAGE_PATH)
            page_creator = ::Susanoo::Exports::PageCreator.new(page.path)
            page_creator.make
          end
        end

        #
        #=== 広告ファイルをコピーしてサーバと同期する
        #
        def copy_advertisement
          banner_image_src_paths = @advertisement_lists.map{|a_l| a_l.advertisement.image.path}
          copy_file(banner_image_src_paths, @image_dest_dir, {}, src_convert: false)

          sync_dir = "#{File.dirname(@image_dest_dir)}/"
          sync_docroot(sync_dir)
        end

        #
        #=== javascriptファイルを作成する
        #
        def make_javascript
          content = []
          if @advertisement_corp_lists.blank?
            content << {
              url: 'http://www.pref.shimane.lg.jp/seisaku/ad1.html',
              alt: "",
              image: '/index.data/banner.jpg'
            }
          else
            @advertisement_corp_lists.each do |a_l|
              ad = a_l.advertisement
              content << {
                url: ad.url,
                alt: ad.alt,
                image: "#{@image_dest_dir}#{File.basename(ad.image.path)}"
              }
            end
          end
          write_file(@javascript_file_path, "BANNERS = #{JSON.generate(content)}")

          sync_docroot(@javascript_file_path)
        end

        private

          def update_advertisement
            advertisement_lists = AdvertisementList.all
            advertisement_lists.each do |a_l|
              Advertisement.update(a_l.advertisement_id,
                                   state: a_l.state,
                                   pref_ad_number: a_l.pref_ad_number,
                                   corp_ad_number: a_l.corp_ad_number,
                                   toppage_ad_number: a_l.toppage_ad_number)
            end
            advertisement_lists.destroy_all
          end

          def remove_unknown_file
            Dir.glob("#{export_path(@image_dest_dir)}/*") do |ad_file_path|
              ad_id = File.basename(ad_file_path, File.extname(ad_file_path)).to_i
              unless @advertisement_lists.detect{|a_l| a_l.advertisement_id == ad_id}
                remove_file(ad_file_path)
              end
            end
          end
      end
    end
  end
end
