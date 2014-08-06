# -*- coding: utf-8 -*-
#
# ページ作成時にcreate_mp3ジョブを追加する
#
Susanoo::Exports::PageCreator # これが無いとうまく拡張できない
class Susanoo::Exports::PageCreator
  private
  #
  #=== ルビふりページ作成、create_mp3ジョブ追加の拡張
  #
  def create_normal_page_with_rubi
    res = create_normal_page_without_rubi
    if create_rubi_page(res)
      prepare_mp3
      res = true  # rsync を行わせる
    end
    res
  end
  alias_method_chain :create_normal_page, :rubi

  #
  #=== ルビふりページを作成する
  #
  def create_rubi_page(force = false)
    rubi_path = path_with_type(@path, :rubi)
    mtime = File.mtime(export_path(rubi_path)) rescue Time.at(0)
    unless force || mtime <= Word.last_modified
      log("No Need To Create Page: #{rubi_path}")
      return false
    end

    body = read_file(@path)
    return false unless body  # htmlファイルが作成されていない場合

    rubi_body = BrowsingSupport::RubiAdder.add(body)
    if rubi_body
      write_file(rubi_path, rubi_body)
    else
      log(" ------------- Failed MeCab initiarizer --------- ")
      if job = retry_with_rubi
        log("Add Retry Job(id: #{job.id}).")
      end
      GC.start
      return false
    end
    true
  end

  #
  #=== create_mp3 ジョブを登録する
  #
  def prepare_mp3
    m3u_path  = export_path(path_with_type(@path, :m3u))
    rubi_path = export_path(path_with_type(@path, :rubi))

    m3u_file_mtime = File.mtime(m3u_path) rescue Time.at(0)
    unless File.exist?(rubi_path) && m3u_file_mtime <= File.mtime(rubi_path)
      return
    end

    # 音声合成中は not_found.mp3 を再生するm3uを作成する
    File.open(m3u_path, 'w') do |f|
      f.puts File.join(Settings.public_uri, 'not_found.mp3')
    end

    # create_mp3 ジョブを登録する
    Job.create_with(datetime: Time.now)
       .find_or_create_by(
           action: 'create_mp3',
           arg1: @path.to_s,
           arg2: ''
       )
  end

  #
  #=== ルビふりページの再作成を行わせるためのジョブを追加する
  #
  def retry_with_rubi
    job = nil
    job_attr = {}
    if page = Page.find_by_path(@path.to_s)
      if page.visitor_content
        job_attr.update(action: Job::CREATE_PAGE, arg1: page.id.to_s)
      else
        page = nil
      end
    end
    unless page
      if @path.basename.to_s == 'index.html' && (genre = Genre.find_by(path: "#{@path.dirname}/"))
        job_attr.update(action: Job::CREATE_GENRE, arg1: genre.id.to_s)
      end
    end

    unless job_attr.empty?
      next_datetime = 10.minutes.since(Time.zone.now)
      j = Job.datetime_le(next_datetime).find_or_initialize_by(job_attr)
      job = if j.new_record?
        j.datetime = next_datetime
        j.save.inspect
        j
      else
        nil
      end
    end
    job
  end

  #
  #=== ファイルを読み込む
  #
  # ファイルが無い時は nil を返す
  #
  def read_file(dir)
    path = export_path(dir)
    File.readable?(path) ? File.read(path) : nil
  end
end
