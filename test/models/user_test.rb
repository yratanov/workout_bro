require "test_helper"

# == Schema Information
#
# Table name: users
# Database name: primary
#
#  id              :integer          not null, primary key
#  ai_api_key      :string
#  ai_model        :string
#  ai_provider     :string
#  email_address   :string           not null
#  first_name      :string
#  last_name       :string
#  locale          :string           default("en")
#  password_digest :string           not null
#  role            :integer          default("user"), not null
#  setup_completed :boolean          default(FALSE), not null
#  weight_max      :float            default(100.0), not null
#  weight_min      :float            default(2.5), not null
#  weight_step     :float            default(2.5), not null
#  weight_unit     :string           default("kg"), not null
#  wizard_step     :integer          default(0)
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#
# Indexes
#
#  index_users_on_email_address  (email_address) UNIQUE
#

class UserTest < ActiveSupport::TestCase
  test "weight_unit is valid with kg" do
    user = users(:john)
    user.weight_unit = "kg"
    assert user.valid?
  end

  test "weight_unit is valid with lbs" do
    user = users(:john)
    user.weight_unit = "lbs"
    assert user.valid?
  end

  test "weight_unit is invalid with other values" do
    user = users(:john)
    user.weight_unit = "stones"
    assert_not user.valid?
    assert_includes user.errors[:weight_unit], "is not included in the list"
  end

  test "weight_min is valid with positive values" do
    user = users(:john)
    user.weight_min = 5
    assert user.valid?
  end

  test "weight_min is valid with zero" do
    user = users(:john)
    user.weight_min = 0
    assert user.valid?
  end

  test "weight_min is invalid with negative values" do
    user = users(:john)
    user.weight_min = -1
    assert_not user.valid?
    assert_includes user.errors[:weight_min],
                    "must be greater than or equal to 0"
  end

  test "weight_max is valid when greater than weight_min" do
    user = users(:john)
    user.weight_min = 5
    user.weight_max = 100
    assert user.valid?
  end

  test "weight_max is invalid when equal to weight_min" do
    user = users(:john)
    user.weight_min = 50
    user.weight_max = 50
    assert_not user.valid?
    assert_includes user.errors[:weight_max], "must be greater than 50.0"
  end

  test "weight_max is invalid when less than weight_min" do
    user = users(:john)
    user.weight_min = 50
    user.weight_max = 25
    assert_not user.valid?
    assert_includes user.errors[:weight_max], "must be greater than 50.0"
  end

  test "weight_step is valid with positive values" do
    user = users(:john)
    user.weight_step = 2.5
    assert user.valid?
  end

  test "weight_step is invalid with zero" do
    user = users(:john)
    user.weight_step = 0
    assert_not user.valid?
    assert_includes user.errors[:weight_step], "must be greater than 0"
  end

  test "weight_step is invalid with negative values" do
    user = users(:john)
    user.weight_step = -1
    assert_not user.valid?
    assert_includes user.errors[:weight_step], "must be greater than 0"
  end

  test "has default weight_unit of kg" do
    new_user = User.new(email_address: "test@example.com", password: "password")
    assert_equal "kg", new_user.weight_unit
  end

  test "has default weight_min of 2.5" do
    new_user = User.new(email_address: "test@example.com", password: "password")
    assert_equal 2.5, new_user.weight_min
  end

  test "has default weight_max of 100" do
    new_user = User.new(email_address: "test@example.com", password: "password")
    assert_equal 100, new_user.weight_max
  end

  test "has default weight_step of 2.5" do
    new_user = User.new(email_address: "test@example.com", password: "password")
    assert_equal 2.5, new_user.weight_step
  end
end
