require 'susanoo/exports/helpers/path_helper'

module BrowsingSupport
  module Exports
    module Helpers
      module PathHelper
        include ::Susanoo::Exports::Helpers::PathHelper

        #
        #=== 引数渡されたパスを、エクスポートするパスに変更して返す
        #
        def arg_to_path(arg)
          path = case arg
          when /\Ap:(\d+)\z/; Page.find($1.to_i).path
          when /\Ag:(\d+)\z/; Genre.find($1.to_i).path
          else                arg
          end
          return path_with_type(path, :html)
        end
      end
    end
  end
end

