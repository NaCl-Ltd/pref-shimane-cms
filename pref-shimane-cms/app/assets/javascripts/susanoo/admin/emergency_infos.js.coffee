class AdminEmergencyInfoForm
  init: ->
    editor =  CKEDITOR.replace( 'emergency_info_content', {
      toolbar: Toolbar.standard,
      allowedContent: AllowedContent.info
    })

Susanoo.Admin or= {}
Susanoo.Admin.EmergencyInfo or= {}
Susanoo.Admin.EmergencyInfo.Form = new AdminEmergencyInfoForm
