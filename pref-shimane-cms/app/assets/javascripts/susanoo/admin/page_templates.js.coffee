class AdminPageTemplateForm
  init: ->
    editor =  CKEDITOR.replace( 'page_template_content', {
      toolbar: Toolbar.standard,
      allowedContent: AllowedContent.standard
      contentsCss: [
        '/assets/public/default.css',
        '/assets/public/color.css',
        '/assets/public/aural.css'
      ]
    })

Susanoo.Admin or= {}
Susanoo.Admin.PageTemplates or= {}
Susanoo.Admin.PageTemplates.Form = new AdminPageTemplateForm
