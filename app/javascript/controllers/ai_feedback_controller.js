import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = ["content", "loading"];
  static values = { url: String, interval: { type: Number, default: 3000 } };

  connect() {
    if (!this.hasLoadingTarget) return;

    this.poll();
  }

  disconnect() {
    this.stopPolling();
  }

  async poll() {
    try {
      const response = await fetch(this.urlValue, {
        headers: { Accept: "application/json" },
      });

      if (!response.ok) return;

      const data = await response.json();

      if (data.ai_summary) {
        this.contentTarget.innerHTML = data.ai_summary;
        this.loadingTarget.remove();
        return;
      }
    } catch {
      // Silently ignore polling errors
    }

    this.timer = setTimeout(() => this.poll(), this.intervalValue);
  }

  stopPolling() {
    if (this.timer) {
      clearTimeout(this.timer);
      this.timer = null;
    }
  }
}
