#
#== date_select, datetime_select に区切り文字を追加する
#
module ActionView
  module Helpers
    class DateTimeSelector
      def select_month_with_separator
        @options[:use_separators] ||= {inline: true}
        separators = @options[:use_separators]
        select_tag = select_month_without_separator

        if @options[:use_hidden].blank? && @options[:discard_month].blank? && separators.present?
          select_tag << separator_tag(:month, separators)
        end

        select_tag
      end
      alias_method_chain :select_month, :separator

      def build_options_and_select_with_separator(type, selected, options = {})
        @options[:use_separators] ||= {inline: true}

        separators = @options[:use_separators]

        if separators.present?
          if use_inline_separator?(separators)
            options.merge!({:use_separator => separator_name(type, separators)})
            build_select(type, build_options_with_separator(selected, options))
          else
            build_select(type, build_options(selected, options)) + separator_tag(type, separators)
          end
        else
          build_options_and_select_without_separator(type, selected, options)
        end
      end
      alias_method_chain :build_options_and_select, :separator

      private
        def use_inline_separator?(separators)
          (separators.class == Hash && separators[:inline] == true)
        end

        def translated_separator_name(type)
          key = 'datetime.separators.' + type.to_s
          I18n.translate(key, :locale => @options[:locale])
        end

        def separator_name(type, separators)
          if separators.class == Hash && separators[type].present?
            separators[type]
          else
            key = 'datetime.separators.' + type.to_s
            I18n.translate(key, :locale => @options[:locale])
          end
        end

        def separator_tag(type, separators)
          return '' if use_inline_separator?(separators)

          default_options = {:html_tag => :span, :class_prefix => 'separator'}
          options = (separators.class == Hash) ? default_options.merge!(separators) : default_options

          if options
            name = separator_name(type, separators)
            class_name = options[:class_prefix] + "_#{type}"
            content_tag(options[:html_tag], name, :class => class_name) + "\n"
          else
            ''
          end
        end

        def build_options_with_separator(selected, options = {})
          options = {
            leading_zeros: true, ampm: false, use_two_digit_numbers: false, use_separator: false
          }.merge!(options)

          start         = options.delete(:start) || 0
          stop          = options.delete(:end) || 59
          step          = options.delete(:step) || 1
          leading_zeros = options.delete(:leading_zeros)

          select_options = []
          start.step(stop, step) do |i|
            value = leading_zeros ? sprintf("%02d", i) : i
            tag_options = { :value => value }
            tag_options[:selected] = "selected" if selected == i
            text = options[:use_two_digit_numbers] ? sprintf("%02d", i) : value
            text = options[:ampm] ? AMPM_TRANSLATION[i] : text
            text = options[:use_separator] ? text.to_s + options[:use_separator] : text
            select_options << content_tag(:option, text, tag_options)
          end

          (select_options.join("\n") + "\n").html_safe
        end
    end
  end
end
