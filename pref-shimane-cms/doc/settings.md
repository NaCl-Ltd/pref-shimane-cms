# Settings.yml

Settings.ymlはpref-shimane-cmsの各種設定を管理する設定ファイルです。
本ドキュメントはSettings.ymlの設定変更について説明します。

## CMSサーバの設定
### CMSサーバのURIを変更する

下記設定を環境に合わせて変更して下さい。

```
    # CMSサーバのURI
    base_uri: 'http://localhost/'
    contents_uri: 'http://localhost/'
    # ローカルとして扱うドメイン
    local_domains:
      - localhost
      - localhost2
    # メール本文で用いるCMSサーバのURI
    mail:
      uri: 'http://localhost/'
```

## 公開サーバの設定
### 公開サーバのURIを変更する

下記設定を環境に合わせて変更して下さい。

```
    # 公開サーバのURI
    public_uri: 'http://localhost/'
    form_data_transfer:
      # 公開サーバのホスト名
      remote_host: localhost
    export:
      # 静的ページの同期先のホスト名
      servers:
        - localhost
      # アクセスカウンタの同期先のホスト名
      sync_counter_servers:
        - localhost
    counter:
      # アクセスカウンタ CGI の URI
      url: http://localhost/cgi-bin/pref-shimane-counter/
```

## メールの設定
### CMS管理者のメールアドレスを変更する

下記設定を環境に合わせて変更して下さい。

```
    super_user_mail: 'webmaster@localhost'
```

### ユーザのメールドメインに関する設定を変更する

下記設定を環境に合わせて変更して下さい。

```
    mail:
      # CMSで利用するメールアドレスのドメイン
      domain: 'example.com'
```

### メールマガジンで利用するドメインを変更する

下記設定を環境に合わせて変更して下さい。

```
    mailmagazine:
      domain: 'example.com'
```

### メールマガジンで使用するデフォルトの差出人を変更する

下記設定を環境に合わせて変更して下さい。

```
    mailmagazine:
      default_e_mail: 'example@localhost'
```

### SMTPサーバの設定

下記設定を環境に合わせて変更して下さい。

```
    mail_config:
      enable_starttls_auto: true
      address             : mail.localhost.localdomain
      domain              : localdomain
      port                : '25'
      authentication      : :plain
```

ここで設定したパラメータは ActionMailer::Base.smtp_settings に設定されます。

各パラメータについては ActionMailer::Base.smtp_settings をご確認ください。


## 所属の設定
### CMS管理者用の所属を変更する

下記設定を環境に合わせて変更して下さい。

```
    section:
      admin_code: '100000'
```

## データ回収の設定
### 公開サーバのアドレスを変更する

下記設定を環境に合わせて変更して下さい。

```
    form_data_transfer:
      remote_host: localhost
```

### データ回収用のユーザ(公開サーバ)を変更する

下記設定を環境に合わせて変更して下さい。

```
    form_data_transfer:
      remote_user: www-data
```

### データ回収コマンドを変更する

下記設定を環境に合わせて変更して下さい。

```
    form_data_transfer:
      # データを回収するコマンド
      command: /var/share/cms/tool/transfer_form_data
```

### データ復号化のGPGを変更する

下記設定を環境に合わせて変更して下さい。

```
    form_data_transfer:
      # GnuPG の home ディレクトリ
      gpg_homedir: /var/share/www/.gnupg

      # GnuPG コマンドのパスを指定します
      gpg_command: /usr/local/bin/gpg
```

### アンケート回答の回収の設定
#### アンケート回答の回収で使用する秘密鍵を変更する

下記設定を環境に合わせて変更して下さい。


```
    form_data_transfer:
      enquete:
        identity: /var/share/www/.ssh/id_rsa_enquete
```

#### 公開サーバ上のアンケート回答を保存するディレクトリを変更する

下記設定を環境に合わせて変更して下さい。


```
    form_data_transfer:
      enquete:
        data_dir: /var/share/cms/form_data/enquete
```

