html = "<%= j(render(partial: "/shared/help_categories/alert", locals: {type: :success, messages: @messages})) %>"
if ($(html).hasClass('alert-success'))
  tree = $('#treeview').fancytree('getTree')
  tree.reload(<%= raw @new_tree.to_json %>)
$('#top-message-area').html(html);
$('#center-form-area').empty()
