class CoinSlotCommand < ApplicationRecord
  include Commandable

  SESSION_REQUIRED_FOR_ACTIONS = [ :enable, :disable ]
  enum :action, [ :enable, :disable, :restart ], prefix: true

  validates :coin_slot_session, presence: true, if: -> { SESSION_REQUIRED_FOR_ACTIONS.include?(action.to_sym) }, on: :create
  validates :action, presence: true, on: :create

  belongs_to :coin_slot
  belongs_to :coin_slot_session, optional: true

  def execute!
    agent = coin_slot.agent

    case action
    when "enable"  then agent.enable(coin_slot_session)
    when "disable" then agent.disable(coin_slot_session)
    when "restart" then agent.restart
    end
  end
end