## アンケートの設定の
### アンケートページのURIを変更する

下記設定を環境に合わせて変更して下さい。

```
    enquete_uri: 'https://ssl.localhost/'
```

### アンケートの回答フォームのPOST先を変更する

下記設定を環境に合わせて変更して下さい。

```
    enquete:
      post_cgi_uri: https://localhost/cgi-bin-ssl/enquete.cgi
```

## アンケート管理機能の設定
### アンケート管理の削除条件数を変更する

下記設定を環境に合わせて変更して下さい。

```
    enquete:
      csv_conditions_form_count: 10
```

## ページコンテンツの設定
### ページコンテンツを挿入するdiv要素のID属性値を変更する

下記設定を環境に合わせて変更して下さい。

```
    page_content:
      wrapper_id: 'page-content'
```

**本設定値を変更した場合は assets の再コンパイルが必要になります**


### 公開履歴の保持数を変更する

下記設定を環境に合わせて変更して下さい。

```
    page_content:
      limit: 10
```

### 編集履歴の保持数を変更する

下記設定を環境に合わせて変更して下さい。

```
    page_revision:
      limit: 10
```

## 画像の設定
### 1ページにアップロードできる画像の合計サイズを変更する

下記設定を環境に合わせて変更して下さい。

```
    max_upload_image_total_size: <%= 3.megabyte %>
```

### アップロード可能な画像の最大サイズを変更する

下記設定を環境に合わせて変更して下さい。

```
    max_upload_image_size: <%= 300.kilobyte %>
```

## wysiwyg エディターの設定
### wysiwyg_editor で利用する要素のID属性を変更する

下記設定を環境に合わせて変更して下さい。

```
    wysiwyg_editor:
      body_id: 'content-wrapper'
```

### wysiwyg_editor で使用する要素にクラス属性を追加する

下記設定を環境に合わせて変更して下さい。

```
    wysiwyg_editor:
      body_class: 'sample-class'
```

## アクセシビリティチェックの設定
### アクセシビリティチェックの強制設定を変更する

下記設定を変更して下さい。

```
    page_content:
      unchecked: true
```

#### page_content.unchecked を false に変更する場合

ページコンテンツ保存前にアクセシビリティチェックを強制します


#### page_content.unchecked を true に変更する場合

下記のユーザはアクセシビリティチェックを実行しなくても
ページコンテンツが保存できるようになります

|対象ユーザ|
|----------|
|運用管理者権限を持つユーザ|
|アクセシビリティチェックのスキップ設定を行った所属に所属しているユーザ|

### michecker (アクセシビリティチェックを行うアプリケーション) との通信設定
#### 通信の暗号化の有無を変更する

下記設定を環境に合わせて変更して下さい。

```
    accessibility:
      https: false
```

#### micheker のアクセス先を変更する

下記設定を環境に合わせて変更して下さい。

```
    accessibility:
      host : localhost
      port : 8080
      api  : '/api/validate'
```

## 新着情報の設定
### 緊急情報のフォルダを変更する

下記設定を環境に合わせて変更して下さい。

```
    emergency_path: '/emergency/'
```

### 新着情報ページを変更する

下記設定を環境に合わせて変更して下さい。

```
    # 最新の新着情報
    top_news_page  : '/top_news.html'
    other_news_page: '/other_news.html'
    news_pages:
      bousai_info: '/bousai_news.html'
      life       : '/life_news.html'
      environment: '/environment_news.html'
      industry   : '/industry_news.html'
      infra      : '/infra_news.html'
      admin      : '/admin_news.html'

    # 過去の新着情報
    top_all_news_page  : '/all_top_news.html'
    other_all_news_page: '/all_other_news.html'
    all_news_pages:
      bousai_info: '/all_bousai_news.html'
      life       : '/all_life_news.html'
      environment: '/all_environment_news.html'
      industry   : '/all_industry_news.html'
      infra      : '/all_infra_news.html'
      admin      : '/all_admin_news.html'
```

