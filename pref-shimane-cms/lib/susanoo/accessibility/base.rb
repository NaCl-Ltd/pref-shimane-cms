module Susanoo
  module Accessibility
    class Base
      attr_reader :settings, :path

      def initialize(path: nil, messages: nil, settings: {})
        @path = path
        @messages = messages || { error: [], warning: [], info: [], user: []}
        @settings = settings.present? ? settings : Settings.accessibility
      end

      private
        #
        #=== メッセージにエラーIDとHTMLのタグ、行数を設定する
        #
        def error(id, tag, *args)
          add_message(:error, id, tag, *args)
        end

        #
        #=== メッセージにエラーIDとHTMLのタグ、行数を設定する
        #
        def warning(id, tag, *args)
          add_message(:warning, id, tag, *args)
        end

        #
        #=== メッセージにエラーIDとHTMLのタグ、行数を設定する
        #
        def user_decision(id, tag, *args)
          add_message(:user, id, tag, *args)
        end

        #
        #=== メッセージにエラーIDとHTMLのタグ、行数を設定する
        #
        def add_message(type, id, tag, *args)
          @messages ||= {}
          @messages[type] ||= []

          return if except?(id)

          message = {}.with_indifferent_access
          message[:id] = id
          message[:args] = args if args.present?
          if tag.present?
            tag_info = { name: tag.name, line: tag.line }.with_indifferent_access
            @messages[type].each do |m|
              if m[:id] == id
                m[:tags] << tag_info
                return
              end
            end
            message[:tags] = [tag_info]
          end
          @messages[type] << message
        end

        #
        #===　エラーIDが例外リストに登録されているかどうかを返す
        #
        def except?(id)
          return false if path.blank? || settings.blank? || settings.exceptions.blank?
          settings.exceptions.each do |e|
            match_id = false
            match_path = false

            e.id.each do |i|
              if i == id
                match_id = true
                break
              end
            end

            next unless match_id

            # パスがマッチするかどうか検証する
            if e.level.blank? || e.level == 1
              match_path = true if e.path == path
            else
              regex = (e.path[-1] == '/') ? %r!^#{e.path}(.*)! : %r!^#{e.path}/(.*)!
              m = regex.match(path)
              if m.present? && m[1].split('/').size <= e.level
                match_path = true
              end
            end

            if match_path
              return true
            end
          end
          return false
        end

        #
        #=== 編集領域の特殊クラス名を返す
        #
        def editable_class
          @editable_class ||= PageContent.editable_class
        end

        #
        #=== 編集可能領域のCSSセレクタを返す
        #
        def selector_editable_field
          @selector_editable_field ||= ".#{editable_class[:field]}"
        end

        #
        #=== 編集要素のCSSセレクタを返す
        #
        def selector_editable_block
          @selector_editable_block ||= ".#{editable_class[:block]}"
        end

        #
        #=== Nokogiri::XML::Nodeが指定のクラスを持つかどうかを返す
        #
        def node_has_class?(node, classname)
          return false unless node['class']
          return node['class'].split(/\s/).include? classname
        end
    end
  end
end
