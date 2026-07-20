import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static values = {
    expiresAt: String,
    sessionDurationMs: Number,
  };

  static targets = ["remaining"];

  connect() {
    this.endTime = new Date(this.expiresAtValue);

    this.update();
    setInterval(() => this.update(), 1000);
  }

  update() {
    const now = new Date();
    const total = this.sessionDurationMsValue;
    const remaining = this.endTime - now;

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
