# BrowsingSupport

This project rocks and uses MIT-LICENSE.

# セットアップ

音声合成エンジン Open Jtalk と MP3エンコーダ lame 、辞書のセットアップを
行います。

下記バージョンで動作確認を行っています。

* Open Jtalk : 1.07
* hts_engine API : 1.08
* MMDAgent_Example : 1.4
* lame : 3.99.5


## Open Jtalk のセットアップ
Open Jtalk のソースコードをダウンロードし、セットアップします。
また、Open Jtalk のセットアップには hts_engine API が必要になりますので、
併せてダウンロードします。


### ダウンロード
下記のサイトから最新バージョンをダウンロードし、<SUSANOO_ROOT>/vendor/src
に配置します。

* Open Jtalk     : http://open-jtalk.sourceforge.net/
* hts_engine API : http://hts-engine.sourceforge.net/


### コンパイル
#### hts Engine API

```
$ mkdir <SUSANOO_ROOT>/vendor/src
$ cd <SUSANOO_ROOT>/vendor/src
$ tar xzf hts_engine_API-<version>.tar.gz
$ cd hts_engine_API-<version>/
$ ./configure
$ make
$ cd ../
$ ln -s hts_engine_API-<version> hts_engine_API
```

#### Open Jtalk

```
$ tar xzf open_jtalk-<version>.tar.gz
$ cd open_jtalk-<version>
$ ./configure \
    --with-hts-engine-header-path=$(dirname $(pwd))/hts_engine_API/include \
    --with-hts-engine-library-path=$(dirname $(pwd))/hts_engine_API/lib \
    --with-charset=utf-8
$ make
$ cd ../
$ ln -s open_jtalk-<version> open_jtalk
```

### htsvoice ファイルのダウンロード、配置
#### htsvoice ファイルのダウンロード

下記サイトから最新バージョンの MMDAgent_Example をダウンロードし、SUSANOO_ROOT/vendor/htsvoices に配置します。

* http://sourceforge.net/projects/mmdagent/files/MMDAgent_Example/

#### htsvoice ファイルの配置

```
$ mkdir <SUSANOO_ROOT>/vendor/htsvoices
$ cd <SUSANOO_ROOT>/vendor/htsvoices
$ unzip MMDAgent_Example-<version>.zip
$ ln -s MMDAgent_Example-<version>/Voice/mei/mei_normal.htsvoice htsvoice
```

## Lame のセットアップ
lame のソースコードをダウンロードし、セットアップします。

### ダウンロード

下記サイトから最新バージョンをダウンロードし、
<SUSANOO_ROOT>/vendor/src に配置します。

http://sourceforge.net/projects/lame/files/lame/


### コンパイル

```
$ cd <SUSANOO_ROOT>/vendor/src
$ tar xzf lame-<version>.tar.gz
$ cd lame-<version>
$ ./configure
$ make
$ cd ../
$ ln -s lame-<version> lame
```


## 辞書の配置

SUSANOO_ROOT/vendor/engines/browsing_support/files/{production,development,test} に
辞書を配置します。

```
$ mkdir -p <SUSANOO_ROOT>/vendor/engines/browsing_support/files/{production,development,test}
$ cp -r <SUSANOO_ROOT>/vendor/src/open_jtalk/mecab-naist-jdic <SUSANOO_ROOT>/vendor/engines/browsing_support/files/production/dic
$ cp -r <SUSANOO_ROOT>/vendor/src/open_jtalk/mecab-naist-jdic <SUSANOO_ROOT>/vendor/engines/browsing_support/files/development/dic
$ cp -r <SUSANOO_ROOT>/vendor/src/open_jtalk/mecab-naist-jdic <SUSANOO_ROOT>/vendor/engines/browsing_support/files/test/dic
```

### dicrc の配置

下記サイトから辞書をダウンロード、解凍し、dicrc ファイルを
SUSANOO_ROOT/vendor/engines/browsing_support/files/{production,development,test} に
配置します。

http://sourceforge.jp/projects/naist-jdic/

```
$ cd <SUSANOO_ROOT>/vendor/src
$ tar xzf mecab-naist-jdic-<version>.tar.gz
$ cd mecab-naist-jdic-<version>
$ cp dicrc <SUSANOO_ROOT>/vendor/engines/browsing_support/files/production/dic
$ cp dicrc <SUSANOO_ROOT>/vendor/engines/browsing_support/files/development/dic
$ cp dicrc <SUSANOO_ROOT>/vendor/engines/browsing_support/files/test/dic
```


## MeCab のセットアップ
### MeCab のダウンロード

下記サイトからOpen Jtalkで使用されているMeCabと同じバージョンのMeCabと
mecab-rubyをダウンロードします。
(Open Jtalk 1.07の場合は0.994のMeCab, mecab-ruby をダウンロードします)

http://code.google.com/p/mecab/downloads/list

MeCabe をダウンロードしましたら、SUSANOO_ROOT/vendor/src に配置します。


### MeCab のコンパイル

SUSANOO_ROOT/vendor/srcにあるMeCabのソースコードを解凍し、コンパイルします。

```
$ cd <SUSANOO_ROOT>/vendor/src
$ tar xzf mecab-<version>.tar.gz
$ cd mecab-<version>
$ ./configure --enable-utf8-only --with-charset=utf8
$ make
$ cd ../
$ ln -s mecab-<version> mecab
```

# pref-shimane-cmsに適用

pref-shimane-cmsで使用するために、下記の操作を行います。

* Gemfile の修正
* マイグレーション
* オプション管理の設定
* 定期実行処理の追加


## Gemfile の修正

SUSANOO_ROOT/Gemfile の下記コメントを外してください。

```
#gem 'browsing_support', path: 'vendor/engines/browsing_support'
```

外した後、bundle install を行います。

```
$ cd <SUSANOO_ROOT>
$ bundle install --without development test
```

## マイグレーション

```
$ rake railties:install:migrations
$ rake db:migrate RAILS_ENV=production
```

システムを再起動してください。

## オプション管理の設定

pref-shimane-cmsのメニューから、各種設定の項目「オプション管理」を選択して、「辞書管理（ふりがな、音声合成）」を有効にしてください。

## 定期実行処理の追加

mp3ファイルを作成、公開側に設置するためには、下記の処理が必要です。crontab等で定期的に実行してください。実行間隔はサンプルです。

```
* * * * * test ! -e '/tmp/export_mp3.lock' && trap 'rm -f '\''/tmp/export_mp3.lock'\''' 0 1 2 3 15 && touch '/tmp/export_mp3.lock' && nice /bin/bash -l -c 'cd /var/share/susanoo && bin/rails runner -e production '\''BrowsingSupport::ExportMp3.run'\'' >> log/cron.log 2>&1'
```

