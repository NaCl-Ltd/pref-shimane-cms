require 'csv'

module Concerns::WebMonitor::Method
  extend ActiveSupport::Concern

  included do
    paginates_per 10

    status.keys.each do |s|
      scope :"eq_#{s}", ->{
        where(state: status[s])
      }
    end

    before_save :crypt_password, if: :password_changed?
    before_update :mark_edited, if: :auth_data_changed?
    after_destroy :update_htpasswd

    private

      def auth_data_changed?
        password_changed? || login_changed?
      end

      def mark_edited
        self.state = self.class.status[:edited]
      end

      def crypt_password
        self.password = htpasswd(password)
      end

      def htpasswd(pass)
        self.class.htpasswd(pass)
      end

      def update_htpasswd
        if genre.try(:auth?)
          Job.create(action: 'remove_from_htpasswd', arg1: self.genre_id.to_s, arg2: self.login)
        end
      end
  end

  module ClassMethods

    def htpasswd(pass)
      salt = [Kernel.rand(64),Kernel.rand(64)].pack("C*").tr("\x00-\x3f","A-Za-z0-9./")
      pass.crypt(salt)
    end

    def import_csv!(csv, attr = {})
      CSV.parse(csv) do |name, login, password|
        create!(
          attr.merge({
            name: name,
            login: login,
            password: password,
            password_confirmation: password,
          })
        )
      end
    end

    def import_csv_from!(io, attr = {})
      import_csv!(NKF.nkf('-w -m0', io.read), attr)
    end

    def reflect_web_monitors_of(genre)
      WebMonitor.transaction do
        Job.transaction do
          Job.create!(action: 'create_htpasswd', arg1: genre.id.to_s)
          genre.web_monitors.update_all(state: WebMonitor.status[:registered])
        end
      end
    end
  end
end
