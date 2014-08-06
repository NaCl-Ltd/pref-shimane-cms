#
# CKEditorの使用可能タグ・属性定義
#
this.AllowedContent = {
  #
  # 通常ページ
  #
  #
  standard: {
    br: true,
    a:{
      attributes: 'accesskey,charset,class,hreflang,href,id,name,rel,rev,lang,style,tabindex,type,title'
      styles: '*'
      classes: '*'
    },
    span: {
      attributes: 'align,class,style,dir,lang'
      styles: '*'
      classes: '*'
    },
    'address h1 h2 h3 h4 h5 h6 p pre': {
      attributes: 'align,class,style'
      styles: '*'
      classes: '*'
    },
    'em li hr ol sub sup strike strong u ul': {
      attributes: 'class,style'
      styles: '*'
      classes: '*'
    },
    div: {
      attributes: 'align,class,id,style'
      styles: '*'
      classes: '*'
    },
    caption: {
      attributes: 'class,id,lang,style'
      styles: '*'
      classes: '*'
    },
    img: {
      attributes: 'align,alt,border,class,lang,longdesc,height,hspace,id,src,style,title,vspace,width,usemap'
      styles: '*'
      classes: '*'
    },
    table: {
      attributes: 'align,cellpadding,cellspacing,class,id,lang,style,summary,width'
      styles: '*'
      classes: '*'
    },
    tr: {
      attributes: 'align,class,id,lang,rowspan,style,valign'
      styles: '*'
      classes: '*'
    },
    'td th': {
      attributes: 'align,class,colspan,height,id,lang,rowspan,scope,style,valign,width'
      styles: '*'
      classes: '*'
    },
    button: {
      attributes: 'class,name,value'
      styles: '*'
      classes: '*'
    }
  },

  #
  # 携帯用の使用可能タグ
  #
  mobile: {
    'em li ol pre strike strong sub sup u ul': true,
    a: {
      attributes: 'accesskey,href,name'
    },
    'div h1 h2 h3 h4 h5 h6 hr p': {
      attributes: 'align'
    },
    br: {
      attributes: 'clear'
    },
    span: {
      attributes: 'class'
      classes: '*'
    },
    button: {
      attributes: 'class,name,value'
      styles: '*'
      classes: '*'
    }
  },

  #
  # お知らせ、緊急情報の使用可能タグ
  #
  info: {
    'em li ol pre strike strong sub sup u ul': true,
    a: {
      attributes: 'accesskey,href,name'
    },
    'p div h1 h2 h3 h4 h5 h6 hr': {
      attributes: 'align'
    },
    br: {
      attributes: 'clear'
    },
    button: {
      attributes: 'class,name,value'
      styles: '*'
      classes: '*'
    }
  }
}
