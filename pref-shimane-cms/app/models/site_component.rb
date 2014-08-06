class SiteComponent < ActiveRecord::Base
  include Concerns::SiteComponent::Association
  include Concerns::SiteComponent::Validation
  include Concerns::SiteComponent::Method
end
