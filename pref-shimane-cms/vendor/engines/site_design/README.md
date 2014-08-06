= SiteDesign

This project rocks and uses MIT-LICENSE.

本エンジンはpref-shimane-cmsのデザインテンプレートを提供します。

目次

* 既存のデザインテンプレートの種類
* テンプレートの変更方法
* 辞書ファイルについて
* 各変数について
* デフォルトデザインについて

----


= 既存のデザインテンプレートの種類

下記のテンプレートを提供しています。

* トップ
* カスタム
* ノーマル（通常ページ）
* BlogManagementエンジン用テンプレート
* EventCalendarエンジン用テンプレート

== トップテンプレート

適用されるURL: /index.html
参照されるテンプレート: app/views/susanoo/visitors/top/show.html

== カスタムテンプレート

適用されるURL: /custom/ 以下
参照されるテンプレート: app/views/susanoo/visitors/custom/show.html

== ノーマルテンプレート

適用されるURL: 上記に当てはまらない通常ページ
参照されるテンプレート: app/views/susanoo/visitors/top/show.html

== BlogManagementエンジン用テンプレート

適用されるURL: ブログページ
参照されるテンプレート: app/views/susanoo/visitors/blog_management/show.html

== EventCalendarエンジン用テンプレート

適用されるURL: イベントページ
参照されるテンプレート: app/views/susanoo/visitors/event_calendar/show.html

----


= テンプレートの変更方法

上記テンプレートの変更は、参照されるテンプレートのファイルを修正してください。

* あるフォルダ以下に適用したいデザインがある
* あるページに限り適用したいデザインがある

等でデザインテンプレートを増やしたい場合は、適当な処理/ファイルを追加する必要があります。

ページ(html)が作成される際に、lib/site_design/susanoo/page_view.rb 中のset_templateメソッドが呼ばれます。このメソッドに処理を追加して、適当なテンプレートを返すようにしてください。

----


= 辞書ファイルについて

デザインのヘッダーやフッターでは、「pref-shimane-cms」などの表示を行っていますが、この文言は辞書ファイルに定義されています。このファイルを編集することで変更可能です。

config/locales/ja.visitors.yml

---


= 各変数について

views等で次の変数を使用しています。ご参考ください。

@engine_name: String
  エンジン提供の機能がviewsを呼び出している場合に、エンジン名が格納されています。例："blog_management"

@page_view: PageViewクラスのインスタンス
  ページのリソース(page, genre)が格納されています。例えば、@page_view.page.name でページ名を取得できます。

@preview: TrueClass
  viewsを表示している状態がプレビューのときに格納される。


== AdvertisementManagementエンジンに係る変数

@corp_ads: Array
  公開中の企業広告データの配列。トップページで企業広告一覧を表示する際に使用。

@pref_ads: Array
  公開中のPR広告データの配列。トップページでPR広告一覧を表示する際に使用。


== BlogManagementエンジンに係る変数

@blog_layout: String
  ページのレイアウトの種類を格納。 "top_index_layout", "year_index_layout", "month_index_layout"等。

@prev_month_blog_genre: String
  前月のフォルダ名。（前月にブログページがなければnil）

@next_month_blog_genre: String
  次月のフォルダ名。（次月にブログページがなければnil）

@month_blog_pages: Array
  当月のブログページ(page)を格納。日付をインデックスとして、ページがなければnil。
@blog_pages_with_content: Array
  直近のブログページ([page, content])を格納。


== EventCalendarエンジンに係る変数

@calendar_year: Integer
  イベントカレンダー表示用の変数。 表示する年を格納。

@calendar_month: Integer
  イベントカレンダー表示用の変数。 表示する月を格納。

----


= デフォルトデザインについて

== ヘッダー

　辞書管理（ふりがな、音声合成）機能を有効化することで、ヘッダに読み上げボタンやふりがなボタンなどが表示されます。
　広告管理機能を有効化することで、トップページ以外のページでは、企業広告がランダムに１つ表示されます。

==フッター

　連絡先設定機能を有効化すると、そのページを作成した所属へのお問合せ先が表示されます。

== トップページ

　広告管理機能を有効化すると、画面上部にトップ広告、画面下部に企業広告とPR広告が表示されます。

== カスタムページ

　通常デザイン以外のページのサンプルです。２段組みのレイアウトで表示されます。左カラムはページの一覧を表示するプラグインを使用しています。

----

