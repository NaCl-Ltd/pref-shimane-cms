#
# 空タグを削除する
#
# CKEditor の CKEDITOR.dtd.$removeEmpty を利用して、空タグの削除が可能だが、
# HTMLのサイズが大きい場合、JavaScriptで Stack size error　が発生することがあるので
# 正規表現で削除する.
#
#
class RemoveEmptyTags
  standard_tags: [ 'strong', 'li', 'ol', 'ul', 'sub', 'sup', 'strike',
    'blockquote','th', 'td', 'tr', 'table', 'div', 'span', 'pre',
    'h1', 'h2', 'h3', 'h4', 'h5', 'h6']

  #
  # HTML全体から空タグを削除する
  #
  all_block: (html)=>
    if html == null || html == ""
      return html

    obj = $("<div></div>")
    obj.append(html)

    for i in @standard_tags
      obj.find("div.editable #{i}:empty").remove()

    return obj.html()

  #
  # 1ブロックのHTMLから空タグを削除する
  #
  block: (html)=>
    if html == null || html == ""
      return html

    obj = $("<div></div>")
    obj.append(html);

    for i in @standard_tags
      obj.find("#{i}:empty").remove()

    return obj.html()

this.Susanoo ||= {}
this.Susanoo.RemoveEmptyTags = new RemoveEmptyTags()
