<% if @messages -%>
html = "<%= j(render(partial: '/shared/help_categories/alert', locals: {type: :success, messages: @messages})) %>"
tree = $('#treeview').fancytree('getTree')
tree.reload(<%= raw @new_tree.to_json %>)
<% else -%>
html = "<%= j(render(partial: '/shared/help_categories/alert', locals: {type: :error, messages: @error_messages})) %>"
<% end -%>
$('#top-message-area').html(html);
