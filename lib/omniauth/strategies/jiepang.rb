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
      
      def signed_params
        params = {}
        params[:api_key] = client.id
        #params[:method] = 'users.getInfo'
        params[:call_id] = Time.now.to_i
        params[:format] = 'json'
        params[:v] = '1.0'
        #params[:uids] = session_key['user']['id']
        #params[:session_key] = session_key['jiepang_token']['session_key']
        params[:sig] = Digest::MD5.hexdigest(params.map{|k,v| "#{k}=#{v}"}.sort.join + client.secret)
        params
      end

      def session_key
        response = @access_token.get('/renren_api/session_key', {:params => {:oauth_token => @access_token.token}})
        @session_key ||= MultiJson.decode(response.response.env[:body])
      end

      def request_phase
        options[:scope] ||= 'publish_feed'
        super
      end

      def build_access_token
        if jiepang_session.nil? || jiepang_session.empty?
          verifier = request.params['code']
          self.access_token = client.auth_code.get_token(verifier, {:redirect_uri => callback_url}.merge(options))
          puts self.access_token.inspect
          self.access_token
        else
          self.access_token = ::OAuth2::AccessToken.new(client, jiepang_session['access_token'])
        end
      end

      def jiepang_session
        session_cookie = request.cookies["rrs_#{client.id}"]
        if session_cookie
          @jiepang_session ||= Rack::Utils.parse_query(request.cookies["rrs_#{client.id}"].gsub('"', ''))
        else
          nil
        end
      end

      def raw_info
        @raw_info ||= {} #MultiJson.decode(access_token.get("http://api.jiepang.com/v1/account/verify_credentials?access_token=#{@access_token.token}").body)
        puts "********@raw_info.inspect"
        puts @raw_info.inspect
        @raw_info
      rescue ::Errno::ETIMEDOUT
        raise ::Timeout::Error
      end
    end
  end
end