$.isLoading('hide')
<% if @fatal_message.blank? -%>
preview_window =　window.open("", "", "toolbar=yes,status=no,menubar=yes,scrollbars=yes,resizable")
preview_window.document.write('<%= raw j(@preview_html) %>')
<% else -%>
alert('<%= j(@fatal_message) %>')
<% end -%>
