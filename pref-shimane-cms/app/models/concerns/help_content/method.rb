module Concerns::HelpContent::Method
  extend ActiveSupport::Concern

  included do
    after_create :rename_folder

    paginates_per 10

    private

      def rename_folder
        if temp_key.present?
          path = Rails.root.join('files', 'help', Rails.env)
          if FileTest.exists?(path.join(temp_key))
            self.update(content: content.gsub(temp_key, id.to_s))
            FileUtils.mv(path.join(temp_key), path.join(id.to_s))
          end
        end
      end
  end

  module ClassMethods
  end
end
