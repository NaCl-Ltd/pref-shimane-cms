<% if @fatal_message.blank? -%>
wrapper_id='#<%= Settings.page_content.wrapper_id %>'
iframe_content =$('.iframe-edit').contents()
iframe_content.find(wrapper_id).html('<%= raw j(@source) %>')
iframe_content.find('.accessibility-message').each( ->
  this.remove()
)
doc = $('.iframe-edit')[0].contentWindow
doc.Visitor.EditableField.init(Susanoo.EditManager)
<% else -%>
alert('<%= j(@fatal_message) %>')
<% end -%>
$.isLoading('hide')
