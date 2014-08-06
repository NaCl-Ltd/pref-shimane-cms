class LostLink < ActiveRecord::Base
  include Concerns::LostLink::Association
  include Concerns::LostLink::Method
  include Concerns::LostLink::Validation

  cattr_accessor :link_check_log
  cattr_accessor :access_cache

  def self.check_all_links
    self.link_check_log = ::Logger.new(Rails.root.join('log/link_check.log'))
    self.access_cache = {}
    self.delete_all
    link_check_log.info("START: check_all_links")
    traverse_dir(Settings.export.docroot, URI.parse(Settings.public_uri))
    link_check_log.info("FINISH: check_all_links")
  end

  private

  def self.traverse_dir(base_dir, base_uri)
    link_check_log.info("base_dir=[#{base_dir}] base_uri=[#{base_uri.to_s}]")
    Dir.glob(File.join(base_dir, "*")) do |path|
      if FileTest.file?(path)
        if /\.html$/ =~ path
          check_link(path, base_uri)
        end
      elsif FileTest.directory?(path)
        traverse_dir(path, base_uri.merge(File.basename(path) + "/"))
      else
        link_check_log.warn("#{path}: This file is not regular file or directory.\n")
      end
    end
  end

  def self.success_uri?(uri)
    return access_cache[uri] if access_cache.has_key?(uri)

    if Settings.proxy_addr && Settings.proxy_port
      proxy_class = Net::HTTP::Proxy(Settings.proxy_addr, Settings.proxy_port)
      http = proxy_class.new(uri.host, uri.port)
    else
      http = Net::HTTP.new(uri.host, uri.port)
    end

    if uri.scheme == "https"
      http.use_ssl = true
      http.verify_mode = OpenSSL::SSL::VERIFY_NONE
    end

    begin
      http.open_timeout = 5
      http.read_timeout = 5
      http.start
     response = http.head(uri.request_uri)
      case response
      when Net::HTTPOK
        access_cache[uri] = true
        return true
      when Net::HTTPSuccess
        access_cache[uri] = true
        return true
      when Net::HTTPRedirection
        access_cache[uri] = false
        return false
      end
    rescue TimeoutError
    ensure
      http.finish rescue nil
    end
    access_cache[uri] = false
    return false
  end

  def self.check_link(filename, base_uri)
    path = filename.sub(%r!\A#{Regexp.quote(Settings.export.docroot)}/?!, '/')
    page = Page.find_by_path(path)
    return unless page
    inside_errors = []
    outside_errors = []
    link_check_log.info("filename=[#{filename}] base_uri=[#{base_uri.to_s}]")
    text = File.read(filename)
    text.sub!(/\A.*?<!-- begin_content -->/m, '')
    text.sub!(/<!-- end_content -->.*?\z/m, '')
    doc = Nokogiri::HTML.parse(text)
    links = doc.xpath("//a").map do |elem|
      elem[:href] ? { href: elem[:href], text: elem.inner_text } : nil
    end.compact

    links.each do |link|
      begin
        next if /\A#/ =~ link[:href]
        link_check_log.debug("try href=[#{link[:href]}] text=[#{link[:text]}] base_uri=[#{base_uri.to_s}] filename=[#{filename}]")
        uri = base_uri.merge(link[:href])
        if /\Ahttps?\z/ !~ uri.scheme
          link_check_log.debug("skip href=[#{link[:href]}] text=[#{link[:text]}] base_uri=[#{base_uri.to_s}] filename=[#{filename}]")
        elsif %r!\A/! =~ link[:href]
          # 内部リンクチェック
          file = File.join(Settings.export.docroot, link[:href])
          file.sub!(%r!#.*\z!, '')
          file.sub!(%r!/\z!, '/index.html')
          if File.exists?(file)
            link_check_log.info("success_local link=[#{uri.to_s}] href=[#{link[:href]}] text=[#{link[:text]}] base_uri=[#{base_uri.to_s}] filename=[#{filename}]")
          else
            link_check_log.error("failure_local link=[#{uri.to_s}] href=[#{link[:href]}] text=[#{link[:text]}] base_uri=[#{base_uri.to_s}] filename=[#{filename}]")
            inside_errors << [link[:href], I18n.t("lost_links.error_message")]
          end
        else
          if success_uri?(uri)
            link_check_log.info("success_remote link=[#{uri.to_s}] href=[#{link[:href]}] text=[#{link[:text]}] base_uri=[#{base_uri.to_s}] filename=[#{filename}]")
          else
            link_check_log.error("failure_remote link=[#{uri.to_s}] href=[#{link[:href]}] text=[#{link[:text]}] base_uri=[#{base_uri.to_s}] filename=[#{filename}]")
            outside_errors << [link[:href], link[:text]]
          end
        end
      rescue
        unless %r!\A/! =~ link[:href]
          link_check_log.fatal("failure_error link=[#{uri.to_s}] href=[#{link[:href]}] text=[#{link[:text]}] base_uri=[#{base_uri.to_s}] filename=[#{filename}]")
          outside_errors << [link[:href], link[:text]]
        end
      end
    end
    if outside_errors.present?
      msg = ""
      msg += %Q!<ul>!
      outside_errors.each do |href, link_text|
        msg += %Q!<li>#{ERB::Util.h(href)} (#{ERB::Util.h(link_text)})</li>!
      end
      msg += %Q!<ul/>!
      if msg.present?
        self.create(page_id: page.id, section_id: page.genre.section.id,
                    side_type: ::LostLink::OUTSIDE_TYPE,
                    target: nil, message: msg)
      end
    end
    inside_errors.each do |e|
      self.create(page_id: page.id, section_id: page.genre.section.id,
                  side_type: LostLink::INSIDE_TYPE,
                  target: e.first, message: e.second)
    end
  end
end
