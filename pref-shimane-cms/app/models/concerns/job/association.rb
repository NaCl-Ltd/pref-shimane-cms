module Concerns::Job::Association
  extend ActiveSupport::Concern

  included do
    CREATE_PAGE = "create_page"
    CANCEL_PAGE = "cancel_page"
    DELETE_PAGE = "delete_page"

    CREATE_GENRE = "create_genre"

    MOVE_FOLDER = 'move_folder'
    MOVE_PAGE = 'move_page'

    REMOVE_ATTACHMENT = "remove_attachment"
    ENABLE_REMOVE_ATTACHMENT = "enable_remove_attachment"

    CREATE_EVENT_DISPLAY_PAGE = 'create_event_display_page'

    # フォルダのアクセス制限を作成するジョブ
    CREATE_HTACCESS = 'create_htaccess'

    # フォルダのアクセス制限を削除するジョブ
    DESTROY_HTACCESS = 'destroy_htaccess'
  end
end
