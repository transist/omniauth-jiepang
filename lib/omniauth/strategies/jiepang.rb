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

      def raw_info
        @raw_info ||= MultiJson.decode(access_token.get("http://api.jiepang.com/v1/account/verify_credentials?access_token=#{@access_token.token}").body)
        puts @raw_info.inspect
        @raw_info
      rescue ::Errno::ETIMEDOUT
        raise ::Timeout::Error
      end
    end
  end
end