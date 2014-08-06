$('.iframe-edit').contents().find("#content").html('<%= raw escape_javascript(@page_content.edit_style_content) %>')

doc = $(".iframe-edit")[0].contentWindow
doc.Public.Editor.contents = []
doc.Public.Editor.setup_content()

