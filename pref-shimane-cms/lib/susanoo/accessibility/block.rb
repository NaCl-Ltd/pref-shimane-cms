module Susanoo
  module Accessibility
    class Block < Base
      #
      #=== ブロック要素の制限をチェックする
      # 以下のHTMLをエラーとする
      #  * 見出し文字数が最大値より大きい場合 -> E_1_1
      #  * 見出しタグ内に改行タグがある場合 -> E_1_2
      #  * ブロック要素内の文字数が最大値より多い場合 -> E_1_4, W_1_1
      #  * 見出し要素がない場合 -> E_1_5
      #  * 先頭が見出し要素でない場合 -> E_1_6
      #  * 同レベルの見出しを連続使用した場合 -> E_1_7
      #  * 見出しレベルの順序をスキップした場合 -> E_1_8
      #  * 見出しレベルを遡る際、間にブロック要素がない場合 -> E_1_9
      #  * tableタグ内にthがない場合 -> C_331.0
      #
      def validate(doc)

        validate_heading_relations(doc)

        doc.css(selector_editable_field).each do |ef|
          # ブロック要素内の検証を行う
          ef.css(selector_editable_block).each do |eb|
            validate_length_block_text(eb)
          end

          # table の th タグの有無をチェックする
          ef.css('table').each do |table|
            error('C_331.0', table) if table.css('th').length == 0
          end
        end

        @messages
      end

      private

        #
        #=== 見出しタグ、その他のタグのの関連性を検証する
        #
        def validate_heading_relations(doc)
          contents = []

          # HTMLから見出しと見出し以外のテキスト・画像を抜き出す
          doc.xpath("#{settings.target.xpath}//text()|#{settings.target.xpath}//img").each do |node|
            if node.name == 'text' && node.text =~ /\n(\s)*/
              next
            end

            h = heading_content(node)

            if h
              contents << h unless contents.include?(h)
            else
              contents << node
            end
          end

          # 見出し要素があるか
          has_heading = true

          # 見出し前に見出し以外の要素があるか
          has_content = false

          # 見出しレベル
          current_heading_level = 0

          contents.each_with_index do |node, i|
            if node.name =~ /(h1|h2|h3|h4|h5|h6)/
              current_heading_level = validate_heading_level(node,
                current_heading_level, has_content)

              validate_heading_content(node)

              has_heading = true

              has_content = false

            else
              # 編集領域の最初の要素が見出しではない
              if i == 0
                if node.name == 'text'
                  error_node = node.parent || node
                else
                  error_node = node
                end
                error('E_1_6', error_node)
              end

              has_content = true
            end
          end

          # 見出しブロックが見つからない場合、エラー E_1_5
          error('E_1_5', nil, nil) unless has_heading
        end

        #
        #=== 見出しブロックの関連性を検証する
        #
        def validate_heading_level(node, current_heading_level, has_content)
          level = heading_level(node)

          if level.nil?
            return current_heading_level
          end

          diff_level = level - current_heading_level

          # 最初の見出しレベルのチェック
          if Settings.accessibility.accessibility_h_level
            Settings.accessibility.accessibility_h_level.each do |h_level|
              if level == h_level && current_heading_level == 0
                diff_level = 1
              end
            end
          end

          if diff_level == 0
            # 見出しレベルが同じ場合、見出し間に本文がないとエラー
            error('E_1_7', node, nil) unless has_content
          elsif diff_level == 1
            # 見出しレベルが1段階下がる場合、見出しの連続使用を許可する
            ;
          elsif diff_level >= 2
            # 見出しレベルが2段階以上下がる場合,見出し間に本文がないとエラー
            error('E_1_8', node, nil) unless has_content
          elsif diff_level < 0
            # 見出しレベルが遡る場合、本見出し間に本文がないとエラー
            error('E_1_9', node, nil) unless has_content
          end

          level
        end

        #
        #=== 見出しブロックの内容を検証する
        #
        def validate_heading_content(node)
          if node.css('br').length > 0
            error('E_1_2', node, nil)
          end

          text = node.inner_text

          if text && text.length > maxlength_header
            error('E_1_1', node, maxlength_header)
          end
        end

        #
        #=== div ブロック要素の文字数を検証する
        #
        def validate_length_block_text(node)
          text = node.text
          if text
            length = text.length
            if length > maxlength_block
              error('E_1_4', node, maxlength_block)
            elsif length > warninglength_block
              warning('W_1_1', node, warninglength_block)
            end
          end
        end

        #
        #=== 見出し要素文字数の最大長を返す
        #
        def maxlength_header
          @maxlength_header ||= settings.block.limit.error.header
        end


        #
        #=== ブロック要素文字数の最大長を返す
        #
        def maxlength_block
          @maxlength_block ||= settings.block.limit.error.text
        end

        #
        #=== 警告対象となるブロック要素文字数を返す
        #
        def warninglength_block
          @warninglength_block ||= settings.block.limit.warning.text
        end

        #
        #=== 見出しレベルを返す
        #
        def heading_level(node)
          level = case node.name.to_sym
            when :h1
              1
            when :h2
              2
            when :h3
              3
            when :h4
              4
            when :h5
              5
            when :h6
              6
            else
              nil
            end
          level
        end

        #
        #=== ノードが見出し内の要素の場合、見出しを返す
        #
        def heading_content(node)
          ancestors = node.ancestors('h1,h2,h3,h4,h5,h6')
          if ancestors.present?
            ancestors.first
          else
            nil
          end
        end
    end
  end
end

