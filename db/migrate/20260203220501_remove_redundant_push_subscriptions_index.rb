class RemoveRedundantPushSubscriptionsIndex < ActiveRecord::Migration[8.0]
  def change
    remove_index :push_subscriptions, :user_id
  end
end
