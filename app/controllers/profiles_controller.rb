# frozen_string_literal: true

class ProfilesController < ApplicationController
  before_action :authenticate_identity!

  def show
    assign_profile_state
  end

  def update
    assign_profile_state
    result = UnitsOfWork::UpdateProfile.execute(
      user: current_user,
      email: profile_params[:email],
      password: profile_params[:password],
      password_confirmation: profile_params[:password_confirmation]
    )
    @profile_errors = result.errors

    if result.success?
      redirect_to profile_path, notice: "Profile updated."
    else
      render :show, status: :unprocessable_content
    end
  end

  private

  def assign_profile_state
    @password_heading = current_user.password_identity.present? ? "Change password" : "Add a password"
  end

  def profile_params
    params.fetch(:profile, {}).permit(:email, :password, :password_confirmation)
  end
end
