module Concerns::HelpCategory::Method
  extend ActiveSupport::Concern

  included do
    MAX_CHILD_COUNT = 2

    BIG_CATEGORY_NAME = 'big_category'
    MIDDLE_CATEGORY_NAME = 'middle_category'
    SMALL_CATEGORY_NAME = 'small_category'

    CATEGORY_CLASS = 'folder'
    HELP_CLASS = ''

    default_scope { order(:number) }

    scope :big_categories, -> { where('parent_id IS NULL') }
    scope :search, -> (keyword) { where("name LIKE ?", "%#{keyword}%") }

    before_create :set_number!

    #
    #=== フォルダのフルパスの配列を返す
    #
    def fullpath
      _path = self.ancestors.empty? ? [] : self.ancestors.reverse
      _path << self
      _path
    end

    def addable
      self.ancestors.count < MAX_CHILD_COUNT
    end

    def set_number!
      maximum_number = HelpCategory.where(parent_id: self.parent_id).maximum(:number)
      self.number = maximum_number ? maximum_number + 1 : 0
    end

    def change_parent!(parent_id: nil)
      self.parent_id = parent_id
      self.set_number!
      self.save!
    end

    def get_category_name
      if self.parent_id.nil?
        return BIG_CATEGORY_NAME
      else
        if self.parent.parent_id.nil?
          return MIDDLE_CATEGORY_NAME
        else
          return SMALL_CATEGORY_NAME
        end
      end
    end

    def all_children
      self_and_children.map{|h_c| h_c == self ? h_c : h_c.all_children}.flatten
    end
  end

  module ClassMethods
    def siblings_for_treeview(id=nil)
      help_categories = if id.present?
        where('parent_id = ?', id)
      else
        big_categories
      end

      h_cs = help_categories.map { |h_c|
        { id: h_c.id,
          title: h_c.name,
          navigation: h_c.navigation,
          parent_id: h_c.parent_id,
          lazy: h_c.children.present?,
          expanded: false,
        }
      }
      if id
        return h_cs
      else
        title = I18n.t('susanoo.admin.help_categories.index.title')
        return [{
          title: title,
          children: h_cs,
          id: nil,
          navigation: false,
          expanded: true}]
      end
    end

    def category_and_help_for_treeview(id: nil, expanded: nil)
      category_and_helps = if id.present?
        where('parent_id = ?', id).to_a.concat(
          ::Help.where('help_category_id = ?', id).showing.to_a)
      else
        big_categories
      end
      category_and_helps.map do |c_h|
        tree_json = {
          id: c_h.id,
          title: c_h.name,
          datatype: c_h.instance_of?(::HelpCategory) ? CATEGORY_CLASS : HELP_CLASS
        }
        if expanded
          help_category = expanded.instance_of?(::HelpCategory) ? expanded : find(expanded)
          help_categories = help_category.ancestors.unshift(help_category).map(&:id)
          if c_h.id.in?(help_categories)
            tree_json[:expanded] = true
            tree_json[:children] = category_and_help_for_treeview(id: c_h.id, expanded: help_category)
          end
        else
          if c_h.instance_of?(::HelpCategory)
            if c_h.helps.present? || c_h.children.present?
              tree_json[:expanded] = false
              tree_json[:lazy] = true
            else
              tree_json[:expanded] = false
              tree_json[:lazy] = false
            end
          end
        end
        tree_json
      end
    end

    def category_and_help_search(keyword)
      if keyword.blank?
        category_and_help_for_treeview
      else
        help_categories = ::HelpCategory.search(keyword).to_a
        helps = ::Help.showing.search(keyword)
        help_categories.concat(helps).map do |h_c|
          data = {
            id: h_c.id,
            title: h_c.name
          }
          if h_c.instance_of?(::HelpCategory)
            data[:datatype] = CATEGORY_CLASS
            data[:expanded] = false
            if h_c.helps.present? || h_c.children.present?
              data[:lazy] = true
            else
              data[:lazy] = false
            end
          else
            data[:datatype] = HELP_CLASS
          end
          data
        end
      end
    end

    #
    #=== 指定したフォルダまで辿った状態のツリービューを返す
    #
    def selected_treeview(selected)
      if selected.present?
        categories = where(parent_id: selected.parent_id)
        data = build_treeview(categories, selected)
        build_treeview_throwback(selected.parent, data)
      end
    end

    def build_treeview(categories, selected = nil)
      categories.inject([]) do |a, c|
        data = {
          id: c.id,
          title: c.name,
          folder: true,
          active: (c.id == selected.try(:id)),
          expanded: false,
          lazy: c.children.present?
        }
        a << data
      end
    end

    #
    #===
    #
    def build_treeview_throwback(category, data)
      if category.present?
        parents = where(parent_id: category.parent_id)
        parent_data = build_treeview(parents)
        parent_data.each do |d|
          if d[:id] == category.id
            d[:lazy] = false
            d[:expanded] = true
            d[:children] = data
          end
        end
        build_treeview_throwback(category.parent, parent_data)
      else
        return [{
          title: I18n.t('susanoo.admin.help_categories.index.title'),
          children: data,
          id: nil,
          navigation: false,
          expanded: true}]
      end
    end
  end
end
