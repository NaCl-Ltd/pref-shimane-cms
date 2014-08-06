#
# genresテーブルでnoがnullのレコードにnoをセットする
#
namespace :genres do
  task set_no: :environment do
    top_genre = Genre.find_by_path('/')
    ActiveRecord::Base.connection.execute("UPDATE genres SET no = 1 WHERE id = #{top_genre.id}")

    Genre.where("parent_id = ?", top_genre.id).order("name ASC").each_with_index do |genre, count|
      ActiveRecord::Base.connection.execute("UPDATE genres SET no = #{count + 1} WHERE id = #{genre.id}")
      set_no(genre)
    end

  end
end

def set_no(genre)
  if genre.has_children?
    Genre.where("parent_id = ?", genre.id).order("name ASC").each_with_index do |genre2, count2|
      ActiveRecord::Base.connection.execute("UPDATE genres SET no = #{count2 + 1} WHERE id = #{genre2.id}")
      set_no genre2
    end
  end
end