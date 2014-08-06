# require 'susanoo/exports/page_creator'

module Susanoo
  class MoveExport < self::Export

    self.lock_file = File.join(Dir.tmpdir, 'move_export.lock')

    #
    #=== Susanoo::Export処理
    #
    def run
      # Creator の logger を move_export.log に変更するための設定
      Susanoo::Exports::Helpers::Logger.logger = ::Logger.new(Rails.root.join('log/move_export.log'))

      # Susanoo::Export で追加したジョブは、Susanoo::Export で処理させないようにする設定。
      #
      # 尚、この設定は Susanoo::Export 側で queue を指定していない場合のみ有効
      Job.create_with(queue: Job.queues[:move_export]).scoping do
        super
      end
    end

    private

      def select_jobs
        Job.queue_eq(:move_export).datetime_is_nil_or_le(Time.zone.now).where(action: self.action_methods.to_a)
      end
  end
end
