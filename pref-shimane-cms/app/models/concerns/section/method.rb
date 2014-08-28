module Concerns::Section::Method
  extend ActiveSupport::Concern

  included do
    CONTENTS_PATH = /\A\/contents\//

    Settings.section.features.each do |name, value|
      define_method("#{name}?") do
        self.feature == Settings.section.features[name]
      end
    end

    #
    #=== 所属のトップフォルダの作成
    #
    def add_new_genre(name)
      new_genre = Genre.top_genre.children.new(name: name, title: self.name)
      new_genre.section_id = self.id
      if new_genre.save
        self.assign_genre(new_genre.id)
        Job.create(action: ::Job::CREATE_GENRE, arg1: new_genre.id.to_s)
        return true
      else
        self.errors.add(:base, new_genre.errors.full_messages.join("\n"))
        return false
      end
    end

    #
    #=== selfに対してフォルダを割り当てる.
    #
    def assign_genre(genre_id)
      self.top_genre_id = genre_id
      self.save
    end

    #
    #=== 機能のキー名を取得する.
    #
    def feature_key
      Settings.section.features.each do |name, value|
        return name if value == feature
      end
    end

    #
    #=== コンテンツ表示に使用するページテンプレート名を返す
    #
    def template
      return 'show'
    end

    #
    #=== 所属を新規作成する
    #
    def create_new_section(genre_params = {})
      max = Section.where(division_id: division_id).maximum(:number)
      self.top_genre_id = nil
      self.number  = (max.nil?) ? 1 : max + 1

      return false unless self.valid?

      result = true
      begin
        self.transaction do
          self.save!
          if genre_params[:name].present?
            unless self.add_new_genre(genre_params[:name])
              result = false
              self.destroy
            end
          else
            if !genre_params[:id].to_i.zero?
              self.assign_genre(genre_params[:id].to_i)
            end
          end
        end
      rescue => e
        self.errors.add(:base, I18n.t('activerecord.errors.messages.unexpected'))
        logger.fatal(%Q!#{$!} : #{$@.join("\n")}!)
        result = false
      end
      result
    end

    #
    #=== ルートフォルダの権限を持つ所属かどうかを返す
    #
    def super_section?
      @_super_section ||= Section.super_section
      id == @_super_section.id
    end

    #
    #=== 所属が持つフォルダ、ページの一覧をCSV形式で抽出する
    #
    def generate_pages_csv
      csv_string = ""
      csv = CSV.new(csv_string, encoding: 'Windows-31J')
      self.genres.order("path").each do |genre|
        # フォルダ
        str = []
        str_count = 0
        genre.ancestors.sort_by { |d| d.path}.each do |g|
          title = !g.title.nil? ? g.title : "フォルダタイトル不明"
          str << title
          str_count += 1
        end
        title = !genre.title.nil? ? genre.title : "フォルダタイトル不明"
        str << title
        csv << str
        # ページ
        genre.pages.sort.each do |page|
          str2 = []
          1..(str_count + 1).times do |b| str2 << "" end
          title = !page.title.nil? ? page.title : "ページタイトル不明"
          str2 << title
          csv << str2
        end
      end
      return NKF::nkf('-Ws', csv.string)
    end

  end

  module ClassMethods
    #
    #=== ルートフォルダの権限を持つ所属を返す
    #
    def super_section
      Section.where(code: Settings.section.admin_code).first
    end

    #
    #=== ルートフォルダの権限を持つ所属のIDを返す
    #
    def super_section_id
      Section.super_section.try(:id)
    end

  end
end
