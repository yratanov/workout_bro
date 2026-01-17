import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static values = { timeout: { type: Number, default: 5000 } };

  connect() {
    this.timeout = setTimeout(() => this.dismiss(), this.timeoutValue);
  }

  disconnect() {
    if (this.timeout) clearTimeout(this.timeout);
  }

  dismiss() {
    this.element.classList.add("opacity-0", "translate-y-[-100%]");
    setTimeout(() => this.element.remove(), 300);
  }
}
