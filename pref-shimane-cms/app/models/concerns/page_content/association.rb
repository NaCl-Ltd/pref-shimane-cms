module Concerns::PageContent::Association
  extend ActiveSupport::Concern

  included do
    RSS_REGEXP = /(plugin\('(?:#{Settings.plugins.rss.to_a.join('|')})')/

    #
    #=== トップニュースの状態
    #* :no      依頼しない
    #* :yes     依頼する
    #* :request 依頼中
    #* :reject  却下
    #
    @@top_news_status = {
      no: 0, yes: 1, request: 2, reject: 3
    }.with_indifferent_access

    #
    #=== 所属向けニュースの状態
    #* :no  依頼しない
    #* :yes 依頼する
    #
    @@section_news_status = {no: 0, yes: 1}.with_indifferent_access

    #
    #=== ページの公開状態
    # 公開中状態を公開開始日、公開終了日により状態を分ける
    #
    #* :editing 編集中
    #* :request 公開依頼中
    #* :reject  公開依頼却下
    #* :publish 公開中
    #* :cancel  公開停止
    #* :waiting 公開待ち DBには公開中状態(code=3)で保存される.begin_dateで判断
    #* :finished 公開期限切れ DBには公開中状態(code=3)で保存される. end_dateで判断
    #
    @@page_status = {
      editing: 0, request: 1, reject: 2,
      publish: 3, cancel: 4, waiting: 5, finished: 6
    }.with_indifferent_access

    @@page_status.each do |k, v|
      define_method("#{k}?") do
        self.admission == v
      end
    end

    #
    #=== 公開ステータス
    #
    @@public_status = [
      @@page_status[:publish],
      @@page_status[:cancel]
    ]

    #
    #=== 未公開ステータス
    #
    @@private_status = [
      @@page_status[:editing],
      @@page_status[:request],
      @@page_status[:reject]
    ]

    #
    #=== content カラムの書式バージョン
    # 旧CMSの場合は0が設定される
    #
    @@current_format_version = 1

    #
    #=== ローカルURI
    #
    @@local_uri = URI.parse("http://#{Settings.local_domains.first}")

    #
    #=== コンテンツ編集用のクラス
    #
    @@editable_class = {
      field:     'susanoo-editable-field',
      block:     'editable',
      heading:   'data-type-h',
      div:       'data-type-div',
      plugin:    'data-type-plugin',
      highlight: 'accessibility-error-highlight'
    }.with_indifferent_access

    cattr_reader :top_news_status, :section_news_status, :page_status,
      :private_status, :public_status, :current_format_version,
      :local_uri, :editable_class

    belongs_to :page, class_name: '::Page'
    has_many :links, class_name: "::PageLink", dependent: :destroy

    attr_reader :edit_style_content
  end
end
