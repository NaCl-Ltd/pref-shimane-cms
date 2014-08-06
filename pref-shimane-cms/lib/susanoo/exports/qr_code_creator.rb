module Susanoo
  module Exports

    #
    #= パスから、QRコードを作成するクラス
    #
    class QrCodeCreator < Creator::Base

      @@default_options = {
        size: 4, level: :h
      }.with_indifferent_access

      #
      #=== 初期化
      #
      # パスをセットする
      def initialize(path)
        @path = path.to_s
      end

      #
      #=== QRコードを作成して、ファイルに書き込む
      #
      def make(options={})
        qr_path = path_with_type(@path, :qr)
        unless File.exists?(export_path(qr_path))
          qr_code = RQRCode::QRCode.new(@path, @@default_options.merge(options))
          write_file(qr_path, qr_code.to_img.to_s)
        else
          return false
        end
      end
    end

  end
end
