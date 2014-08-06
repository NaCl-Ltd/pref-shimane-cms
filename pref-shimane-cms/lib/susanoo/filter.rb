require 'iconv'

module Susanoo::Filter
  CONV_TABLE = {
    "\342\204\226" => "No.",
    "\342\204\241" => "TEL",
    "\342\205\240" => "I",
    "\342\205\241" => "II",
    "\342\205\242" => "III",
    "\342\205\243" => "IV",
    "\342\205\244" => "V",
    "\342\205\245" => "VI",
    "\342\205\246" => "VII",
    "\342\205\247" => "VIII",
    "\342\205\250" => "IX",
    "\342\205\251" => "X",
    "\342\205\260" => "i",
    "\342\205\261" => "ii",
    "\342\205\262" => "iii",
    "\342\205\263" => "iv",
    "\342\205\264" => "v",
    "\342\205\265" => "vi",
    "\342\205\266" => "vii",
    "\342\205\267" => "viii",
    "\342\205\270" => "ix",
    "\342\205\271" => "x",
    "\343\210\261" => "(株)",
    "\343\210\262" => "(有)",
    "\343\210\271" => "(代)",
    "\343\212\244" => "(上)",
    "\343\212\245" => "(中)",
    "\343\212\246" => "(下)",
    "\343\212\247" => "(左)",
    "\343\212\250" => "(右)",
    "\343\214\203" => "アール",
    "\343\214\215" => "カロリー",
    "\343\214\224" => "キロ",
    "\343\214\230" => "グラム",
    "\343\214\242" => "センチ",
    "\343\214\243" => "セント",
    "\343\214\246" => "ドル",
    "\343\214\247" => "トン",
    "\343\214\253" => "パーセント",
    "\343\214\266" => "ヘクタール",
    "\343\214\273" => "ページ",
    "\343\215\211" => "ミリ",
    "\343\215\212" => "ミリバール",
    "\343\215\215" => "メートル",
    "\343\215\221" => "リットル",
    "\343\215\227" => "ワット",
    "\343\215\273" => "平成",
    "\343\215\274" => "昭和",
    "\343\215\275" => "大正",
    "\343\215\276" => "明治",
    "\343\216\216" => "mg",
    "\343\216\217" => "kg",
    "\343\216\234" => "mm",
    "\343\216\235" => "cm",
    "\343\216\236" => "km",
    "\343\216\241" => "m2",
    "\343\217\204" => "cc",
    "\343\217\215" => "K.K.",
    "\357\274\215" => "−",
    "\357\275\236" => "〜",
  }

  #
  #=== 機種依存文字を変換する
  #
  def convert_non_japanese_chars(str, conv = true, import_all_enable = false)
    sjis_text = convert(str, 'utf-8', 'shift_jis'){|c|
      if conv && CONV_TABLE[c]
        convert(CONV_TABLE[c], 'utf-8', 'shift_jis')
      else
        if import_all_enable
          ''
        else
          '<span class="invalid">&#%d;</span>' %
            Iconv.conv('ucs-2be', 'utf-8', c).unpack('n').first
        end
      end
    }
    sjis_text.encode("UTF-8", "Shift_JIS").gsub(/\342\200\276/, '~')
  end

  #
  #=== 機種依存文字を除去する
  #
  def remove_non_japanese_chars(text)
    sjis_text = convert(text, 'utf8', 'shift_jis')
    sjis_text.encode("UTF-8", "Shift_JIS").gsub(/\342\200\276/, '~')
  end

  #
  # 対象の文字列の文字列コードを変換する
  #
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
          invalid_char, input = e.failed.split("", 2)
          if block_given?
            ret_text << yield(invalid_char)
          end
        rescue NoMethodError
          raise 'invalid encoding'
        end
      end
    end
    return ret_text
  end

  #
  # 機種依存文字を抜き出す
  #
  def non_japanese_chars(text)
    return if text.blank?
    invalid_chars = ""
    input = text.dup
    Iconv.open('shift_jis', 'utf-8') do |cd|
      until input.empty?
        begin
          cd.iconv(input)
          break
        rescue Iconv::Failure => e
          invalid_char, input = e.failed.split("", 2)
          invalid_chars << invalid_char
        rescue NoMethodError
          raise 'invalid encoding'
        end
      end
    end
    return invalid_chars.split("")
  end

  module_function :convert_non_japanese_chars
  module_function :remove_non_japanese_chars
  module_function :convert
  module_function :non_japanese_chars
end
