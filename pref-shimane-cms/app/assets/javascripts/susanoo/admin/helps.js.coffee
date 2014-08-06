class AdminHelperForm
  wysiwyg_id: 'help_content_content',
  filebrowserBrowseUrl: '/susanoo/admin/help_content_assets/attachment_files'
  filebrowserImageBrowseLinkUrl: '/susanoo/admin/help_content_assets/images'
  filebrowserImageBrowseUrl: '/susanoo/admin/help_content_assets/images'
  filebrowserImageUploadUrl: '/susanoo/admin/help_content_assets/upload_image'
  filebrowserUploadUrl: '/susanoo/admin/help_content_assets/upload_attachment_file'

  init: (help_content_id)->
    this.filebrowserBrowseUrl += '?help_content_id=' +　help_content_id
    this.filebrowserImageBrowseLinkUrl += '?help_content_id=' +　help_content_id
    this.filebrowserImageBrowseUrl += '?help_content_id=' +　help_content_id
    this.filebrowserImageUploadUrl += '?help_content_id=' +　help_content_id
    this.filebrowserUploadUrl += '?help_content_id=' +　help_content_id

    editor =  CKEDITOR.replace( @wysiwyg_id, {
      toolbar: Toolbar.uploadable,
      filebrowserBrowseUrl: @filebrowserBrowseUrl
      filebrowserImageBrowseLinkUrl: @filebrowserImageBrowseLinkUrl
      filebrowserImageBrowseUrl: @filebrowserImageBrowseUrl
      filebrowserImageUploadUrl: @filebrowserImageUploadUrl
      filebrowserUploadUrl: @filebrowserUploadUrl
    })

Susanoo.Admin or= {}
Susanoo.Admin.Helper or= {}
Susanoo.Admin.Helper.Form = new AdminHelperForm
