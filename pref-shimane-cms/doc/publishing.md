
pref-shimane-cms(バージョン 2.0.0) 公開手順説明書
====
本ドキュメントはpref-shimane-cms(バージョン 2.0.0)で作成したページをhtmlに出力する設定や、公開のための環境および手順について説明します。


1. Exportのセットアップ
====
pref-shimane-cmsでは、Exportとよばれる処理によって、htmlファイル等の公開側に置くファイルを作成します。ここでは、Export処理の設定、公開側フォルダにファイルを転送する設定を行います。

以降は下記の条件でのセットアップ手順になります。

* pref-shimane-cmsの実行ユーザ：www-data
* 公開フォルダ：/var/www/cms


1.1. Export先フォルダ作成
----
pref-shimane-cmsがhtmlファイル等を出力するフォルダを作成します。このフォルダにあるファイルは公開フォルダへコピーされます。

```
$ mkdir <CMS_ROOT>/public.
$ sudo ln -s <CMS_ROOT>/vendor/engines/site_design/app/assets/images/susanoo/visitors public./images
$ sudo ln -s <CMS_ROOT>/vendor/engines/site_design/app/assets/javascripts/susanoo/visitors public./javascripts
$ sudo ln -s <CMS_ROOT>/vendor/engines/site_design/app/assets/stylesheets/susanoo/visitors public./stylesheets
```


1.2. 公開鍵の作成
----
公開フォルダへのコピーはrsyncを使用して行うため、公開鍵の作成および設定を行います。なお、ここでは１台構成を想定していますが、公開フォルダを別サーバにすることでpref-shimane-cms（アプリケーションサーバ）と公開サーバを分離できます。

```
$ sudo mkdir -m 700 ~www-data/.ssh
$ sudo chown www-data:www-data ~www-data/.ssh
$ sudo -u www-data ssh-keygen -t rsa -N '' -f ~www-data/.ssh/id_rsa
$ sudo -u www-data bash -c "cat ~www-data/.ssh/id_rsa.pub >> ~www-data/.ssh/authorized_keys"
$ sudo -u www-data ssh localhost #<= 動作確認です
$ exit
```


1.3. 公開フォルダ作成と初期ファイルの転送
----

```
$ mkdir /var/www/cms
$ sudo chown www-data:www-data /var/www/cms
$ sudo -u www-data rsync -aLz <CMS_ROOT>/public./ /var/www/cms/
```


1.4. HTMLの作成と確認
----

```
$ cd <CMS_ROOT>
$ touch do_export
$ rails runner -e production 'Susanoo::Export.new.all_page'
$ rails runner -e production 'Susanoo::Export.new.run'
$ ls public./index.html*
HTML ファイルが作成されていること
```


1.5. 公開フォルダへの転送と確認
----

```
$ cd <CMS_ROOT>
$ touch do_sync
$ rails runner -e production 'Susanoo::ServerSync::Worker.run'
$ ls -l /var/www/cms/
public./* 以下に作成されたファイルがコピーされていること
```


2. 定期実行処理の設定
====
上記のExport処理などはcron等で定期的に実行する必要があります。

※下記は、定期実行を行う処理の例です。お使いの環境にあう設定を行ってください。特に実行間隔については、マシンによって処理が重くなる可能性がありますのでご注意ください。

```
# Susanoo::Export.new.run
* * * * * /bin/bash -l -c 'cd /var/share/pref-shimane-cms && bin/rails runner -e production '\''Susanoo::Export.new.run'\'' >> log/cron.log 2>&1'

# Susanoo::MoveExport.new.run
* * * * * /bin/bash -l -c 'cd /var/share/pref-shimane-cms && bin/rails runner -e production '\''Susanoo::MoveExport.new.run'\'' >> log/cron.log 2>&1'

# Susanoo::ServerSync::Worker.run
* * * * * test -e '/var/share/pref-shimane-cms/do_sync' && test ! -e '/tmp/server_sync.lock' && trap 'rm -f '\''/tmp/server_sync.lock'\''' 0 1 2 3 15 && touch '/tmp/server_sync.lock' && nice /bin/bash -l -c 'cd /var/share/pref-shimane-cms && bin/rails runner -e production '\''Susanoo::ServerSync::Worker.run'\'' >> log/cron.log 2>&1'

# Susanoo::Export.new.all_page
7 0 * * 6 /bin/bash -l -c 'cd /var/share/pref-shimane-cms && bin/rails runner -e production '\''Susanoo::Export.new.all_page'\'' >> log/cron.log 2>&1'

# SessionStore::Session.delete_all
0 3 * * * /bin/bash -l -c 'cd /var/share/pref-shimane-cms && bin/rails runner -e production '\''ActiveRecord::SessionStore::Session.delete_all(["updated_at <= ?", 1.days.ago])'\'' >> log/cron.log 2>&1'
```

また、オプション管理で下記機能を有効にされている場合は、該当する処理を追加してください。


リンク切れチェック

```
4 21 * * 6 /bin/bash -l -c 'cd /var/share/pref-shimane-cms && bin/rails runner -e production '\''LostLink.check_all_links'\'' >> log/cron.log 2>&1'
```

一括ページ取り込み

```
1 1 * * * /bin/bash -l -c 'cd /var/share/pref-shimane-cms && bin/rails runner -e production '\''ImportPage::Importer.run'\'' >> log/cron.log 2>&1'
```

広告管理

```
16 0 * * * /bin/bash -l -c 'cd /var/share/pref-shimane-cms && bin/rails runner -e production '\''Advertisement.send_expired_advertisement_mail'\'' >> log/cron.log 2>&1'
```

イベントカレンダー管理

```
10 3 * * * /bin/bash -l -c 'cd /var/share/pref-shimane-cms && bin/rails runner -e production '\''Susanoo::Export.new.create_page_for_event_referers'\'' >> log/cron.log 2>&1'
```


3. 公開ページのルビ振り、ページ読み上げについて
====
pref-shimane-cmsでは、BrowsingSupportエンジンを利用することで通常のhtmlファイルの他にルビ振りページや、ページの読み上げファイル(mp3)を、自動で作成することができます。
詳しくは、vendor/engine/browsing_support/README.md をご参照ください。

