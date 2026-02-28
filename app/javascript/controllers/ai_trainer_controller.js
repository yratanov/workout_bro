import { Controller } from "@hotwired/stimulus";
import { Turbo } from "@hotwired/turbo-rails";

export default class extends Controller {
  static values = {
    url: String,
    interval: { type: Number, default: 5000 },
    processing: Boolean,
    configured: Boolean,
  };

  static targets = ["form", "warning", "processingBanner"];

  connect() {
    if (this.processingValue) {
      this.startPolling();
    }
  }

  disconnect() {
    this.stopPolling();
  }

  startPolling() {
    this.disableForm();
    this.timer = setInterval(() => this.checkStatus(), this.intervalValue);
  }

  stopPolling() {
    if (this.timer) {
      clearInterval(this.timer);
      this.timer = null;
    }
  }

  async checkStatus() {
    try {
      const response = await fetch(this.urlValue);
      const data = await response.json();

      if (data.status === "completed" || data.status === "failed") {
        this.stopPolling();
        Turbo.visit(window.location.href);
      }
    } catch (error) {
      console.error("Failed to check trainer status:", error);
    }
  }

  disableForm() {
    if (!this.hasFormTarget) return;

    const inputs = this.formTarget.querySelectorAll(
      "input, select, textarea, button",
    );
    inputs.forEach((input) => (input.disabled = true));
  }
}
