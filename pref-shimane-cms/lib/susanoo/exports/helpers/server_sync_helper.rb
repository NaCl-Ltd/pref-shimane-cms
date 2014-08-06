module Susanoo
  module Exports
    module Helpers
      module ServerSyncHelper
        extend ActiveSupport::Concern

        included do
          Susanoo::ServerSync::Worker.action_methods.each do |action|
            define_method(action) do |path|
              job = ::Job.find_or_create_by(action: action, datetime: nil, arg1: path)
              if job
                # Delete scheduled sync jobs
                ::Job.where(action: job.action, arg1: job.arg1)
                  .where(::Job.arel_table[:datetime].gt(Time.zone.now + 1.seconds))
                  .delete_all
              end
            end
          end
        end
      end
    end
  end
end
