class PcCommand < ApplicationRecord
  include Commandable

  enum :action, [ :lock, :unlock, :restart, :shutdown ], prefix: true

  validates :action, presence: true

  belongs_to :pc

  def execute!
    agent = pc.agent

    case action
    when "restart"  then agent.restart
    when "shutdown" then agent.shutdown
    when "lock"     then agent.lock
    when "unlock"   then agent.unlock
    end
  end
end
