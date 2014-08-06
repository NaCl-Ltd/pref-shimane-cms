#
# 表示中のViewの名前を取得するために active_template を追加する
#
class ActionController::Base
  helper_method :template_virtual_path, :template_uniq_id, :template_scope

  attr_accessor :active_template

  #
  #=== 表示するテンプレートのパスを返す
  #
  def template_virtual_path
    self.active_template.virtual_path if self.active_template
  end

  #
  #=== 表示するテンプレートのユニークIDを返す
  #
  def template_uniq_id
    template_virtual_path ? template_virtual_path.split("/").join("-") : nil
  end

  #
  #=== 表示するテンプレートのユニークIDを返す
  #
  def template_scope
    template_virtual_path ? template_virtual_path.split("/") : nil
  end
end

#
# render_template の処理前に表示するViewのインスタンスをコントローラに渡す
#
class ActionView::TemplateRenderer

  alias_method :_render_template_original, :render_template

  def render_template(template, layout_name = nil, locals = {})
    if @view.controller && @view.controller.respond_to?('active_template=')
      @view.controller.active_template = template 
    end
    result = _render_template_original( template, layout_name, locals)
    if @view.controller && @view.controller.respond_to?('active_template=')
      @view.controller.active_template = nil
    end
    
    return result
  end
end
