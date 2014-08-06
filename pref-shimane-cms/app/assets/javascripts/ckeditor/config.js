/*
Copyright (c) 2003-2011, CKSource - Frederico Knabben. All rights reserved.
For licensing, see LICENSE.html or http://ckeditor.com/license
*/

CKEDITOR.dom.document.prototype.write = function (html) {
  this.$.open( 'text/html', 'replace' );
  if ( CKEDITOR.env.ie ){
    html = html.replace( /<\/title>/i, '$&\n<meta http-equiv="X-UA-Compatible" content="IE=Edge" />\n<script data-cke-temp="1">(' + CKEDITOR.tools.fixDomain + ')();</script>' );
  }
  this.$.write( html );
  this.$.close();
};

CKEDITOR.editorConfig = function( config )
{
  // Define changes to default configuration here. For example:
  config.language = 'ja';
  // config.uiColor = '#AADC6E';

  config.shiftEnterMode = CKEDITOR.ENTER_P;

  config.image_previewText = CKEDITOR.tools.repeat( ' ', 1 );

  /* Filebrowser routes */
  // The location of an external file browser, that should be launched when "Browse Server" button is pressed.
  config.filebrowserBrowseUrl = "/susanoo/page_assets/attachment_files";

  // The location of an external file browser, that should be launched when "Browse Server" button is pressed in the Flash dialog.
  config.filebrowserFlashBrowseUrl = "/susanoo/page_assets/attachment_files";

  // The location of a script that handles file uploads in the Flash dialog.
  config.filebrowserFlashUploadUrl = "/susanoo/page_assets/upload_attachment_file";

  // The location of an external file browser, that should be launched when "Browse Server" button is pressed in the Link tab of Image dialog.
  config.filebrowserImageBrowseLinkUrl = "/susanoo/page_assets/images";

  // The location of an external file browser, that should be launched when "Browse Server" button is pressed in the Image dialog.
  config.filebrowserImageBrowseUrl = "/susanoo/page_assets/images";

  // The location of a script that handles file uploads in the Image dialog.
  config.filebrowserImageUploadUrl = "/susanoo/page_assets/upload_image";

  // The location of a script that handles file uploads.
  config.filebrowserUploadUrl = "/susanoo/page_assets/upload_attachment_file";

  // Rails CSRF token
  config.filebrowserParams = function(){
    var csrf_token, csrf_param, meta,
        metas = document.getElementsByTagName('meta'),
        params = new Object();

    for ( var i = 0 ; i < metas.length ; i++ ){
      meta = metas[i];

      switch(meta.name) {
        case "csrf-token":
          csrf_token = meta.content;
          break;
        case "csrf-param":
          csrf_param = meta.content;
          break;
        default:
          continue;
      }
    }

    if (csrf_param !== undefined && csrf_token !== undefined) {
      params[csrf_param] = csrf_token;
    }

    return params;
  };

  config.addQueryString = function( url, params ){
    var queryString = [];

    if ( !params ) {
      return url;
    } else {
      for ( var i in params )
        queryString.push( i + "=" + encodeURIComponent( params[ i ] ) );
    }

    return url + ( ( url.indexOf( "?" ) != -1 ) ? "&" : "?" ) + queryString.join( "&" );
  };

  // リンク挿入と、画像挿入ダイアログののタブ制限
  config.removeDialogTabs = 'image:advanced;image:Link;link:advanced';

  // Integrate Rails CSRF token into file upload dialogs (link, image, attachment and flash)
  CKEDITOR.on( 'dialogDefinition', function( ev ){
    // Take the dialog name and its definition from the event data.
    var dialogName = ev.data.name;
    var dialogDefinition = ev.data.definition;
    var content, upload;

    if (CKEDITOR.tools.indexOf(['link', 'image', 'attachment', 'flash'], dialogName) > -1) {
      content = (dialogDefinition.getContents('Upload') || dialogDefinition.getContents('upload'));
      upload = (content == null ? null : content.get('upload'));

      if (upload && upload.filebrowser && upload.filebrowser['params'] === undefined) {
        upload.filebrowser['params'] = config.filebrowserParams();
        upload.action = config.addQueryString(upload.action, upload.filebrowser['params']);
      }

      if ( dialogName == 'link' ){
        var infoTab = dialogDefinition.getContents('info');
        infoTab.get('protocol')['items'].splice(2,2);
      }
    }
  });
};
