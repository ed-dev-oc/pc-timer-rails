import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static values = {
    expiresAt: String,
    sessionDurationMs: Number
  };

  static targets = ["remaining"];

  connect() {
    this.endTime = new Date(this.expiresAtValue);

    this.update();
    setInterval(() => this.update(), 1000);
  }

  update() {
    const now = new Date();
    const timeLeftMs = this.endTime - now;

    this.renderRemainingTime(timeLeftMs);
  }

  formated_timer(milliseconds) {
    const totalSeconds = Math.floor(milliseconds / 1000);

    const hours = Math.floor(totalSeconds / 3600);
    const minutes = Math.floor((totalSeconds % 3600) / 60);
    const seconds = totalSeconds % 60;

    const data =
      `${hours.toString().padStart(2, "0")}:` +
      `${minutes.toString().padStart(2, "0")}:` +
      `${seconds.toString().padStart(2, "0")}`;

    return data;
  }

  renderRemainingTime(milliseconds) {
    if (this.hasRemainingTarget) {
      if (milliseconds <= 0) {
        this.remainingTarget.innerText = "Expired";
      } else {
        this.remainingTarget.innerText = this.formated_timer(milliseconds);
      }
    }
  }
}
