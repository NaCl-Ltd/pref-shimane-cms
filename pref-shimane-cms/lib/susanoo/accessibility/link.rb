
module Susanoo
  module Accessibility
    class Link < Base

      def initialize(settings = {})
        super(settings)
        nbsp = Nokogiri::HTML("&nbsp;").text
        @space_regex = /^(\s|　|#{nbsp})+$/
      end

      def validate(doc)
        selector = settings.target.css

        doc.css("#{selector} a").each_with_index do |node, i|
          uri = parse_uri(node['href'])
          if uri
            validate_external_link(node, uri)
            validate_invalid_file(node, uri)
          end
          validate_links(node)
        end
        @messages
      end

      private

        #
        #=== 外部サイトリンクのラベルをチェックする
        # チェック対象はaタグ配下のテキスト、aタグ配下のimg.alt属性
        #
        def validate_external_link(node, uri)
          if local_uri?(uri) || settings.link.external_label.nil?
            return
          end

          has_external_label = false

          if node.text =~ /#{settings.link.external_label}/
            has_external_label = true
          end

          node.css('img').each do |img|
            if img['alt'].present? && img['alt'] =~ /#{settings.link.external_label}/
              has_external_label = true
            end
          end

          unless has_external_label
            error('E_5_1', node, settings.link.external_label)
          end
        end

        #
        #=== 自サイト内のリンクの音声・動画を禁止する
        #
        def validate_invalid_file(node, uri)
          if !local_uri?(uri) || settings.link.not_uploadable_types.nil?
            return
          end
          mime_types = MIME::Types.type_for(uri.path)
          if mime_types.blank?
            return
          end
          media_type = mime_types.first.media_type
          if settings.link.not_uploadable_types.include?(media_type)
            error('E_5_4', node)
          end
        end

        #
        #=== 連続するリンクを禁止する
        #
        def validate_links(node)
          return unless node.next.present?
          if node.next.name == 'a'
            error('E_5_2', node.next)
          elsif node.next.name == 'text' && node.next.text =~ @space_regex
            if node.next.next.present? && node.next.next.name == 'a'
              error('E_5_3', node.next.next)
            end
          end
        end

        #
        #=== 内部サイトへのリンクかどうかチェックする
        #
        def local_uri?(uri)
          uri.relative? || Settings.local_domains.include?(uri.host)
        end

        #
        #=== hrefの内容を解析する
        #
        def parse_uri(href)
          return nil if href.blank?
          begin
            decoded_href = URI.decode(href)
            encoded_href = URI.encode(decoded_href)
            uri = URI.parse(encoded_href)
            if uri.to_s =~ /^mailto\:/ || uri.to_s =~ /^javascript\:/
              nil
            else
              uri
            end
          rescue => e
            nil
          end
        end

    end
  end
end
