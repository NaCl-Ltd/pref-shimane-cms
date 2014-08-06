
namespace :site_design do
  # SiteDesignエンジンにある images, javascripts, stylesheets を 設置する
  #
  # @args
  #   EXPOSED_DIR : ファイルのシンボリックリンク作成先フォルダ
  #   SYNC_DIR : ファイルのコピー先フォルダ
  exposed_dir = File.join(Rails.root.to_s, ENV["EXPOSED_DIR"] || "public.")
  sync_dir = ENV["SYNC_DIR"]


  namespace :install do
    # シンボリックリンク作成タスク
    desc "Set visitor-files(images, javascripts, stylesheets) to pref-shimane-cms exposed dir (DEFAULT: public.)"
    task :assets => [exposed_dir, "images", "javascripts", "stylesheets"]

    # 各ファイルのタスクの定義
    # * set_images 等、単体でもrake使用可
    filetypes = ["images", "javascripts", "stylesheets"]
    filetypes.each do |filetype|
      src = SiteDesign::Engine.root.join("app", "assets", filetype, "susanoo", "visitors")

      # シンボリックリンク関係の処理
      ln_dest = File.join(exposed_dir, filetype)
      desc "Set visitor-#{filetype} to pref-shimane-cms exposed dir"
      task "#{filetype}" => ln_dest
      file ln_dest do
        sh "ln -s #{src} #{ln_dest}"
      end
    end
  end

  namespace :sync do
    # コピー作成(rsync --delete) タスク
    desc "Set visitor-files(images, javascripts, stylesheets) to SYNC_DIR with rsync --delete"
    task :assets => ["images", "javascripts", "stylesheets"]

    # 各ファイルのタスクの定義
    # * set_images 等、単体でもrake使用可
    filetypes = ["images", "javascripts", "stylesheets"]
    filetypes.each do |filetype|
      src = SiteDesign::Engine.root.join("app", "assets", filetype, "susanoo", "visitors")
      # sync 関係の処理
      desc "Sync visitor-#{filetype} to SYNC_DIR"
      task "sync_#{filetype}" do |task|
        if sync_dir
          sync_dest = File.join(sync_dir, filetype)
          sh "mkdir -p #{sync_dest}"  unless File.exist?(sync_dest)
          sh "rsync -aC --delete #{src}/ #{sync_dest}/"
        else
          puts "Error #{task.name}, please set arg SYNC_DIR"
        end
      end
    end
  end

  # シンボリックリンク先のフォルダ の作成
  directory exposed_dir
end
