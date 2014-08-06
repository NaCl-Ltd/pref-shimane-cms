module ConsultManagement
  module Susanoo
    module Exports
      class JsonCreator < ::Susanoo::Exports::Creator::Base
        FILE_PATH = File.join(Settings.consult_management.data.dir, Settings.consult_management.data.json.path)

        #
        #=== 初期化
        #
        def initialize
          @consults = Consult.select(:id, :name, :link, :work_content, :contact)
        end

        #
        #=== JSONファイルを作成する
        #
        def make
          consult_json = @consults.map{|c|
            c.attributes.merge(consult_category_ids: c.consult_categories.pluck(:id))
          }.to_json

          write_file(FILE_PATH, consult_json)
          sync_docroot(FILE_PATH)
        end
      end
    end
  end
end
