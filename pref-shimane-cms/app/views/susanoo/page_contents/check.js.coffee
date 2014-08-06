<% if @fatal_message.blank? -%>
wrapper_id='#<%= Settings.page_content.wrapper_id %>'
iframe_content =$('.iframe-edit').contents()
iframe_content.find('.accessibility-message').remove()

<% if @checker.infos.present? -%>
info_messages = '<%= j(accessibility_messages('info', @checker.infos)) %>'
iframe_content.find('body').prepend(info_messages)
<% end -%>

<% if @checker.users.present? -%>
user_messages = '<%= j(accessibility_messages('user', @checker.users)) %>'
iframe_content.find('body').prepend(user_messages)
<% end -%>

<% if @checker.warnings.present? -%>
warning_messages = '<%= j(accessibility_messages('warning', @checker.warnings)) %>'
iframe_content.find('body').prepend(warning_messages)
<% end -%>

iframe_content.find(wrapper_id).html('<%= raw j(@result) %>')
doc = $('.iframe-edit')[0].contentWindow
doc.Visitor.EditableField.init(Susanoo.EditManager)

<% if @checker.errors.present? -%>
error_messages = '<%= j(accessibility_messages('error', @checker.errors)) %>'
iframe_content.find('body').prepend(error_messages)
<% if current_user.skip_accessibility_check? -%>
Susanoo.EditManager.enable_save()
<% else -%>
Susanoo.EditManager.disable_save()
<% end -%>
<% else -%>
success_messages = '<%= j(accessibility_success_messages) %>'
iframe_content.find('body').prepend(success_messages)
Susanoo.EditManager.enable_save()
<% end -%>
<% else-%>
alert('<%= j(@fatal_message) %>')
<% end -%>

$.isLoading('hide')
