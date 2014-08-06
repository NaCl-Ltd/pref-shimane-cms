# -*- coding: utf-8 -*-
module Susanoo
  module Accessibility
    class Michecker < Base

      def validate(target)
        response = send_request(target)
        response_to_messages(response)
      end

      private

        #
        #=== michecker でHTMLをチェックする
        #
        def send_request(target)
          response = nil
          Net::HTTP.start(settings.host, settings.port) do |http|
            http.read_timeout = 300
            header = {'Content-Type' => "application/html"}
            response = http.post(settings.api, target, header)
          end

          if response.code == '200'
            body = response.read_body
            return JSON.parse(body)
          else
            return nil
          end
        end

        #
        #=== micheckerから受け取ったレスポンスのエラー内容を変換する
        #
        def response_to_messages(response)
          response.each do |r|
            severity = nil
            message = r.with_indifferent_access

            settings.policy.each do |policy, codes|
              severity = settings.severity[policy] if codes.include?(message[:id])
            end

            severity = message[:severity] if severity.nil?

            case severity
            when settings.severity.error
              @messages[:error] << message

            when settings.severity.warning
              @messages[:warning] << message

            when settings.severity.user, settings.severity.info
              @messages[:user] << message
            end
          end
          @messages
        end
    end
  end
end
