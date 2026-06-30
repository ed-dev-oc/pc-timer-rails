import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = ["input", "toggleIcon"];

  toggle() {
    const type = this.inputTarget.type;
    this.inputTarget.type = type === "password" ? "text" : "password";
    this.updateIcon(type === "password");
  }

  updateIcon(isPassword) {
    if (this.toggleIconTarget) {
      this.toggleIconTarget.classList.toggle("bi-eye", isPassword);
      this.toggleIconTarget.classList.toggle("bi-eye-slash", !isPassword);
    }
  }
}
