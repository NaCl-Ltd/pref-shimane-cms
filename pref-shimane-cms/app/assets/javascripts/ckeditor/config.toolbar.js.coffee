#
# CKEditorのツールバー定義
#
this.Toolbar = {
  full: [
    { name: 'document' , items : [ 'Source','-','Save','NewPage','DocProps','Preview','Print','-','Templates' ] },
    { name: 'clipboard', items : [ 'Cut','Copy','Paste','PasteText','PasteFromWord','-','Undo','Redo' ] },
    { name: 'editing'  , items : [ 'Find','Replace','-','SelectAll','-','SpellChecker', 'Scayt' ] },
    { name: 'forms', items : [ 'Form', 'Checkbox', 'Radio', 'TextField', 'Textarea', 'Select', 'Button', 'ImageButton', 'HiddenField' ] },
    '/',
    { name: 'basicstyles', items : [ 'Bold','Italic','Underline','Strike','Subscript','Superscript','-','RemoveFormat' ] },
    { name: 'paragraph', items : [ 'NumberedList','BulletedList','-','Outdent','Indent','-','CreateDiv',
    '-','JustifyLeft','JustifyCenter','JustifyRight','JustifyBlock','-','BidiLtr','BidiRtl' ] },
    { name: 'links', items : [ 'Link','Unlink','Anchor' ] },
    { name: 'insert', items : [ 'Image','Flash','Table','HorizontalRule','Smiley','SpecialChar','PageBreak','Iframe' ] },
    '/',
    { name: 'styles', items : [ 'Styles','Format','Font','FontSize' ] },
    { name: 'tools', items : [ 'Maximize', 'ShowBlocks','-','About'] }
  ],
  standard: [
    { name: 'clipboard', items : [ 'Cut','Copy','Paste','PasteText','-','Undo','Redo' ] },
    { name: 'basicstyles', items : [ 'Bold','Italic','Underline','Strike','RemoveFormat' ] },
    { name: 'paragraph', items : [ 'NumberedList','BulletedList','-','Outdent','Indent'] },
    { name: 'styles', items : [ 'Format','FontSize' ] },
  ],
  header: [
    { name: 'basicstyles', items : ['RemoveFormat' ] },
    { name: 'paragraph', items : ['JustifyLeft','JustifyCenter','JustifyRight','JustifyBlock'] },
    { name: 'styles', items : ['language', 'letterspacing'] },
  ],
  div: [
    { name: 'basicstyles', items : ['Italic','Underline','Subscript','Superscript','RemoveFormat' ] },
    { name: 'clipboard', items: ['Undo','Redo'] },
    { name: 'paragraph', items : [ 'NumberedList','BulletedList','-','Outdent','Indent','-','JustifyLeft','JustifyCenter','JustifyRight','JustifyBlock'] },
    { name: 'styles', items : ['language', 'letterspacing'] },
    { name: 'links', items : [ 'Link','Unlink'] },
    { name: 'insert', items : [ 'Image','jisxtable','HorizontalRule'] },
  ],
  mobile: [
    { name: 'basicstyles', items : [ 'Bold','Italic','Strike','RemoveFormat' ] },
    { name: 'clipboard', items : [ 'Undo','Redo' ] },
    { name: 'paragraph', items : [ 'NumberedList','BulletedList','-','Outdent','Indent'] },
    { name: 'links', items : [ 'Link','Unlink'] },
    { name: 'insert', items : [ 'HorizontalRule'] }
  ],
  uploadable: [
    { name: 'basicstyles', items : [ 'Bold','Italic','Underline' ] },
    { name: 'paragraph', items : [ 'NumberedList','BulletedList','-','JustifyLeft','JustifyCenter','JustifyRight' ] },
    { name: 'links', items : [ 'Link','Unlink' ] },
    { name: 'insert', items : [ 'Image','Table' ] },
  ],
}
