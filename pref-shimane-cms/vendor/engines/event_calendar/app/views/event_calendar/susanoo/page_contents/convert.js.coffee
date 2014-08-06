<% if @fatal_message.blank? -%>
wrapper_id='#<%= Settings.page_content.wrapper_id %>'
iframe_content =$('.iframe-edit').contents()
iframe_content.find(wrapper_id).html('<%= raw j(@result) %>')
iframe_content.find('.accessibility-message').each( ->
  $(this).remove()
)
<% if @page_content.errors.any? -%>
messages = '<%= j(page_editor_error_messages_for(@page_content)) %>'
iframe_content.find('body').prepend(messages)
<% end -%>

doc = $('.iframe-edit')[0].contentWindow
doc.Visitor.EditableField.init(Susanoo.EditManager)
<% else -%>
alert('<%= j(@fatal_message) %>')
<% end -%>
$.isLoading('hide')
