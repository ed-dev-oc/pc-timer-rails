import { Controller } from "@hotwired/stimulus";

// Connects to data-controller="session-timer"
export default class extends Controller {
  static values = {
    endedAt: String,
    totalMillisecondsExpiration: Number,
  };

  static targets = ["bar", "remaining", "totalTime"];

  connect() {
    this.endTime = new Date(this.endedAtValue);

    this.update();
    setInterval(() => this.update(), 1000);

    if (this.hasTotalTimeTarget) {
      this.totalTimeTarget.innerText = this.formated_timer(
        this.totalMillisecondsExpirationValue,
      );
    }
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
    if (this.hasBarTarget) {
      this.barTarget.style.width = progress + "%";
      this.barTarget.innerText = Math.floor(progress) + "%";
    }

    if (this.hasRemainingTarget) {
      if (remaining <= 0) {
        this.remainingTarget.innerText = "Expired";
      } else {
        this.remainingTarget.innerText = this.formated_timer(remaining);
      }
    }
  }

  formated_timer(remaining) {
    const totalSeconds = Math.floor(remaining / 1000);

    const hours = Math.floor(totalSeconds / 3600);
    const minutes = Math.floor((totalSeconds % 3600) / 60);
    const seconds = totalSeconds % 60;

    const data =
      `${hours.toString().padStart(2, "0")}:` +
      `${minutes.toString().padStart(2, "0")}:` +
      `${seconds.toString().padStart(2, "0")}`;

    return data;
  }
}
