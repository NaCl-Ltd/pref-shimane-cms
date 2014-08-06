module Susanoo
  module Exports
    module Helpers
      module Actionable
        extend ActiveSupport::Concern

        included do
          class_attribute :action_methods
          self.action_methods = Set.new.freeze
        end

        module ClassMethods
          private
            def action_method(*args)
              self.action_methods = action_methods.dup.merge(args.map(&:to_s)).freeze
            end
        end
      end
    end
  end
end
