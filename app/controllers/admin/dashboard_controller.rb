class Admin::DashboardController < Admin::BaseController
  def index
    @stats = {
      online_pcs: Pc.online.count + Pc.active_session.count,
      active_sessions: PcSession.active.count,
      offline_pcs: Pc.offline.count,
      revenue_today: CoinTransaction.used.where(created_at: Time.zone.now.beginning_of_day..Time.zone.now.end_of_day).sum(:peso_amount),
      total_pcs: Pc.count,
      total_revenue: CoinTransaction.used.sum(:peso_amount),
      total_sessions: PcSession.count,
      total_coin_slots: CoinSlot.count
    }

    @pc_status_counts = {
      online: Pc.online.count,
      active_session: Pc.active_session.count,
      offline: Pc.offline.count,
      disabled: Pc.disabled_kiosk.count,
      uninstalled: Pc.uninstalled.count
    }

    @recent_transactions = CoinTransaction.used
      .includes(:pc, :coin_slot)
      .order(created_at: :desc)
      .limit(10)

    @active_sessions = PcSession.active
      .includes(:pc)
      .order(expires_at: :asc)
      .limit(10)

    @revenue_last_7_days = get_revenue_last_7_days
    @sessions_last_7_days = get_sessions_last_7_days
    @hourly_sessions = get_hourly_sessions
  end

  private

  def get_revenue_last_7_days
    revenue_data = []
    labels = []

    6.downto(0).each do |days_ago|
      date = Time.zone.now - days_ago.days
      revenue = CoinTransaction.used
        .where(created_at: date.beginning_of_day..date.end_of_day)
        .sum(:peso_amount)
      revenue_data << revenue
      labels << date.strftime("%b %d")
    end

    { labels: labels, data: revenue_data }
  end

  def get_sessions_last_7_days
    sessions_data = []
    labels = []

    6.downto(0).each do |days_ago|
      date = Time.zone.now - days_ago.days
      sessions = PcSession.where(created_at: date.beginning_of_day..date.end_of_day).count
      sessions_data << sessions
      labels << date.strftime("%b %d")
    end

    { labels: labels, data: sessions_data }
  end

  def get_hourly_sessions
    today = Time.zone.now.beginning_of_day
    hourly_data = Array.new(24, 0)
    labels = (0..23).map { |h| "#{h}:00" }

    PcSession.where(created_at: today..Time.zone.now)
      .pluck(:created_at)
      .each do |timestamp|
        hourly_data[timestamp.hour] += 1
      end

    { labels: labels, data: hourly_data }
  end
end
