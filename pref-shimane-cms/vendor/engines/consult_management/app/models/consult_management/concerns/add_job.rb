module ConsultManagement
  module Concerns
    module AddJob
      extend ActiveSupport::Concern
      JOB_ACTION = 'create_consult_json'

      included do
        before_save :add_job
      end


      def add_job
        Job.find_or_create_by(action: JOB_ACTION)
      end
    end
  end
end