### 新着情報から除外するフォルダにパスを変更する

下記設定を環境に合わせて変更して下さい。

```
    section_news:
      top:
        # top_news_page, top_all_news_page の新着情報の取得から除外するパス
        except:
          - '/bid_info/'

      other:
        # other_news_page, other_all_news_page の新着情報の取得から除外するパス
        except:
          - '/bousai_info/'
          - '/life/'
          - '/environment/'
          - '/industry/'
          - '/infra/'
          - '/admin/'
          - '/emergency/'
          - '/bid_info/'
```

## 公開ページの設定
### 公開ページで使用する asset のパスを変更する

下記設定を環境に合わせて変更して下さい。

```
    visitor_path: susanoo/visitors
```

### アップロードファイルの保存先を変更する

下記設定を環境に合わせて変更して下さい。

```
    visitor_data_path: <%= Rails.root.join('files', Rails.env) %>
```

## アクセスカウンタの設定
### CGI へのアクセス先を変更する

下記設定を環境に合わせて変更して下さい。

```
    counter:
      url: http://localhost/cgi-bin/pref-shimane-counter/

    export:
      sync_counter_servers:
        - localhost
```

### アクセスカウンタの保存先を変更する
#### CMSサーバ上

下記設定を環境に合わせて変更して下さい。

```
    counter:
      data_dir: counter
```

#### 公開サーバ上

下記設定を環境に合わせて変更して下さい。

```
    export:
      sync_counter_dir:　'/var/share/counter'
```

## Export の設定
### 公開ページの保存先を変更する

下記設定を環境に合わせて変更して下さい。

```
    export:
      docroot: <%= Rails.root.join('public.') %>
```

### ウェブモニタ一覧の保存先を変更する

下記設定を環境に合わせて変更して下さい。

```
    export:
      local_htpasswd_dir: <%= Rails.root.join('files/htpasswd/', Rails.env) %>
```

### 公開ページの同期設定
#### 同期するサーバを追加、削除する

下記設定を環境に合わせて変更して下さい。

```
    export:
      servers:
        - localhost
```

#### 同期先を変更する

下記設定を環境に合わせて変更して下さい。

```
    export:
      sync_dest_dir        : /var/www/cms
```

### アクセスカウンタの同期設定
#### 同期するサーバを追加、削除する

下記設定を環境に合わせて変更して下さい。

```
    export:
      sync_counter_servers:
        - localhost
```

#### 同期先を変更する

下記設定を環境に合わせて変更して下さい。

```
    export:
      sync_counter_dir: /var/share/counter/
```

### ウェブモニタ一覧の同期設定
#### 同期先を変更する

下記設定を環境に合わせて変更して下さい。

```
    export:
      public_htpasswd_dir: /var/www/htpasswd
```

## プラグインの設定
### ページコンテンツ編集画面の「プラグイン」項目にプラグインを追加する

下記設定を環境に合わせて変更して下さい。

```
    plugins:
      # ページコンテンツプラグイン
      contents:
        - page_list
        - genre_list
        - section_news
        - section_news_by_path
        - emergency
        - genre_down_list
        - genre_news_list
        - genre_news_list_truncate
        - section
        - section_top_list
        - sitemap
        - sub_genre_list
        - counter
```

###　ページコンテンツ編集画面の「プラグイン」項目から特定のプラグインを削除する

下記設定を環境に合わせて変更して下さい。

```
    plugins:
      hidden:
        - counter
```

### RSS用のプラグインとする

下記設定を環境に合わせて変更して下さい。

```
    plugins:
      rss:
        - news
        - genre_news_list
        - genre_news_list_truncate
        - dl_genre_news_list_truncate
        - section_news
        - section_news_by_path
```

## ウィルススキャンの設定
### アップロードするファイルにウィルススキャンを行う

下記の設定をアンコメントし、'fsav' をウィルススキャンコマンドに変更して下さい。

```
    #anti_virus:
    #  - 'fsav'
```
