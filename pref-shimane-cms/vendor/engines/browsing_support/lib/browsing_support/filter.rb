require 'iconv'
require 'nkf'

module BrowsingSupport
  module Filter
    def k2h(text)
      return text if text.blank?

      text = text.gsub('ヴ', 'う゛')
      NKF.nkf('-w --hiragana', text)
    end

    def h2k(text)
      return text if text.blank?

      text = text.gsub('う゛', 'ヴ')
      NKF.nkf('-w --katakana', text)
    end

    def convert(text, from, to)
      ret_text = ''
      input = text
      Iconv.open(to, from) do |cd|
        until input.empty?
          begin
            ret_text << cd.iconv(input)
            break
          rescue Iconv::Failure => e
            ret_text << e.success
            invalid_char, input = e.failed.split(Regexp.new('', nil, from), 2)
            ret_text << yield(invalid_char) if block_given?
          rescue NoMethodError
            raise 'invalid encoding'
          end
        end
      end
      return ret_text
    end

    module_function :convert
    module_function :k2h, :h2k
  end
end
