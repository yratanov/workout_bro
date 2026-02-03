class PushSubscriptionsController < ApplicationController
  before_action :require_authentication

  def create
    subscription = current_user.push_subscriptions.find_or_initialize_by(
      endpoint: subscription_params[:endpoint]
    )

    subscription.assign_attributes(
      p256dh: subscription_params[:p256dh],
      auth: subscription_params[:auth],
      user_agent: request.user_agent
    )

    if subscription.save
      render json: { status: "subscribed" }, status: :created
    else
      render json: { errors: subscription.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def destroy
    subscription = current_user.push_subscriptions.find_by(endpoint: params[:endpoint])
    subscription&.destroy

    render json: { status: "unsubscribed" }
  end

  def vapid_public_key
    public_key = WebPushService.vapid_public_key

    if public_key.present?
      render json: { vapid_public_key: public_key }
    else
      render json: { error: "VAPID not configured" }, status: :service_unavailable
    end
  end

  private

  def subscription_params
    params.require(:subscription).permit(:endpoint, :p256dh, :auth)
  end
end
