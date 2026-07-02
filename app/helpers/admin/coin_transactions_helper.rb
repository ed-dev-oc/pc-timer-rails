module Admin::CoinTransactionsHelper
  BADGE_CLASSES = {
    used: "text-bg-success",
    unused: "text-bg-secondary"
  }.freeze

  ICON_CLASSES = {
    used: "bi bi-check-circle-fill",
    unused: "bi bi-circle"
  }

  def coin_transaction_status_badge(coin_transaction)
    content_tag(:span, class: "badge p-2 #{coin_transaction_badge_class(coin_transaction.status)}") do
      concat content_tag(:i, "", class: "#{ICON_CLASSES[coin_transaction.status.to_sym]} me-1")
      concat coin_transaction.status.titleize
    end
  end

  def coin_transaction_badge_class(status)
    BADGE_CLASSES[status.to_sym]
  end
end
