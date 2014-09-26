module ConsultManagement
  module ConsultsHelper
    include BootstrapFlashHelper

    def lost_link_check_td_tag(consult)
      td_tag = '<td>'
      lost_link_td_tag = '<td style="background-color: red;">'

      url = consult.link.gsub(Settings.public_uri.chop, "")
      unless url =~ /^htt/
        page = Page.find_by_path(url)
        if page
          visitor_content = page.visitor_content
          unless visitor_content
            td_tag = lost_link_td_tag
          end
        else
          td_tag = lost_link_td_tag
        end
      end

      td_tag += consult.name + '</td>'

      return td_tag
    end
  end
end
