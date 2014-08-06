require 'fileutils'
require 'logger'
require 'susanoo/exports/helpers/path_helper'
require 'susanoo/exports/sync/rsync'

class BrowsingSupport::Exports::Mp3Mover
  include BrowsingSupport::Exports::Helpers::PathHelper
  include ::Susanoo::Exports::Helpers::ServerSyncHelper

  cattr_accessor :logger do
    Logger.new(STDOUT)
  end

  def move(arg, tmp_id)
    path = arg_to_path(arg)
    html_path = export_path(path)
    tmp_dir = Rails.root.join('tmp', tmp_id)

    # mp3, m3u ファイルが格納されているtempディレクトリが
    # 存在しない場合は処理を終了する
    unless tmp_dir.exist?
      logger.info("Mp3Mover: Temp Dir does not exist. (#{tmp_dir})")
      return
    end

    # 公開停止などでファイルが削除された場合は、
    # tempディレクトリを削除し、処理を終了する
    unless html_path.exist?
      logger.info("Mp3Mover: File does not exist. (#{path})")
      FileUtils.rm_rf(tmp_dir)
      return
    end

    dst_dir = html_path.dirname

    tmp_dir_basename = tmp_dir.join(path.basename('.html'))
    dst_dir_basename = dst_dir.join(path.basename('.html'))

    logger.info("Mp3Mover: Move Mp3")

    # 音声ファイルをdocroot にコピー
    FileUtils.cp(Dir["#{tmp_dir_basename}.{m3u,*.mp3,*.md5}"], dst_dir, preserve: true)

    # docrootから不要な mp3, md5ファイルを削除
    keep_mp3_files = File.readlines("#{dst_dir_basename}.m3u").map{|s| File.basename(s.chomp) }
    delete_mp3_files = Dir["#{dst_dir_basename}.*.mp3"].select do |file|
      !keep_mp3_files.include?(File.basename(file))
    end
    delete_mp3_files.concat( delete_mp3_files.map{|s| s.sub(/\.mp3$/, ".md5") } )
    FileUtils.rm_f(delete_mp3_files)

    # 音声合成で使用したtmpディレクトを削除
    FileUtils.rm_rf(tmp_dir)

    logger.info("Mp3Mover: Rsync Mp3")
    begin
      sync_docroot("#{base_path(path)}.*.mp3")
      sync_docroot("#{base_path(path)}.m3u")
    rescue => e
      logger.error("Rsync: #{e}")
    end
  ensure
    # 音声合成で使用したtmpディレクトを削除
    FileUtils.rm_rf(tmp_dir) if tmp_dir
  end
end
