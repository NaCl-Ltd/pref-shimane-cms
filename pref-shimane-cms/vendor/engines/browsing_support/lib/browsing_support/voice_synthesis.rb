require 'rubygems'
require 'nokogiri'
require 'tempfile'
require 'digest/md5'

module BrowsingSupport
  class VoiceSynthesis
    attr_accessor :open_jtalk
    attr_accessor :open_jtalk_options
    attr_accessor :lame
    attr_accessor :lame_options
    attr_accessor :max_part_length
    attr_accessor :logger

    def initialize(configs = {})
      @open_jtalk    = configs[:open_jtalk] || "oepn_jtalk"
      @open_jtalk_options = configs[:open_jtalk_options] || {}
      @lame     = configs[:lame] || "lame"
      @lame_options  = configs[:lame_options] || {}
      @max_part_length = 300
      @logger = nil
    end

    def synthesize(text, output, options = {})
      debug_log("start: synthesize")

      raw_file = Tempfile.new('jtalk')
      raw_filename = raw_file.path
      raw_file.close
      output.binmode  # binmode に変更
      debug_log("start: lame")
      IO.popen(lame_command, "r+", binmode: true) do |lame|
        lame.sync = true
        split_text(text).each_with_index do |part, i|
          part = '。' if part == :silence
          part = numeral2number(part)
          # 音声合成開始
          debug_log("start: jtalk")
          # debug_log("part #{i + 1}: |#{part}|")
          IO.popen(jtalk_command('-ow' => raw_filename), "r+") do |jtalk|
            jtalk.write(part)
          end
          debug_log("end: jtalk")
          File.open(raw_filename, 'r', binmode: true) do |f|
            # wav ヘッダの除外
            # 標準入力からのMP3作成は、ヘッダもエンコードされるため
            # wav ヘッダを除外してエンコードする
            f.read(48)
            while s = f.read(512)
              lame.write(s)
              while IO.select([lame], nil, nil, 0)
                output.write(lame.sysread(512))
              end
            end
          end
        end
        lame.close_write
        while s = lame.read(512)
          output.write(s)
        end
      end
      debug_log("end: lame")
      debug_log("end: synthesize")

    ensure
      raw_file.close! if raw_file
    end

    def numeral2number(text)
      # Open Jtalk は数字の前後に半角括弧が有る場合、電話番号としての読み上げを回避する
      text = text.dup
      text.gsub!(/(\()(\d+?[^)\d])/, '\1 \2')  # '(2000から' -> '( 2000から'
      text.gsub!(/([^(\d]\d+?)(\))/, '\1 \2')  # 'から2013)' -> 'から2013 )'
      text.gsub!(/(\d)(\([^\d])/, '\1 \2')     # '2000(数値)' -> '2000 (数値)'
      text.gsub!(/([^\d]\))(\d)/, '\1 \2')     # '(数値)2000' -> '(数値) 2000'
      text
    end

    def synthesize_html(text, output, options = {})
      text.gsub!(%r!</(?:blockquote|dd|div|dl|dt|form|h[1-6]|hr|li|ol|p|pre|table|tbody|td|tfoot|th|thead|tr|ul)>!, "。")
      text.gsub!(/\./, '')
      text.gsub!(/(<.+?>)+/, ' ')
      text = Nokogiri::HTML(text).text
      text.strip!
      text.gsub!(/\s+/, '、')
      text.gsub!(/、*。+、*/, '。')
      text = '。' if text.empty?
      synthesize(text, output, options)
    end

    def html2m3u(path, uri, options = {})
      debug_log("html2m3u: #{path}, #{uri}")
      path_base = path.sub(/\.html\z/, '')
      uri_base = uri.sub(%r!/[^/]*\z!, '/')
      basename = File.basename(path_base)
      dest_dir = options[:dest_dir] || File.dirname(path_base)
      dest_path_base = File.join(dest_dir, basename)

      html = File.read("#{path_base}.html.r")
      text = html.gsub(/\r?\n/, '')
      text.sub!(/\A.*?<!-- begin_content -->/m, '')
      text.sub!(/<!-- end_content -->.*?\z/m, '')
      text.gsub!(%r!<script type=.+?>.+?</script>!, '')
      text.gsub!(%r!<style type=.+?>.+?</style>!, '')
      text.gsub!(%r!<ruby([^>]*)>(.*?)<rt>(.*?)</rt>.*?</ruby>!) do
        attr = $1
        ruby_base = $2
        ruby_text = $3
        if /class="custom"/ =~ attr
          ruby_text
        else
          ruby_base.gsub(%r!<rp>.*?</rp>!, '')
        end
      end
      ary = ['']
      text.split(%r!(<h[1-3][^>]*>.*?</h[1-3]>)!m).each do |e|
        text = e.dup
        text.gsub!(/(<.+?>)+/, ' ')
        text = Nokogiri::HTML(text).text
        text.strip!
        text.gsub!(/\s+/, '、')
        next if text.empty?
        if /\A<h[1-3]/ =~ e
          if ary.last.empty?
            ary.last << text
          else
            ary << text
          end
        else
          ary.last << "、#{text}"
        end
      end
      m3u_path = "#{dest_path_base}.m3u"
      mp3_files = []
      ary.each_with_index do |e, i|
        old_mp3_path = "#{path_base}.#{i}.mp3"
        mp3_path = "#{dest_path_base}.#{i}.mp3"
        mp3_files << mp3_path

        old_md5 = File.read("#{path_base}.#{i}.md5", 32) rescue ''
        md5_path = "#{dest_path_base}.#{i}.md5"
        new_md5 = Digest::MD5.hexdigest(e)

        # 新旧の md5 が一致(文章は無変更)しても、
        # 旧 mp3 ファイルが無い場合は再合成する
        if File.exist?(old_mp3_path) && old_md5 == new_md5
          debug_log("skip: #{mp3_path}")
          next
        end
        debug_log("create: #{mp3_path}")
        File.open(mp3_path, 'w') do |f|
          synthesize_html(e, f)
        end
        File.open(md5_path, 'w'){|f| f.print new_md5}
      end
      File.open(m3u_path, 'w') do |f|
        mp3_files.each do |e|
          f.puts "#{uri_base}#{File.basename(e)}"
        end
      end
      (Dir["#{dest_path_base}.*mp3"] - mp3_files).each do |file|
        FileUtils.rm([file, file.sub(/\.mp3\z/, '.md5')], :force => true)
      end
    end

    private

    def split_text(text)
      parts = []
      first_time = true
      text.split(/。|$/um).each do |part|
        part.gsub!('　', ' ')
        part.sub!(/\A[、\s]*/u, '')
        part.gsub!(/(、\s*)+/u, '、')
        part.strip!
        if !part.empty?
          if first_time
            first_time = false
          else
            parts << :silence
          end
          parts += part.scan(/.{1,#{@max_part_length}}/u)
        end
      end
      return parts
    end

    def jtalk_command(options = {})
      options = self.open_jtalk_options.merge(options)
      return %{#{self.open_jtalk} #{options.to_a.flatten.compact.join(' ')} 2>/dev/null}
    end

    def lame_command(options = {})
      options = self.lame_options.merge(options)
      return %{#{self.lame} #{options.to_a.flatten.compact.join(' ')} - - 2>/dev/null}
    end

    def debug_log(msg)
      if @logger
        # add datetime since Rails changes the default logger format :(
        @logger.debug(Time.now.strftime('%b %d %H:%M:%S ') + msg)
      end
    end
  end
end

if $0 == __FILE__
  require 'logger'

  text = <<-EOS.gsub(/^ {4}/, '')
    音声合成のテストです。
    ABCDEFGやabcdefgなどのアルファベット。
    「<」や、「>」はエスケープしないと解析に失敗する。
    エスケープ後にアンエスケープはされない。
    「&」や「""」などの記号の扱いも考える必要があります。
    いろいろ課題が残りますね。
    「ぐ」は、読みがカタカナにならない言葉です。
    電話番号999-1234-5678です。
    電話番号０８５２−２８−９２８０です。
    半角カナ(ｱｶｻﾀﾅﾊﾏﾔﾗﾜｦﾝ)も読み上げます。
    。
  EOS
  text += "\x21\x16\x21\x60\x21\x61\x21\x62\x21\x63\x21\x64\x21\x65\x21\x66\x21\x67\x21\x68\x21\x69\x21\x70\x21\x71\x21\x72\x21\x73\x21\x74\x21\x75\x21\x76\x21\x77\x21\x78\x21\x79\x33\x49\x33\x14\x33\x22\x33\x4d\x33\x18\x33\x27\x33\x03\x33\x36\x33\x51\x33\x57\x33\x0d\x33\x26\x33\x23\x33\x2b\x33\x4a\x33\x3b\x33\x9c\x33\x9d\x33\x9e\x33\x8e\x33\x8f\x33\xc4\x33\xa1\x33\x7b\x21\x16\x33\xcd\x21\x21\x32\xa4\x32\xa5\x32\xa6\x32\xa7\x32\xa8\x32\x31\x32\x32\x32\x39\x33\x7e\x33\x7d\x33\x7c\xff\x0d".encode('utf-8', 'ucs-2be')
  text += "おしまい。"
  logger = Logger.new('voice_synthesis.log')
  logger.level = Logger::DEBUG
  vs = BrowsingSupport::VoiceSynthesis.new
  vs.logger = logger
  vs.open_jtalk = File.expand_path('../../../../../src/open_jtalk/bin/open_jtalk', __FILE__)
  vs.open_jtalk_options = {
    '-x' => File.expand_path('../../../../../../files/browsing_support/development/dic', __FILE__),
    '-m' => File.expand_path('../../../../../htsvoices/mei_normal.htsvoice', __FILE__),
    '-r' => '0.9',
    '-jm' => '0.5',
    '-jf' => '0.2',
  }
  vs.lame = File.expand_path('../../../../../src/lame/frontend/lame', __FILE__)
  vs.lame_options = {'-r' => nil, '-b' => '32', '--cbr' => nil, '-m' => 'm', '--scale' => '1.5'}
  vs.synthesize(text, STDOUT)
end
