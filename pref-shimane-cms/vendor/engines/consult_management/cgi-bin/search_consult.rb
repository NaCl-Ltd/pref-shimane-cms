#!/usr/local/bin/ruby

require "cgi"
require "json"

# 相談窓口検索機能CGI(モバイルページのみ)
cgi = CGI.new
consults = JSON.parse(File.read('consult.json', :encoding => Encoding::UTF_8))
params = cgi.params

# 分類とキーワードが一致しているものを取得
result = params["consult[consult_category_ids][]"].each_with_object([]) do |id, result|
  consults.each do |c|
    if c['consult_category_ids'].include?(id.to_i) &&
      (c["name"].include?(cgi["consult[keyword]"]) || c["work_content"].include?(cgi["consult[keyword]"]))
      result << c
    end
  end
end
result.uniq!

# ここから出力処理

# ヘッダーの出力
print cgi.header('charset' => 'UTF-8')
print <<HTML
<a href="/">TOP</a>

<hr />

<h1>相談窓口検索結果</h1>
HTML

# 検索結果の出力
result_html = result.each_with_object('') do |consult, result_html|
  result_html << <<HTML
  <div>
    <h2>名称:<a href=#{consult['link']}>#{consult['name']}</a></h2>
    <p>#{consult['work_content']}</p>
    <p>#{consult['contact']}</p>
  </div>
HTML
end
print result_html

# フッターの出力
print <<HTML
<a href='#{cgi.referer}'>検索画面へ戻る</a>
<hr />
HTML
