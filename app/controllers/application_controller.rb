class ApplicationController < ActionController::Base
    def index

    end

    protected
    def authenticate_user!
      if user_signed_in?
        super
      else
        redirect_to root_path, :notice => 'please log in.'
        ## if you want render 404 page
        ## render :file => File.join(Rails.root, 'public/404'), :formats => [:html], :status => 404, :layout => false
      end
    end
end
