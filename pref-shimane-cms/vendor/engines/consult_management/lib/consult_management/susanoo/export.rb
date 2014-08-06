require "consult_management/susanoo/exports/json_creator"

module ConsultManagement
  module Susanoo
    module Export
      extend ActiveSupport::Concern

      included do
        action_method :create_consult_json
      end

      #
      #=== 相談窓口管理機能用JSON作成
      #
      # Jobのアクションに'create_consult_json'が入っている時に、sendにより呼び出される
      def create_consult_json
        json_creator = Exports::JsonCreator.new
        json_creator.make
      end

    end
  end
end
