#-- encoding: UTF-8
#-- copyright
# BSD 3-clause license
#++
# Setting.plugin_open_id_google
# => {"open_id_google"=>"on", "open_id_google_domain"=>"foobar.com"}

class OpenidController < AccountController
  def login()
    if Setting.plugin_open_id_google['open_id_google'] != "on"
      redirect_to :controller => 'welcome', :action => 'index'
      return
    end

    domain = Setting.plugin_open_id_google['open_id_google_domain']

    identifier = "https://www.google.com/accounts/o8/site-xrds?hd=#{domain}"

    begin
      oidreq = consumer.begin(identifier)

    rescue OpenID::OpenIDError => e
      logger.warn("discovery error : #{e}")

      redirect_to :controller => 'account', :action => 'login'
      return
    end

    # Simple registration
    ax_req = OpenID::AX::FetchRequest.new
    requested_attrs = [['http://schema.openid.net/namePerson/first', 'firstname', true],
                       ['http://schema.openid.net/namePerson/last',  'lastname', true],
                       ['http://schema.openid.net/contact/email', 'email', true]]

    requested_attrs.each {|a| ax_req.add(OpenID::AX::AttrInfo.new(a[0], a[1], a[2] || false))}
    oidreq.add_extension(ax_req)
    oidreq.return_to_args['did_ax'] = 'y'

    # Redirect
    return_to = url_for :action => 'complete', :only_path => false
    realm = url_for :action => 'index', :id => nil, :only_path => false

    redirect_to oidreq.redirect_url(realm, return_to)
  end

  def complete()
    if Setting.plugin_open_id_google['open_id_google'] != "on"
      redirect_to :controller => 'welcome', :action => 'index'
      return
    end

    domain = Setting.plugin_open_id_google['open_id_google_domain']

    current_url = url_for(:action => 'complete', :only_path => false)
    parameters = params.reject{|k,v|request.path_parameters[k]}
    oidresp = consumer.complete(parameters, current_url)

    case oidresp.status
    when OpenID::Consumer::FAILURE
      if oidresp.display_identifier
        flash[:error] = ("Verification of #{oidresp.display_identifier}"\
                         " failed: #{oidresp.message}")
      else
        flash[:error] = "Verification failed: #{oidresp.message}"
      end
    when OpenID::Consumer::SUCCESS
      ax_resp = OpenID::AX::FetchResponse.from_success_response(oidresp)

      mail = ax_resp.get("http://schema.openid.net/contact/email").first

      if mail.split("@").last != domain
        flash[:error] = "Wrong domain"
        redirect_to :controller => 'welcome', :action => 'index'
        return
      end

      @user = User.find(:first, :conditions=>["mail = ? OR mail = ?",
                                              mail, 
                                              mail.gsub(%r!.com$!, '.fr')]) 
      if @user.nil?
        # register
        @user = User.new
        @user.admin = false
        @user.login =     ax_resp.get("http://schema.openid.net/contact/email").first.split("@").first
        @user.firstname = ax_resp.get("http://schema.openid.net/namePerson/first").first
        @user.lastname =  ax_resp.get("http://schema.openid.net/namePerson/last").first
        @user.mail =      ax_resp.get("http://schema.openid.net/contact/email").first

        # Put auth_source as openid
        @user.auth_source = authsource

        @user.register

        case Setting.self_registration
        when '1'
          register_by_email_activation(@user)
        when '3'
          register_automatically(@user)
        else
          register_manually_by_administrator(@user)
        end
      else
        # login

        # Put authsource as openid
        @user.auth_source = authsource
        @user.save

        if @user.active?
          successful_authentication(@user)
        else
          flash[:notice] = l(:notice_account_pending)
          redirect_to :controller => 'welcome', :action => 'index'
        end
      end
      return
    when OpenID::Consumer::SETUP_NEEDED
      flash[:alert] = "Immediate request failed - Setup Needed"
    when OpenID::Consumer::CANCEL
      flash[:alert] = "OpenID transaction cancelled."
    else
    end

    redirect_to :controller => 'welcome', :action => 'index'
  end

  def consumer
    if @consumer.nil?
      store = OpenIdAuthentication.store
      @consumer = OpenID::Consumer.new(session, store)
    end
    return @consumer
  end

  def authsource
    AuthSource.find(:first, :conditions=>["name = ?", "AuthSourceOpenIDGoogle"])
  end
end
