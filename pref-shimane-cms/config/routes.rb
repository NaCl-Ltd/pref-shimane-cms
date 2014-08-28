# -*- coding: utf-8 -*-
PrefShimaneCms::Application.routes.draw do
  get '/_admin/' => redirect('/classic/users/login')
  get '/_admin/login' => redirect('/classic/users/login')

  root to: 'susanoo/visitors#view'

  get 'susanoo', to: 'susanoo/users#login'

  # Susanoo コア機能
  namespace :susanoo do
    resources :visitors, only: [] do
      collection do
        get :attach_file
        get :preview_virtual
        patch :preview_virtual
      end

      member do
        get :preview
        get :show_mobile_revision_page
      end
    end

    # ユーザ管理機能
    resources :users do
      member do
        # ログアウト
        delete :logout
      end

      collection do
        # ログイン画面表示
        get  :login

        # ログイン処理
        post :authenticate
      end
    end

    # ダッシュボード（トップページ）
    resources :dashboards, only: %w(index)

    # フォルダ管理機能
    resources :genres do
      member do
        # フォルダ移動
        get :move

        # フォルダコピー
        get :copy

        # 順番変更
        get :move_order

        # サイト構造のCSVダウンロード
        get :csv_download
      end

      collection do
        # ツリービューのJSONデータ取得
        get :treeview

        # フォルダ選択
        get :select_genre

        # フォルダ・ページ選択
        get :select_resource

        # 部局選択
        get :select_division

        # ツリービューとページのJSONデータ取得
        get :treeview_with_pages
      end

      # アクセス制限機能
      resources :web_monitors do
        collection do
          delete :destroy_all
          post   :import_csv
          patch  :reflect
          patch  :update_auth
        end
      end
    end

    # ページ管理機能
    resources :pages do
      member do
        get :move
        get :revisions
        get :histories
        get :reflect
        delete :private_page_unlock
      end

      collection do
        get :select
        get :content
        get :select_copy_page
      end
    end

    # ページ管理機能
    resources :page_contents do
      collection do
        get :cancel
        get :content
        post :check
        post :preview
        post :convert
        post :direct_html
      end

      member do
        get :cancel_request
        get :edit_private_page_status
        patch :update_private_page_status
        get :edit_public_page_status
        patch :update_public_page_status
        get :destroy_public_term
      end
    end

    resources :helps, only: [:index, :show] do
      collection do
        get :treeview
        post :search
      end
    end

    resources :page_assets, only: [] do
      collection do
        get :images
        get :attachment_files
        delete :destroy
        post :upload_image
        post :upload_attachment_file
      end
    end

    resources :infos, only: [:show]

    # 運用管理者のみアクセスできる機能
    namespace :admin do
      #ユーザ管理機能
      resources :users

      # 所属管理機能
      resources :sections, except: [:show] do
        collection do
          post :update_sort
        end
      end

      # 部局管理機能
      resources :divisions, except: [:show] do
        collection do
          post :update_sort
        end
      end

      #お知らせ管理機能
      resources :infos

      #緊急お知らせ管理機能
      resources :emergency_infos, only: [:create, :update] do
        collection do
          get :edit
          patch :update
          patch :stop_public
        end
      end

      # ヘルプ管理機能
      resources :helps, except: [:destory] do
        collection do
          post :update_sort
          post :save_caption
          get :configure
          get :edit_caption
          get :action_configure
          get :edit_action
          post :save_action
        end

        member do
          get :caption_change_public
          delete :destroy_caption
          delete :destroy_action
        end
      end

      # ヘルプカテゴリ管理機能
      resources :help_categories, except: [:show] do
        collection do
          get :treeview
          post :update_sort
          get :help_list
        end

        member do
          get :change_navigation
        end
      end

      resources :help_content_assets, only: :show do
        collection do
          get :images
          get :attachment_files
          delete :destroy
          post :upload_image
          post :upload_attachment_file
        end
      end

      # オプション管理機能
      resources :engines, only: [:index] do
        member do
          get :change_state
        end
      end

      # テンプレート管理機能
      resources :page_templates do
        collection do
          get :cancel
          get :content
          post :check
          post :preview
          post :convert
          post :direct_html
        end

        member do
          get :edit_content
          patch :update_content
        end
      end
    end

    # 情報提供管理者、運用管理者がアクセスできる機能
    namespace :authorizer do

    end
  end

    # 閲覧支援機能
  mount BrowsingSupport::Engine => '/browsing_support' if defined? BrowsingSupport::Engine

  # 連絡先設定機能
  mount SectionInfoConfigure::Engine => '/section_info_configure' if defined? SectionInfoConfigure::Engine

  # 広告管理機能
  mount AdvertisementManagement::Engine => '/advertisement_management' if defined? AdvertisementManagement::Engine

  # ブログ管理機能
  mount BlogManagement::Engine => '/blog_management' if defined? BlogManagement::Engine

  # 相談窓口機能
  mount ConsultManagement::Engine => '/consult_management' if defined? ConsultManagement::Engine

  # イベントカレンダー管理機能
  mount EventCalendar::Engine => '/event_calendar' if defined? EventCalendar::Engine

  # 一括ページ取り込み機能
  mount ImportPage::Engine => '/import_page' if defined? ImportPage::Engine

  #リンク切れチェック機能
  mount LostLinkCheck::Engine => '/lost_link_check' if defined? LostLinkCheck::Engine

  class ClassicPageConstraints
    def matches?(request)
      path = request.path

      if path =~ %r!\A/(news\.(\d+))\.html!
        return true
      elsif Classic::EventCalendar.event_display_page?(path)
        if genre = Genre.find_by(path: '/event_calendar/')
          return genre.section.classic?
        end
      end

      page_view = Susanoo::PageView.new(path)

      if page = page_view.page
        return page.section.try(:classic?)
      end
    end
  end

  class AttachFileConstraints
    def matches?(request)
      if request.path =~ /\A\/(.+)\.data\//
        return true
      elsif request.path =~ /^\/images\//
        return true
      elsif request.path =~ /^\/stylesheets\//
        return true
      elsif request.path =~ /^\/javascripts\//
        return true
      end
      return false
    end
  end

  get '*path', to: 'susanoo/visitors#attach_file', constraints: AttachFileConstraints.new
  get '*path', to: 'susanoo/visitors#view'
  get '*path', to: 'classic/visitors#view', constraints: ClassicPageConstraints.new
end
