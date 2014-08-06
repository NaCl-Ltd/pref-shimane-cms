
pref-shimane-cms(バージョン 2.0.0) インストール説明書
====
本ドキュメントはpref-shimane-cms(バージョン 2.0.0)をセットアップのための環境および手順について説明します。
*既存のシステムにインストールされる場合は、十分に気をつけて作業を行ってください。*
**本手順書により生じたいかなる損失について当方では責任を負えません。**

最終更新日：2014/7/1


動作環境
====
Debian GNU/Linux wheezy

* Ruby 2.1.0
* jruby-1.7.5
* PostgreSQL 9.1

Debian パッケージ
----
* python
* libpq-dev
* libmagickwand-dev
* g++
* build-essential
* openssl
* libreadline6
* libreadline6-dev
* curl
* git-core
* zlib1g
* zlib1g-dev
* libssl-dev
* libyaml-dev
* libxml2-dev
* libxslt-dev
* autoconf
* libc6-dev
* ncurses-dev
* automake
* libtool
* bison

上記パッケージをインストールします
```
$ sudo apt-get install python libpq-dev libmagickwand-dev g++ build-essential openssl libreadline6 libreadline6-dev curl git-core zlib1g zlib1g-dev libssl-dev libyaml-dev libxml2-dev libxslt-dev autoconf libc6-dev ncurses-dev automake libtool bison
```

1. pref-shimane-cmsのセットアップ
====

1.1. gemのインストール
----
pref-shimane-cmsでは、gemの依存管理に Bundler を使用しています。
```
$ cd <CMS_ROOT>
$ gem install bundler
$ bundle install --without development test
```
CMS_ROOTはpref-shimane-cmsを配置したフォルダになります（以下同様です）。

CMS_ROOTでは、.ruby_versionで2.1.0を指定しております。bundle install時に、2.1.0のgemが対象になっているようご注意ください。


1.2. データベースのセットアップ
----
pref-shimane-cmsで接続するアカウントに対して、テーブルの作成権限を追加してください。
デフォルトでは、susanooユーザを使用します。
```
$ cd <CMS_ROOT>
$ cp config/database.yml.sample config/database.yml
$ rake db:create RAILS_ENV=production
$ rake railties:install:migrations
$ rake db:migrate RAILS_ENV=production
$ rake db:fixtures:load RAILS_ENV=production
```


1.3. 公開サイトのデザイン設定
----
SiteDesignエンジンで公開サイトのデザインを行っています。
pref-shimane-cmsのページコンテンツ編集画面でも同様のデザインが適用されるように、下記の操作を行います。
```
$ cd <CMS_ROOT>
$ sudo ln -s <CMS_ROOT>/vendor/engines/site_design/app/assets/images/susanoo/visitors public/images
$ sudo ln -s <CMS_ROOT>/vendor/engines/site_design/app/assets/javascripts/susanoo/visitors public/javascripts
$ sudo ln -s <CMS_ROOT>/vendor/engines/site_design/app/assets/stylesheets/susanoo/visitors public/stylesheets
```

1.4. 管理画面で使用するJavaScript、CSS、画像ファイルのセットアップ
----

```
$ cd <CMS_ROOT>
$ rake assets:precompile
```


1.5. 起動と動作確認
----
pref-shimane-cmsの起動を行います。ここでは公開側Webサーバ(port 80)との一台構成を想定し、8000番を使用します。

```
$ cd <CMS_ROOT>
$ rails server -p 8000 -e production
```

下記の初期ユーザが登録済みです。

```
ユーザID : admin

パスワード : password
```

1.6. pref-shimane-cmsの基本設定
----
config/settings.local.yml.sampleにpref-shimane-cmsを動かすための基本的な設定がまとめてあります。環境に合わせて設定してください。

```
$ cp <CMS_ROOT>/config/settings.local.yml.sample <CMS_ROOT>/config/settings.local.yml
```

1.7. pref-shimane-cms で使用している定数について
----
pref-shimane-cmsでは定数をgemのrails_confで管理しています。詳しくは、doc/settings.md をご参照ください。

1.8. 本番環境の設定
----
本番環境では、Phusion Passenger等を使用して動かします。  （推奨）
環境構築の詳細は以下のURLを参照してください。

https://www.phusionpassenger.com/

   　
2. pref-shimane-checkerのセットアップ
====
pref-shimane-checkerは、JIS X 8341-3:2010のAA基準に基づいたアクセシビリティをチェックするための機能です。
jrubyを使用してRailsアプリケーションとして動かし、pref-shimane-cmsからアクセスを行います。
pref-shimane-cmsのページコンテンツ編集画面では本アプリケーションによるアクセシビリティチェック実施後にページコンテンツの保存が可能になります。

2.1. セットアップと起動確認
----
```
$ cd /var/share/<CHECKER_ROOT>
$ gem install bundler
$ bundle install --without development test
$ rails server -p 8080 -e production
```
CHECKER_ROOTはpref-shimane-cmsを配置したフォルダになります（以下同様です）

CHECKER_ROOTでは、.ruby_versionファイルでjruby-1.7.5を指定しております。
bundle install時に、jruby-1.7.5のgemが対象になっているようご注意ください。


2.2. 本番環境の設定
----
本番環境では、warファイルを作成しTomcat等を使用します（推奨）。

```
$ cd /var/share/<CHECKER_ROOT>
$ warble
作成された michecker.war をTomcat等のWebコンテナへ配置
```

----

以上で、pref-shimane-cmsの管理機能を使用できます。ぜひ、お試しください。



補足事項1 : サイトの公開について
====
実際にCMSで作成されたファイルを公開される場合は、doc/publishing.md をご参照ください。


補足事項2 : サイトデザインについて
====
pref-shimane-cmsのサイトデザインは、SiteDesignエンジンで行っています。スタイルの変更等のデザイン変更は、SiteDesignエンジンを修正することで行えます。
詳しくは、vendor/engine/site_design/README.md をご参照ください。


