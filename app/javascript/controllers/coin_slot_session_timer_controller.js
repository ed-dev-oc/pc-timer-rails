import { Controller } from "@hotwired/stimulus";

// Connects to data-controller="coin-slot-session-timer"
export default class extends Controller {
  static values = {
    endedAt: String,
    totalMillisecondsExpiration: Number,
  };

  static targets = ["bar", "remaining"];

  connect() {
    this.endTime = new Date(this.endedAtValue);

    this.update();
    setInterval(() => this.update(), 1000);
  }

  update() {
    const now = new Date();
    const total = this.totalMillisecondsExpirationValue;
    const remaining = this.endTime - now;

    // progress calculation
    let progress = ((total - remaining) / total) * 100;
    if (progress > 100) progress = 100;
    if (progress < 0) progress = 0;

    // UI updates
    this.barTarget.style.width = progress + "%";
    this.barTarget.innerText = Math.floor(progress) + "%";

    this.remainingTarget.innerText =
      remaining <= 0 ? "Done!" : Math.ceil(remaining / 1000) + " seconds";
  }
}
