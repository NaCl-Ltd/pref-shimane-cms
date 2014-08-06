require 'nokogiri'

module Susanoo
  #
  #== アクセシビリティチェッククラス
  #
  class AccessibilityChecker

    attr_reader :settings, :messages, :target, :path

    #
    #=== コンストラクタ
    #
    def initialize(path: nil)
      @path = path
      @messages = { error: [], warning: [], info: [], user: []}
      @settings = Settings.accessibility
      @wrapper_id = Settings.page_content.wrapper_id
      @validates = {
        michecker: true, block: true, alt: true,
        blank: true, link: true, text: true, button: true
      }
    end

    #
    #=== アクセシビリティチェックを実行する
    # 実行結果を反映したHTMLを返却し、  エラーの内容をインスタンス変数に設定する
    #
    def run(target, validate_configs={})
      return if @settings.blank? or target.blank?
      @validates.merge!(validate_configs) if validate_configs.present?
      @target = target
      doc = Nokogiri.HTML(@target)

      if @validates[:michecker]
        mic = Susanoo::Accessibility::Michecker.new(messages: messages)
        mic.validate(@target)
      end

      if @validates[:block]
        block = Susanoo::Accessibility::Block.new(path: @path, messages: messages)
        block.validate(doc)
      end

      if @validates[:alt]
        alt = Susanoo::Accessibility::Alt.new(path: @path, messages: messages)
        alt.validate(doc)
      end

      if @validates[:blank]
        blank = Susanoo::Accessibility::Blank.new(path: @path, messages: messages)
        blank.validate(doc)
      end

      if @validates[:style]
        style = Susanoo::Accessibility::Style.new(path: @path, messages: messages)
        style.validate(doc)
      end

      if @validates[:link]
        link = Susanoo::Accessibility::Link.new(path: @path, messages: messages)
        link.validate(doc)
      end

      if @validates[:text]
        text = Susanoo::Accessibility::Text.new(path: @path, messages: messages)
        text.validate(doc)
      end

      if @validates[:button]
        button = Susanoo::Accessibility::Button.new(path: @path, messages: messages)
        button.validate(doc)
      end

      highlight(doc, errors)
    end

    def errors
      messages[:error]
    end

    def warnings
      messages[:warning]
    end

    def infos
      messages[:info]
    end

    def users
      messages[:user]
    end

    private

      #
      # エラー行数をハイライトする
      #
      def highlight(doc, problems)
        if problems.blank?
          return doc.at_css('#'+@wrapper_id).children.to_xhtml
        end

        error_lines = {}

        problems.each do |_p|
          next if _p[:tags].blank?

          _p[:tags].each do |_t|

            i18n_options = { scope:'accessibility.errors', default: _p[:description] }

            if _p[:args].present?
              _p[:args].each_with_index { |a, i| i18n_options["arg#{i+1}".to_sym] = a }
            else
              i18n_options[:arg1] = _p[:target]
            end

            description = I18n.t(_p[:id].gsub("\.", "_"), i18n_options)

            l = _t[:line].to_i
            error_lines[l] ||= []
            error_lines[l] << [_t[:name], description]
          end
        end

        doc.css("\##{@wrapper_id} *").each_with_index do |e, i|
          next unless error_lines.has_key?(e.line)
          error_info = error_lines[e.line]
          error_info.each do |name, description|
            if name == e.name
              e["class"] ||= ""
              if !(e["class"] =~ /accessibility\-error\-highlight/)
                e["class"] += " accessibility-error-highlight"
              end
              e["data-content"] = description
            end
          end
        end
        doc.at_css('#'+@wrapper_id).children.to_xhtml
      end
  end
end
