# lots of stuff taken from https://github.com/yzhang/omniauth/commit/eafc5ff8115bcc7d62c461d4774658979dd0a48e

require 'omniauth-oauth2'

module OmniAuth
  module Strategies
    class Jiepang < OmniAuth::Strategies::OAuth2
      option :client_options, {
        :site          => 'http://jiepang.com/',
        :authorize_url => '/oauth/authorize',
        :token_url     => '/oauth/access_token'
      }

      uid { raw_info['id'] }

      info do
        {
          "uid" => raw_info["id"], 
          "gender"=> raw_info['sex'], 
          "image"=>raw_info['avatar'],
          'name' => raw_info['name'],
          'nickname' => raw_info['nick'],
          'location' => raw_info['city'],
          'email' => raw_info['email'],
          'urls' => {
            'Jiepang' => "http://jiepang.com/user"+ raw_info["id"].to_s
          }
        }
      end
      
      def callback_phase
        if request.params['error'] || request.params['error_reason']
          raise CallbackError.new(request.params['error'], request.params['error_description'] || request.params['error_reason'], request.params['error_uri'])
        end

        self.access_token = build_access_token
        self.access_token = client.auth_code.refresh_token(access_token.refresh_token) if access_token.expired?

        super
      rescue ::OAuth2::Error, CallbackError => e
        puts e.inspect
        fail!(:invalid_credentials, e)
      rescue ::MultiJson::DecodeError => e
        fail!(:invalid_response, e)
      rescue ::Timeout::Error, ::Errno::ETIMEDOUT => e
        fail!(:timeout, e)
      end

      def raw_info
        @raw_info ||= {} #MultiJson.decode(access_token.get("http://api.jiepang.com/v1/account/verify_credentials?access_token=#{@access_token.token}").body)
        puts @raw_info.inspect
        @raw_info
      rescue ::Errno::ETIMEDOUT
        raise ::Timeout::Error
      end
      
      protected
      
      def build_access_token
        puts request.params['code'].inspect
        puts callback_url.inspect
        puts options.token_params.to_hash(:symbolize_keys => true).inspect
        verifier = request.params['code']
        client.auth_code.get_token(verifier, {:redirect_uri => callback_url}.merge(options.token_params.to_hash(:symbolize_keys => true)))
      end
    end
  end
end