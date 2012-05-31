#-- encoding: UTF-8
#-- copyright
# BSD 2-clause licencse
#++

ActionController::Routing::Routes.draw do |map|
  map.connect 'openid/login',    :controller => 'openid', :action => 'login'
  map.connect 'openid/complete', :controller => 'openid', :action => 'complete'
end
