@help_categories = HelpCategory.where(parent_id: params[:help_category_id])
json.array!(@help_categories) do |json, h_c|
  json.id h_c.id
  json.name h_c.name
end
