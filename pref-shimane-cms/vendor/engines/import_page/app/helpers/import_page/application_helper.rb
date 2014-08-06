module ImportPage
  module ApplicationHelper
    include BootstrapFlashHelper

    def import_page_result_messages(results = '')
      results = ActiveSupport::JSON.decode(results)
      if results.blank?
        return content_tag(:div, t('.has_no_messages'))
      end

      results.map do |result|
        html = ''
        result = result.with_indifferent_access
        unless result[:messages].blank?
          html += content_tag(:div, result[:title])
          html += content_tag(:ul) do
            result[:messages].map do |msg|
              content_tag(:li, msg, nil, false)
            end.join.html_safe
          end
        end
        html
      end.join.html_safe
    rescue MultiJson::LoadError
      results = results.lines.map(&:chop)
      if results.blank? || results.size == 1
        return content_tag(:div, t('.has_no_messages'))
      end

      content_tag(:ul) do
        results.map {|msg| content_tag(:li, msg) }.join.html_safe
      end
    end
  end
end
