class AdminInfoForm
  init: ->
    editor =  CKEDITOR.replace( 'info_content', {
      toolbar: Toolbar.standard,
      allowedContent: AllowedContent.info
    })

Susanoo.Admin or= {}
Susanoo.Admin.Info or= {}
Susanoo.Admin.Info.Form = new AdminInfoForm
