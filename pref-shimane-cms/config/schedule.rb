# -*- coding: utf-8 -*-
# Use this file to easily define all of your cron jobs.
#
# It's helpful, but not entirely necessary to understand cron before proceeding.
# http://en.wikipedia.org/wiki/Cron

# Example:
#
# set :output, "/path/to/my/cron_log.log"
#
# every 2.hours do
#   command "/usr/bin/some_great_command"
#   runner "MyModel.some_method"
#   rake "some:great:rake:task"
# end
#
# every 4.days do
#   runner "AnotherModel.prune_old_records"
# end

# Learn more: http://github.com/javan/whenever

# cronの設定
#
#   $ bundle exec whenever --update-crontab
#
# cronの確認
#
#   $ bundle exec whenever
#

# nice付加メソッド
#   ブロック内のコマンドに nice コマンドを付加させます。
#
# 利用方法:
#
#   with_nice do
#     runner 'BrowsingSupport::ExportMp3.run'
#   end
def with_nice
  orig = job_template
  set :job_template, "nice #{orig}"
  yield
ensure
  set :job_template, orig
end

# 検証メソッド
#   指定したオプションを満たす時にプロセスを起動させます。
#
# 指定可能オプション
#   * lock
#     指定したロックファイルが存在しなければプロセスを起動させます
#
#   * exist
#     指定したファイルが存在すればプロセスを起動させます
#
# 利用方法:
#
#   with_validation(lock: '/tmp/export_mp3.lock') do
#     runner 'BrowsingSupport::ExportMp3.run'
#   end
def with_validation(options = {})
  orig = job_template

  if options[:lock]
    set :job_template, "test ! -e '#{options[:lock]}' && trap 'rm -f '\\''#{options[:lock]}'\\''' 0 1 2 3 15 && touch '#{options[:lock]}' && #{job_template}"
  end
  if options[:exist]
    set :job_template, "test -e '#{options[:exist]}' && #{job_template}"
  end

  yield
ensure
  set :job_template, orig
end

set :output, 'log/cron.log'
set :environment, :production

# export
every 1.minute do
  runner 'Susanoo::Export.new.run'
end

every 1.minute do
  # move_export
  runner 'Susanoo::MoveExport.new.run'

  # server_sync
  with_nice do
    with_validation(lock: '/tmp/server_sync.lock', exist: "#{Whenever.path}/do_sync") do
      runner 'Susanoo::ServerSync::Worker.run'
    end
  end
end

# export_all (土曜日の0:07)
every :saturday, :at => '0:07 am' do
  runner 'Susanoo::Export.new.all_page'
end

# export_mp3
every 1.minute do
  with_nice do
    with_validation(lock: '/tmp/export_mp3.lock') do
      runner 'BrowsingSupport::ExportMp3.run'
    end
  end
end
#
# RAILS_ENV=production ./vendor/engines/browsing_support/bin/export_mp3
#

# 一括ページ取り込み import_all (classic)
#1   0 * * * /var/share/cms/tool/import_all
every :day, :at => '0:01 am' do
  runner 'Classic::ImportPage::Importer.run'
end

# 一括ページ取り込み import_all (susanoo)
#1   0 * * * /var/share/cms/tool/import_all
every :day, :at => '1:01 am' do
  runner 'ImportPage::Importer.run'
end

# アンケート取得
every 42.minute do
  runner 'EnqueteAnswer.retrieve_form_data'
end

# バナー広告の期限切れチェック(毎日0:16)
every :day, :at => '0:16 am' do
  runner 'Advertisement.send_expired_advertisement_mail'
end

# ページのリンクチェック(土曜日の21:04）
every :saturday, :at => '21:04 pm' do
  runner 'LostLink.check_all_links'
end

# アクセスログの取り込み
every :day, :at => '0:10 am' do
  runner 'AccessStatistics::ApacheLog.new.analyze'
end

# セッションの消去
every :day, :at => '3:00 am' do
  runner 'ActiveRecord::SessionStore::Session.delete_all(["updated_at <= ?", 1.days.ago])'
end

# イベント関係のプラグインが挿入されているページを更新
every :day, :at => '3:10 am' do
  runner 'Susanoo::Export.new.create_page_for_event_referers'
end
