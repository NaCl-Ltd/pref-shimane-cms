class AddColumnDeletableToGenres < ActiveRecord::Migration

  # マイグレーション限定のGenreモデルクラス
  class Genre < ActiveRecord::Base
  end

  def change
    add_column :genres, :deletable, :boolean, default: true

    Genre.reset_column_information
    Genre.where(path: "/").update_all(deletable: false)
  end
end
