require_dependency BrowsingSupport::Engine.root.join('lib/browsing_support/rubi_adder').to_s

class ApplicationController < ActionController::Base

  private

    def rubi_filter
      return unless Mime[:html] == content_type
      return unless cookies['ruby'] && cookies['ruby'] == 'on'
      response.body = BrowsingSupport::RubiAdder.add(response.body)
    end
end
