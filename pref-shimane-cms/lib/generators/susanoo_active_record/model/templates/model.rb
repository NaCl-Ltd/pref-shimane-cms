<% module_namespacing do -%>
class <%= class_name %> < <%= parent_class_name.classify %>
  include Concerns::<%= class_name %>::Association
  include Concerns::<%= class_name %>::Validation
  include Concerns::<%= class_name %>::Method
end
<% end -%>
