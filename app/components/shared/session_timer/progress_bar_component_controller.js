import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static values = {
    expiresAt: String,
    sessionDurationMs: Number,
  };

  static targets = ["bar"];

  connect() {
    this.endTime = new Date(this.expiresAtValue);

    this.update();
    setInterval(() => this.update(), 1000);
  }

  update() {
    const now = new Date();
    const total = this.sessionDurationMsValue;
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
  }
}
