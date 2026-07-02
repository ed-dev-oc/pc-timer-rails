import { Controller } from "@hotwired/stimulus";
import * as bootstrap from "bootstrap";

// Connects to data-controller="toast-event"
export default class extends Controller {
  connect() {
    bootstrap.Toast.getOrCreateInstance(this.element).show();
  }
}
