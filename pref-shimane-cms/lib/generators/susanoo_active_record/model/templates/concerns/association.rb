<% module_namespacing do -%>
module Concerns::<%= class_name %>::Association
  extend ActiveSupport::Concern

  included do
<% attributes.select(&:reference?).each do |attribute| -%>
    belongs_to :<%= attribute.name %><%= ', polymorphic: true' if attribute.polymorphic? %>
<% end -%>
<% if attributes.any?(&:password_digest?) -%>
    has_secure_password
<% end -%>
  end
end
<% end -%>
