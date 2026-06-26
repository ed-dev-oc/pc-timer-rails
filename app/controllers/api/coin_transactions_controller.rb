class Api::CoinTransactionsController < Api::BaseController
  before_action :authenticate_device!, :set_coin_slot!, :set_coin_slot_session!

  def create
    @coin_transaction = CoinTransaction.new(coin_transaction_params)
    @coin_transaction.coin_slot = @coin_slot
    @coin_transaction.pc = @coin_slot_session.pc

    if @coin_transaction.save
      render json: {
        status: "created",
        message: "Coin transaction saved",
        transaction_uid: @coin_transaction.transaction_uid
      }, status: :created
    else
      render_validation_failed(@coin_transaction, "Failed to save coin transaction")
    end
  end

  private
    def set_coin_slot!
      @coin_slot = current_device
    end

    def set_coin_slot_session!
      @coin_slot_session = CoinSlotSession.find_puid(params[:coin_slot_session_id])

      render_not_found("Coin slot session") if @coin_slot_session.nil?
    end

    def coin_transaction_params
      params.expect(coin_transaction: [ :transaction_uid, :peso_amount ])
    end
end
