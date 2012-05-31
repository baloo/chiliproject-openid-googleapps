# coding: utf-8
#begin
#  require 'openid'
#rescue LoadError
#  begin
#    gem 'ruby-openid', '>=2.1.4'
#  rescue Gem::LoadError
#    # no openid support
#  end
#end

#if Object.const_defined?(:OpenID)
#  config.to_prepare do
#    OpenID::Util.logger = Rails.logger
#    ActionController::Base.send :include, OpenIdAuthentication
#  end
#end


Redmine::Plugin.register :open_id_google do
  name 'OpenId Google'
  author 'Arthur Gautier'
  description 'This plugin helps you to log from google apps'
  version '0.0.1'
  settings :default => {
    'openid_google'=> 0,
    'openid_google_domain'=> ""
    }, :partial => 'settings/open_id_google'
end
