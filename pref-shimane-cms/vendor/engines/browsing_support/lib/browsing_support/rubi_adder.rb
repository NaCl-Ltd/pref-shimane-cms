# -*- coding: utf-8 -*-
require_relative 'filter'

ENV['MECAB_PATH'] ||= Settings.browsing_support.library.mecab
require 'natto'

module BrowsingSupport
  module RubiAdder
    ADDED_RUBI_REGEXP = %r'(<ruby[^>]*>.*?</ruby\s*>)'m
    OKURIGANA_PATTERN = '[ぁ-んァ-ンー]'

    module_function

    def add(html)
      before_body = html.slice!(/\A.*?<body.*?>\n?/m)
      after_body = html.slice!(/\n?<\/body.*?>.*?\z/m)
      body = html.split(ADDED_RUBI_REGEXP).collect { |s|
        if ADDED_RUBI_REGEXP =~ s
          s
        else
          exclude_regexp = %r'(<.*?>|\s+)'m
          s.split(exclude_regexp).collect { |s2|
            if s2.empty? || exclude_regexp =~ s2
              s2
            else
              add_rubi(s2)
            end
          }
        end
      }.join
      return [before_body, body, after_body].join
    rescue Natto::MeCabError
      return nil
    end

    def add_rubi(text)
      result = ""
      parse(text) do |node|
        next if node.is_eos?

        orig = node.surface.strip
        rubi = node.feature.split(',')[7]
        if "" == orig
          result << "\n"
          next
        end
        rubi = Filter.k2h(rubi)
        if /[一-龠々]/ =~ orig
            split_okurigana(orig, rubi).each do |(_orig, _rubi)|
            if _rubi
              result << %{<ruby>#{_orig}<rp>(</rp><rt>#{_rubi}</rt><rp>)</rp></ruby>}
            else
              result << _orig
            end
          end
        else
          result << orig
        end
      end
      return result.chomp
    end

    #
    # お祭り, おまつり => [['お', nil], ['祭', 'まつ'], ['り', nil]]
    #
    def split_okurigana(text, rubi)
      result = [[text, rubi]]

      text_parts = text.split(/(#{OKURIGANA_PATTERN}+)/u)
      text_parts.shift if text_parts.first.blank?
      # 送り仮名が無い場合は、そのまま返す
      return result unless text_parts.length > 1

      hiragana_text_parts = text_parts.map {|i| Filter.k2h(i) }
      if /^#{hiragana_text_parts.first}/ =~ rubi
        result.unshift([text_parts.first, nil])
        # 元のテキストから接続詞を削除
        result[1] = [result[1][0].sub(/^#{text_parts.first}/, ''),
                     result[1][1].sub(/^#{hiragana_text_parts.first}/, '')]
      end
      if /#{hiragana_text_parts.last}$/ =~ rubi
        result.push([text_parts.last, nil])
        # 元のテキストから送り仮名を削除
        result[-2] = [result[-2][0].sub(/#{text_parts.last}$/, ''),
                      result[-2][1].sub(/#{hiragana_text_parts.last}$/, '')]
      end
      return result
    end

    def natto_mecab
      if @mecab_dicts.blank? ||
          @mecab_dicts.any? {|(d, t)| t != (File.mtime(d) rescue nil) }

        @natto_mecab = begin
            _natto_mecab
          rescue Natto::MeCabError
            GC.start
            _natto_mecab
          end

        if @natto_mecab
          @mecab_dicts =
            @natto_mecab.dicts.each_with_object({}) do |d, h|
              h[d[:filename]] = File.mtime(d[:filename]) rescue nil
            end
        end
      end
      @natto_mecab
    end

    def _natto_mecab
      Natto::MeCab.new(rcfile: Settings.browsing_support.mecabrc, dicdir: Settings.browsing_support.dicdir)
    end

    def parse(text, &block)
      natto_mecab.parse(text, &block)
    end
  end
end
