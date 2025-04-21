class ApplicationController < ActionController::Base
  include Pagy::Backend

  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  before_action :configure_permitted_parameters, if: :devise_controller?
  allow_browser versions: { modern: true, firefox: "110" }
  before_action :set_query, except: []

  protected

  def configure_permitted_parameters
    devise_parameter_sanitizer.permit(:sign_up, keys: [ :username, :pin ])
    devise_parameter_sanitizer.permit(:account_update, keys: [ :username ])
  end

  def set_query
    @q = Post.ransack(params[:q])
  end
end
