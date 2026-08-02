require "test_helper"

class CoinSlotTest < ActiveSupport::TestCase
  setup do
    @slot = coin_slots(:one)
  end

  test "validates presence of required attributes" do
    slot = CoinSlot.new
    refute slot.valid?
    assert_includes slot.errors[:name], "can't be blank"
    assert_includes slot.errors[:mac_address], "can't be blank"
    assert_includes slot.errors[:ip_address], "can't be blank"
  end

  test "validates uniqueness of name, mac_address, ip_address, device_id" do
    duplicate = CoinSlot.new(
      name: @slot.name,
      mac_address: @slot.mac_address,
      ip_address: @slot.ip_address,
      device_id: @slot.device_id,
      status: :online
    )
    refute duplicate.valid?
    assert_includes duplicate.errors[:name], "has already been taken"
    assert_includes duplicate.errors[:mac_address], "has already been taken"
    assert_includes duplicate.errors[:ip_address], "has already been taken"
    assert_includes duplicate.errors[:device_id], "has already been taken"
  end

  test "generates secret on create" do
    new_slot = CoinSlot.create!(
      name: "New Slot",
      mac_address: "AA:BB:CC:DD:EE:FF",
      ip_address: "192.168.1.200",
      device_id: "new-slot",
      status: :online
    )
    assert new_slot.secret.present?
    assert_match(/^sk_[0-9a-f]{64}$/, new_slot.secret)
  end

  test "authorized_status? works for authorized statuses" do
    @slot.update!(status: :online)
    assert @slot.authorized_status?
    @slot.update!(status: :active_session)
    assert @slot.authorized_status?
    @slot.update!(status: :offline)
    assert @slot.authorized_status?
  end

  test "authorized_status? returns false for locked" do
    @slot.update!(status: :locked)
    refute @slot.authorized_status?
  end
end
