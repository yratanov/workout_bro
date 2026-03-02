import { Controller } from "@hotwired/stimulus";
import { Turbo } from "@hotwired/turbo-rails";

export default class extends Controller {
  static values = {
    url: String,
    interval: { type: Number, default: 5000 },
    processing: Boolean,
  };

  connect() {
    if (this.processingValue) {
      this.startPolling();
    }
  }

  disconnect() {
    this.stopPolling();
  }

  startPolling() {
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
      console.error("Failed to check routine generation status:", error);
    }
  }
}
