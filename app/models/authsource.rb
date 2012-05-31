

class AuthSourceOpenIDGoogle < AuthSource

  def initialize
    super
    self.name = "AuthSourceOpenIDGoogle"
  end

  def authenticate(login, password)
    return nil
  end

  def auth_method_name
    "OpenIDGoogle"
  end

end

