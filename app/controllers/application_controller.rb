#coding: UTF-8
class ApplicationController < ActionController::Base
  protect_from_forgery                                               # Activé par défaut
  #skip_before_action :verify_authenticity_token, if: :json_request? # Ajouter cette ligne pour ne pas vérifier le csrf (Rails 4)
  skip_before_filter  :verify_authenticity_token, if: :json_request? # Ajouter cette ligne pour ne pas vérifier le csrf (Rails 3)


  protected

  # Utilisé par la méthode skip_before_action pour ne pas contrôler le csrf sur des appels json (à ajouter en Rails 4)
  def json_request?
    request.format.json?
  end

  def session_id
    @session_id ||= Session.current(request)[0].id if request.session_options[:id] != nil
    @session_id ||= 0
  end
  helper_method :session_id

  def check_csrf
    if session_id == 0
      render text: "Votre session a expiré", status: :unauthorized
      # Can't verify your CSRF tocken. Your session was reseted.
      false
    else
      true
    end
  end
end
