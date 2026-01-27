import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static values = {
    id: Number,
    url: String,
    interval: { type: Number, default: 5000 },
  };

  static targets = ["badge", "stats", "error"];

  connect() {
    this.poll();
  }

  disconnect() {
    this.stopPolling();
  }

  poll() {
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
        this.updateUI(data);
      } else if (data.status === "in_progress") {
        this.updateBadge("in_progress");
      }
    } catch (error) {
      console.error("Failed to check import status:", error);
    }
  }

  updateUI(data) {
    this.updateBadge(data.status);

    if (data.status === "completed") {
      this.updateStats(data.imported_count, data.skipped_count);
    } else if (data.status === "failed" && data.error_details) {
      this.updateError(data.error_details.message);
    }
  }

  updateBadge(status) {
    if (!this.hasBadgeTarget) return;

    const badgeClasses = {
      pending:
        "inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium bg-yellow-900/50 text-yellow-300",
      in_progress:
        "inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium bg-yellow-900/50 text-yellow-300",
      completed:
        "inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium bg-green-900/50 text-green-300",
      failed:
        "inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium bg-red-900/50 text-red-300",
    };

    const badgeTexts = {
      pending: "Pending",
      in_progress: "Processing",
      completed: "Completed",
      failed: "Failed",
    };

    this.badgeTarget.innerHTML = `<span class="${badgeClasses[status]}">${badgeTexts[status]}</span>`;
  }

  updateStats(imported, skipped) {
    if (!this.hasStatsTarget) return;

    this.statsTarget.innerHTML = `Imported: ${imported}, Skipped: ${skipped}`;
    this.statsTarget.classList.remove("animate-pulse");
  }

  updateError(message) {
    if (!this.hasStatsTarget) return;

    this.statsTarget.innerHTML = `<span class="text-red-400">${message}</span>`;
    this.statsTarget.classList.remove("animate-pulse");
  }
}
