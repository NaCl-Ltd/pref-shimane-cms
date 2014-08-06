/**
 * @license Copyright (c) 2003-2013, CKSource - Frederico Knabben. All rights reserved.
 * For licensing, see LICENSE.md or http://ckeditor.com/license
 */

CKEDITOR.plugins.add( 'jisxtable', {
  requires: 'dialog',
  lang: 'ja,en', // %REMOVE_LINE_CORE%
  icons: 'jisxtable', // %REMOVE_LINE_CORE%
  hidpi: true, // %REMOVE_LINE_CORE%
  init: function( editor ) {
    if ( editor.blockless )
      return;

    var table = CKEDITOR.plugins.table,
      lang = editor.lang.table;

    editor.addCommand( 'jisxtable', new CKEDITOR.dialogCommand( 'jisxtable', {
      context: 'table',
      allowedContent: 'table{width,height}[align,border,cellpadding,cellspacing,summary];' +
        'caption tbody thead tfoot;' +
        'th td tr[scope];' +
        ( editor.plugins.dialogadvtab ? 'table' + editor.plugins.dialogadvtab.allowedContent() : '' ),
      requiredContent: 'table',
      contentTransformations: [
        [ 'table{width}: sizeToStyle', 'table[width]: sizeToAttribute' ]
      ]
    } ) );

    function createDef( def ) {
      return CKEDITOR.tools.extend( def || {}, {
        contextSensitive: 1,
        refresh: function( editor, path ) {
          this.setState( path.contains( 'table', 1 ) ? CKEDITOR.TRISTATE_OFF : CKEDITOR.TRISTATE_DISABLED );
        }
      });
    }

    editor.addCommand( 'jisxtableProperties', new CKEDITOR.dialogCommand( 'jisxtableProperties', createDef() ) );
    editor.addCommand( 'jisxtableHeaderId', new CKEDITOR.dialogCommand( 'jisxtableHeaderId', createDef() ) );
    editor.addCommand( 'jisxtableDataHeaders', new CKEDITOR.dialogCommand( 'jisxtableDataHeaders', createDef() ) );
    editor.addCommand( 'jisxtableDelete', createDef({
      exec: function( editor ) {
        var path = editor.elementPath(),
          table = path.contains( 'table', 1 );

        if ( !table )
          return;

        // If the table's parent has only one child remove it as well (unless it's the body or a table cell) (#5416, #6289)
        var parent = table.getParent();
        if ( parent.getChildCount() == 1 && !parent.is( 'body', 'td', 'th' ) )
          table = parent;

        var range = editor.createRange();
        range.moveToPosition( table, CKEDITOR.POSITION_BEFORE_START );
        table.remove();
        range.select();
      }
    }));

    editor.ui.addButton && editor.ui.addButton( 'jisxtable', {
      label: lang.toolbar,
      command: 'jisxtable',
      toolbar: 'insert,30'
    });

    CKEDITOR.dialog.add( 'jisxtable', this.path + 'dialogs/table.js' );
    CKEDITOR.dialog.add( 'jisxtableProperties', this.path + 'dialogs/table.js' );
    CKEDITOR.dialog.add( 'jisxtableHeaderId', this.path + 'dialogs/table.js' );
    CKEDITOR.dialog.add( 'jisxtableDataHeaders', this.path + 'dialogs/table.js' );

    // If the "menu" plugin is loaded, register the menu items.
    if ( editor.addMenuItems ) {
      editor.addMenuItems({
        jisxtable: {
          label: lang.menu,
          command: 'jisxtableProperties',
          group: 'table',
          order: 5
        },

        jisxtableHeaderId: {
          label: '見出しの設定',
          command: 'jisxtableHeaderId',
          group: 'table',
          order: 6
        },

        jisxtableDataHeaders: {
          label: '見出しを指定',
          command: 'jisxtableDataHeaders',
          group: 'table',
          order: 7
        },

        jisxtableDelete: {
          label: lang.deleteTable,
          command: 'jisxtableDelete',
          group: 'table',
          order: 1
        }
      });
    }

    editor.on( 'doubleclick', function( evt ) {
      var element = evt.data.element;

      if ( element.is( 'table' ) )
        evt.data.dialog = 'jisxtableProperties';
    });

    // If the "contextmenu" plugin is loaded, register the listeners.
    if ( editor.contextMenu ) {
      editor.contextMenu.addListener( function() {
        var path = editor.elementPath();
        var td = path.contains( 'td', 1 );
        var th = path.contains( 'th', 1 );

        if (th) {
          menu = {
            jisxtableDelete: CKEDITOR.TRISTATE_OFF,
            jisxtableHeaderId: CKEDITOR.TRISTATE_OFF,
            jisxtable: CKEDITOR.TRISTATE_OFF
          };
        } else if(td) {
          menu = {
            jisxtableDelete: CKEDITOR.TRISTATE_OFF,
            jisxtableDataHeaders: CKEDITOR.TRISTATE_OFF,
            jisxtable: CKEDITOR.TRISTATE_OFF
          };
        } else {
          menu = {
            jisxtableDelete: CKEDITOR.TRISTATE_OFF,
            jisxtable: CKEDITOR.TRISTATE_OFF
          };
        }
        return menu;
      });
    }
  }
});
