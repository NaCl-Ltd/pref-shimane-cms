# -*- coding: utf-8 -*-
module Susanoo
  module Accessibility
    #
    #=== 空白チェック
    #
    class Blank < Base
      def validate(doc)
        xpath = settings.target.xpath
        nbsp = Nokogiri::HTML("&nbsp;").text

        doc.xpath("#{xpath}/div//text()").each_with_index do |e, i|
          if e.parent.present?
            # 同じ親要素の先頭のテキストノードのポインタを取得する
            first_text_pointer_id = nil
            e.parent.children.each do |c|
              if c.name == 'text'
                first_text_pointer_id = c.pointer_id
                break
              end
            end

            # 言語指定されていない要素内のテキストをチェックする
            # また、テキストが空白のみの場合はチェックしない
            if e.ancestors('span[lang]').blank?
              if !(e.text.gsub(nbsp, '').empty? && e.parent.try(:name) == 'p')
                if first_text_pointer_id
                  if first_text_pointer_id == e.pointer_id
                    e.content = remove_space(e.content)
                  else
                    e.content = e.content.gsub(/(\s|　|#{nbsp})/, '')
                  end
                else
                  e.content = remove_space(e.content)
                end
              end
            end
          else
            e.content = remove_space(e.content)
          end
        end

        selector = settings.target.css
        doc.css("#{selector} img").each_with_index do |e, i|
          if e['alt'].present?
            e['alt'] = e['alt'].gsub(/(\s|　)/, '')
          end
        end

        doc.css("#{selector} table").each_with_index do |e, i|
          if e['summary'].present?
            e['summary'] = e['summary'].gsub(/(\s|　)/, '')
          end
        end

        @messages
      end

      #
      #=== 先頭の全角スペース以外のスペースを置換する
      #
      def remove_space(text)
        nbsp = Nokogiri::HTML("&nbsp;").text
        removed = text.gsub(/(?<=.)(\s|　|#{nbsp})/, '')
        removed = removed.gsub(/^(\s|#{nbsp})/, '')
        removed
      end

    end
  end
end
