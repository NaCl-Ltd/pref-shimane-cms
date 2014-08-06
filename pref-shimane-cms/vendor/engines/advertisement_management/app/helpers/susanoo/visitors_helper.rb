#
# メインアプリのVisitorsHelperを拡張
#
module Susanoo::VisitorsHelper
  #
  # 広告画像のパスを返す
  #
  def ad_image_path(image)
    extname = File.extname(image.path)
    file_name = image.instance.id.to_s + extname
    if @preview
      "/advertisement.data/#{file_name}"
    else
      "/images/advertisement/#{file_name}"
    end
  end
end
