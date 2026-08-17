require "test_helper"

class UserTest < ActiveSupport::TestCase
  test "valid fixture is valid" do
    assert users(:one).valid?
  end

  test "default role is user" do
    user = User.new(
      email: "default-role@example.com",
      password: "password123",
      password_confirmation: "password123"
    )

    assert user.user?
  end

  test "requires valid email" do
    user = User.new(
      email: "not-an-email",
      password: "password123",
      password_confirmation: "password123"
    )

    assert_not user.valid?
    assert_includes user.errors[:email], "is invalid"
  end

  test "requires password on create" do
    user = User.new(email: "missing-password@example.com")

    assert_not user.valid?
    assert_includes user.errors[:password], "can't be blank"
  end

  test "allows first owner" do
    User.owner.destroy_all

    owner = User.new(
      email: "owner@example.com",
      password: "password123",
      password_confirmation: "password123",
      role: :owner
    )

    assert owner.valid?
  end

  test "does not allow a second owner" do
    User.owner.destroy_all
    User.create!(
      email: "first-owner@example.com",
      password: "password123",
      password_confirmation: "password123",
      role: :owner
    )

    owner = User.new(
      email: "second-owner@example.com",
      password: "password123",
      password_confirmation: "password123",
      role: :owner
    )

    assert_not owner.valid?
    assert_includes owner.errors[:base], "Owner already exist!"
  end

  test "allows admins and users when owner exists" do
    User.owner.destroy_all
    User.create!(
      email: "existing-owner@example.com",
      password: "password123",
      password_confirmation: "password123",
      role: :owner
    )

    admin = User.new(
      email: "new-admin@example.com",
      password: "password123",
      password_confirmation: "password123",
      role: :admin
    )
    user = User.new(
      email: "new-user@example.com",
      password: "password123",
      password_confirmation: "password123",
      role: :user
    )

    assert admin.valid?
    assert user.valid?
  end
end
