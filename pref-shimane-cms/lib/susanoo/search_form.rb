#
#=== 検索フォーム用モデル
#
module Susanoo
  class SearchForm

    extend ActiveModel::Naming
    include ActiveModel::Conversion
    include ActiveModel::Validations

    @@default_order = ''
    class_attribute :fields, :default_order
    attr_accessor :attributes, :order_column, :order_direction

    #
    #=== 検索パラメータを定義する
    # type で指定可能な型は以下
    #* :string   編集中
    #* :integer  公開依頼
    #* :date     却下
    #* :datetime 公開(公開待ち・公開中・公開終了の状態を含む)
    #
    def self.field(name, options = {})
      type = options[:type] || "string"
      self.fields ||= {}
      self.fields[name.to_sym] = {type: type.to_sym}
    end

    #
    #=== コンストラクタ
    #
    def initialize(attr = {})
      self.order_column = attr[:order_column]
      self.order_direction = attr[:order_direction]
      self.attributes = {}
      _attr = attr.with_indifferent_access
      self.fields.each do |f, o|
        case o[:type]
        when :string
          attributes[f] = _attr[f] if _attr[f].present?
        when :integer
          attributes[f] = _attr[f].to_i if _attr[f].present?
        when :date, :datetime
          attributes[f] = parse_datetime(_attr, f)
        end
      end
    end

    #
    #=== 指定のキーで格納している値を取得する
    #
    def [](key)
      attributes[key.to_sym]
    end

    #
    #=== 指定のキーで指定の値を格納する
    #
    def []=(key, value)
      attributes[key.to_sym] = value
    end

    #
    # メソッドでアクセスされた場合、ハッシュから値を取得する
    # 代入メソッドの場合、ハッシュに値を格納する
    #
    def method_missing(name, *args)
      if name.to_s.ends_with?('=')
        attributes[name.to_s.chomp('=').to_sym] = *args[0]
      else
        attributes[name.to_sym]
      end
    end

    #
    #=== 内部に格納しているパラメータをハッシュ形式で出力する
    #
    def to_s
      attributes.to_s
    end

    #
    #=== フィールドタイプを返す
    #
    def field_type(name)
      self.fields[name.to_sym] ? self.fields[name.to_sym][:type] : nil
    end

    #
    #=== ソート順を返す
    #
    # 子クラスでオーバーライドすること
    #
    def order_by
    end

    private
      #
      #== 日付型のリクエストパラメータを解析する
      #
      def parse_datetime(attr, name)
        _name = name.to_s
        begin
          y = attr[(_name + '(1i)').to_sym].to_i
          m = attr[(_name + '(2i)').to_sym].to_i
          d = attr[(_name + '(3i)').to_sym].to_i

          if field_type(name) == :date
            Date.new(y, m, d)
          else
            hh = (attr[(_name + '(4i)').to_sym] || 0).to_i
            mm = (attr[(_name + '(5i)').to_sym] || 0).to_i
            ss = (attr[(_name + '(6i)').to_sym] || 0).to_i
            DateTime.new(y, m, d, hh, mm, ss)
          end
        rescue => e
          nil
        end
      end
  end
end
