module ApplicationHelper

  #
  #=== モデルインスタンスのエラーメッセージを整形して返す。
  #
  def error_messages_for(model_instance)
    return "" if model_instance.errors.empty?
    error_messages(model_instance.errors.full_messages)
  end

  #
  #=== エラーメッセージを整形して表示する。
  #
  def error_messages(messages)
    return "" if messages.empty?
    html = content_tag(:div, class: "alert fade in alert-error") do
      div = content_tag(:button, "×", class: "close", "data-dismiss" =>  "alert")
      div += content_tag(:ul) do
        ul = messages.map do |fm|
          content_tag(:li) do
            content_tag(:span, fm)
          end
        end.join
        raw(ul)
      end
      div
    end
    return html
  end

  #
  #=== News用のstrftime
  #
  def news_strftime(time)
    f = t("date.formats.news")
    time.strftime(f) rescue f.gsub(/[\%\_m|\%\_d]/, "?")
  end

  def news_strftime_for_dl_genre_plugin(time)
    f = t("date.formats.news_year")
    time.strftime(f) rescue f.gsub(/[\%\_m|\%\_d]/, "?")
  end

  #
  #=== 公開期間
  #
  def public_term_strftime(time)
    f = t("date.formats.public_term")
    time.strftime(f) rescue ''
  end

  #
  #=== 指定したフォーマットの日付文字列を返す
  #
  def date_text(object, format_name = :default)
    object.present? ? object.strftime(t("date.formats.#{format_name}")) : ""
  end

  #
  #=== 指定したフォーマットの日付文字列を返す
  #
  def date_term_text(start_at, end_at, format_name = :default)
    if start_at || end_at
      format = t("date.formats.#{format_name}")
      text = start_at.present? ? start_at.strftime(format) : t("shared.no_term")
      text += t("shared.term_separator")
      text += end_at.present? ? end_at.strftime(format) : t("shared.no_term")
    else
      t("shared.no_term")
    end
  end

  #
  #=== 新規作成用リンクボタンを表示する
  #
  def link_to_new(url, options = {})
    label = options.delete(:label) || t(".new")
    _link_to(label, url, {class: "btn btn-primary"}.merge(options), {class: "icon-plus"})
  end

  #
  #=== 編集用リンクボタンを表示する
  #
  def link_to_edit(url, options = {})
    label = options.delete(:label) || t("shared.edit")
    _link_to(label, url, {class: "btn btn-success"}.merge(options), {class: "icon-edit"})
  end

  #
  #=== 削除用リンクボタンを表示する
  #
  def link_to_remove(url, options = {})
    label = options.delete(:label) || t("shared.delete")
    link_options = {
      class: "btn btn-danger",
      method: :delete,
      data: { confirm: t("shared.confirm.delete") }
    }.merge(options)
    _link_to(label, url, link_options, {class: "icon-remove"})
  end

  #
  #=== 詳細用リンクボタンを表示する
  #
  def link_to_show(url, options = {})
    label = options.delete(:label) || t("shared.show")
    _link_to(label, url, {class: "btn btn-info"}.merge(options), {class: "icon-file"})
  end

  #
  #=== 戻るリンクボタンを表示する
  #
  def link_to_back(url, options = {})
    label = options.delete(:label) || t("shared.back")
    _link_to(label, url, {class: "btn btn-warning"}.merge(options), {class: "icon-arrow-left"})
  end

  #
  #=== フォルダのフルパスを表示する
  #
  def genre_fullpath(genre, options= {})
    return nil if genre.nil?

    separator = options[:separator] || " > "
    text = genre.fullpath.map {|_| _.title }.join(separator)
    text.html_safe
  end

  #
  #=== ページのフルパスを表示する
  #
  def page_fullpath(page, options= {})
    return nil if page.nil?

    separator = options[:separator] || " > "
    fullpath = page.genre.fullpath.map {|_| _.title }
    fullpath << page.title
    fullpath.join(separator).html_safe
  end

  #
  #=== コンテンツに埋め込むプラグイン一覧
  #
  def page_content_plugins
    Settings.plugins.editor.pc.try(:to_h) || {}
  end

  #
  #=== コンテンツに埋め込み用のカテゴライズされたプラグイン一覧を返します。
  #
  def page_editor_categorized_plugins(view_type = :pc)
    c = case view_type
        when :pc      ; Settings.plugins.editor.pc
        when :mobile  ; Settings.plugins.editor.mobile
        when :template; Settings.plugins.editor.template
        else          ; Settings.plugins.editor.pc
        end
    c.try(:to_h) || {}
  end

  #
  #=== コンテンツに埋め込み用のプラグイン一覧を返します
  #
  def page_editor_all_plugins(view_type = :pc)
    page_editor_categorized_plugins(view_type).values.flatten
  end

  #
  #=== プラグイン一覧に表示しないプラグイン一覧を返します
  #
  def page_editor_hidden_plugins(view_type = :pc)
    Settings.plugins.editor.hidden || []
  end

  #
  #=== カテゴリ用アイコンの名前を返します
  #
  def page_editor_widget_category_icon(category, default_icon = nil)
    Settings.plugins.editor.category_icon.to_h[category] || default_icon
  end

  #
  #=== コンテンツ用Widgetを表示する
  #
  def page_editor_widgets_contents
    contents = ['h1', 'h2', 'h3', 'h4', 'h5', 'h6'].map do |tag|
      text = t("widgets.examples.#{tag}")
      {name: tag, type: "inline", data: "<div class='editable data-type-h'><#{tag}>#{text}</#{tag}></div>"}
    end
    contents << { name: "div", type: "inline", data: "<div class='editable data-type-div'><p>#{t("widgets.examples.div")}</p></div>"}
    _widget_content(:content, contents)
  end

  #
  #=== sectionのセレクトを生成
  #
  def options_for_select_with_sections(sections, selected = "")
    lists = sections.map{|s|[s.name, s.id]}
    options_for_select(lists, selected)
  end

  #
  #=== divisionのセレクトを生成
  #
  def options_for_select_with_divisions(divisions, selected = "")
    lists = divisions.map{|s|[s.name, s.id]}
    options_for_select(lists, selected)
  end

  #
  #=== plugin呼び出し
  #
  def plugin(template_name, *args)
    render template: "plugins/#{template_name}", :locals => {:args => args}
  end

  def format_address(str)
    str.collect{|i|
      i.gsub(/[A-Za-z0-9;\/?:&=+$,\-_.!~*\'()#%]+@#{Regexp.quote(Settings.mail_domain)}/, '<a href="mailto:\&">\&</a>')
    }.join('<br />')
  end

  #
  # ページ情報からページ公開の状態遷移テーブルを表示する
  #
  def page_transitions_table_by_admission(page)
    if page.present?
      if page.latest_content.present?
        current_step = 7
      elsif page.request_content.present?
        current_step = 5
      else
        current_step = 3
      end
    else
      current_step = 1
    end
    page_transitions_table(current_step)
  end

  #
  #=== ページ公開の状態遷移テーブルを表示する
  #
  def page_transitions_table(current_step)
    transitions = []
    6.times {|i| transitions << t("shared.transitions.step#{i+1}")}

    html = content_tag(:table, class: "table table-transitions") do
      tr = ""
      transitions.each_with_index do |t, i|
        step = i + 1
        if current_step == step
          tr_class = "current"
        elsif current_step > step
          tr_class = "done"
        else
          tr_class = ""
        end
        tr += content_tag(:tr, class: tr_class) do
          td = ''
          td += content_tag(:td, '', class: 'detail') do
            _td = content_tag(:span, "#{step}", class: "wizard-step-number")
            _td += content_tag(:span, t, class: 'wizard-step-label')
            _td.html_safe
          end
          td.html_safe
        end
      end
      tr.html_safe
    end
    html.html_safe
  end

  #
  #=== リンク先をポップアップ表示する
  #
  def popup_link_to(name, options = {}, html_options = {})
    url = url_for(options)
    html_options = html_options.merge(:onclick => raw("window.open('#{escape_javascript(url)}', '', 'toolbar=yes,status=no,menubar=yes,scrollbars=yes,resizable');return false;"))
    link_to(name, options, html_options)
  end

  #
  #=== アクセシビリティチェック成功のメッセージを返す
  #
  def accessibility_success_messages
    content_tag(:div, class: "accessibility-message bootstrap") do
      content_tag(:div, class: "alert alert-success") do
        t('shared.accessibility.success')
      end.html_safe
    end.html_safe
  end

  #
  #=== アクセシビリティチェック成功のメッセージを返す
  #
  def accessibility_messages(severity, errors)
    return if errors.blank?
    content_tag(:div, class: 'accessibility-message bootstrap') do
      content_tag(:div, class: "alert alert-#{severity}") do
        html = ""
        if severity != 'error'
          html += content_tag(:button, 'x', class: 'close', "data-dismiss" => 'alert')
        end
        html += content_tag(:p, t("shared.accessibility.#{severity}", count: errors.size))
        html += content_tag(:ul) do
          ul = errors.map do |e|
            options = { scope:'accessibility.errors', default: e['description'] }
            if e['args'].present?
              e['args'].each_with_index { |a, i| options["arg#{i+1}".to_sym] = a }
            else
              options[:arg1] = e['target']
            end
            message = t(e['id'].gsub("\.", "_"), options)
            content_tag(:li) { content_tag(:span, "#{e['id']}:#{message}") }
          end.join
          ul.html_safe
        end
        html.html_safe
      end.html_safe
    end.html_safe
  end

  #
  #=== ジャンルタイトルと、ジャンルのフルパスを一緒に表示する
  #
  def genre_title_with_fullpath(genre)
    genre.title + "(#{genre_fullpath(genre)})"
  end

  #
  #===　ページエディター用モデルインスタンスのエラーメッセージを整形して返す。
  #
  def page_editor_error_messages_for(model_instance)
    return "" if model_instance.errors.empty?
    content_tag(:div, class: 'accessibility-message bootstrap') do
      error_messages(model_instance.errors.full_messages).html_safe
    end
  end

  #
  #===　所属に設定した住所を表示する
  #
  def format_address(str)
    str.lines.collect{|i|
      h(i).gsub(/[A-Za-z0-9;\/?:&=+$,\-_.!~*\'()#%]+@#{Regexp.quote(Settings.mail.domain)}/, '<a href="mailto:\&">\&</a>')
    }.join('<br />').html_safe
  end

  #
  #=== digest なしの JavaScript タグを返す
  #
  def javascript_include_tag_nodigest(path)
    content_tag(:script, "", src: File.join(Rails.configuration.assets.prefix, "#{path}.js",))
  end

  #
  # エンジンのルートパスを返す
  #
  def engine_root_path(engine)
    begin
      engine_name = engine.to_s.downcase.camelize
      engine_module = Module.const_get("::#{engine_name}::Engine")
      engine_module.routes.url_helpers.root_path
    rescue
      # DBでエンジンが有効になっているが、Gemfile/routes.rb からエンジンが除外されている場合は nil を返す
      nil
    end
  end
  module_function :page_content_plugins

  private

    #
    #=== リンクボタンを生成する
    #
    def _link_to(label, url, link_options, text_options)
      if link_options[:disabled]
        url = "#"
        link_options.delete(:method)
        link_options[:data].delete(:confirm) if link_options[:data] && link_options[:data][:confirm]
      end

      pull_right = link_options.delete(:pull_right) || false
      link_options[:class] += " pull-right" if pull_right
      link_options[:class] += " btn-small"

      link_to url, link_options do
#        h = content_tag :i, nil, text_options  # アイコンとテキストが被るため、無効化
        h = ""
        h += " "+ label
        h.html_safe
      end
    end

    #
    #=== ページ編集用ウィジェットを生成する
    #
    def _widget_content(name, items)
      li = ""
      items.each do |item|
        li += content_tag(:li,
          t(item[:name], scope: "widgets.items"),
          "id"           => "jquery-ui-effect_" + item[:name],
          "name"         => item[:name],
          "class"        => "widget-item",
          "data-type"    => item[:type],
          "data-default" => item[:data])
      end
      li.html_safe
    end

    #
    #=== ページ編集用ウィジェットの項目を生成する
    #
    def _widget_item(name, options = {})
      content_tag(:li,
        t(name, scope: "widgets.items"),
        "name"         => name,
        "class"        => "widget-item",
        "data-type"    => options[:type],
        "data-default" => options[:data]
      )
    end
end
