require 'omniauth-oauth2'

module OmniAuth
  module Strategies
    class Jiepang < OmniAuth::Strategies::OAuth2
      # Give your strategy a name.
      option :name, "jiepang"

      # This is where you pass the options you would pass when
      # initializing your consumer from the OAuth gem.
      option :client_options, {
        :site => "https://jiepang.com",
        :authorize_url => '/oauth/authorize',
        :token_url     => '/oauth/token'
      }

      # These are called after authentication has succeeded. If
      # possible, you should try to set the UID without making
      # additional calls (if the user id is returned with the token
      # or as a URI parameter). This may not be possible with all
      # providers.
      uid{ raw_info['id'] }

      info do
        {
          :name => raw_info['name'],
          
        }
      end

      extra do
        {
          'raw_info' => raw_info
        }
      end
      
      def signed_params
        params = {}
        params[:access_token] = @access_token.token
        puts "*****params access token"
        puts params.inspect
        params
      end

      def raw_info
        response = Net::HTTP.post_form(URI.parse('http://api.jiepang.com/v1/account/verify_credentials'), signed_params).body
        @raw_info ||= MultiJson.decode(response)[0]
        
        puts "*****@raw_info.inspect"
        puts @raw_info.inspect
        @raw_info
      end
    end
  end
end