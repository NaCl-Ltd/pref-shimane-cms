module Susanoo
  module Assets
    class Image < Base

      has_attached_file :data,
        url: ':page_data/:basename.:extension',
        path: ':rails_root/files/:rails_env/:page_id/:basename.:extension',
        styles: {
          original: {
            processors: %i(image_resizer_classic),
            filesize: proc { Settings.max_upload_image_size },
            quality: 75,
            pivot_geometry: '400x266',
            trials: 15,
          }
        }

      before_data_post_process :resize_required?

      def self.all(params = {})
        images = []
        page = Page.find(params[:page_id])
        files = Dir.glob(Rails.root.join('files', Rails.env.to_s, page.id.to_s, '*')).sort
        files.grep(regex[:image]).each do |i|
          image = new
          image.page = page
          image.data = File.open(i)
          images << image
        end
        images
      end

      #
      #=== アップロードファイルを検証する
      #
      def save
        return false unless validate_image_file_type
        return false unless validate_image_size
        return false unless validate_total_image_size
        super
      end

      def resize_required?
        !!(extname =~ /^\.je?pg$/i)
      end

      #
      #=== ファイルの拡張子を検証する
      #
      def validate_image_file_type
        if extname !~ regex[:image]
          @messages << I18n.t('shared.upload.invalid_image_type')
          false
        else
          true
        end
      end

      #
      #=== ファイルサイズを検証する
      #
      def validate_image_size
        if data_file_size > Settings.max_upload_image_size
          # リサイズ対象画像とそれ以外とでメッセージを変更する
          @messages <<
            if resize_required?
              I18n.t('shared.upload.failed_optimization')
            else
              I18n.t('shared.upload.image_size_too_big', size: number_to_human_size(Settings.max_upload_image_size))
            end
          false
        else
          true
        end
      end

      #
      #=== ファイル合計サイズを検証する
      #
      def validate_total_image_size
        if total_image_size + data_file_size > Settings.max_upload_image_total_size
          @messages << I18n.t('shared.upload.image_total_size_too_big', size: number_to_human_size(Settings.max_upload_image_total_size))
          false
        else
          true
        end
      end

      #
      #== ページフォルダにある画像一覧
      #
      def sibling
        Susanoo::Assets::Image.all(page_id: page.id)
      end

      #
      #== ページフォルダにある画像の合計サイズ
      #
      def total_image_size
        total_size = 0
        sibling.each {|_| total_size += _.data_file_size}
        total_size
      end

      private

        def number_to_human_size(number)
          ActiveSupport::NumberHelper.number_to_human_size(number, precision: 0).sub(/b(?:ytes?)?$/i, '').sub(/K$/, 'k').delete(' ')
        end
    end
  end
end
