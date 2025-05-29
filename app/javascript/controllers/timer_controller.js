import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static values = {
    date: String,
    showHours: Boolean,
  };

  connect() {
    this.startTime = new Date(this.dateValue);
    this.update();
    this.timer = setInterval(() => this.update(), 1000);
  }

  disconnect() {
    clearInterval(this.timer);
  }

  update() {
    const now = new Date();
    let diff = Math.abs(now - this.startTime) / 1000; // in seconds

    const hours = String(Math.floor(diff / 3600)).padStart(2, "0");
    diff %= 3600;
    const minutes = String(Math.floor(diff / 60)).padStart(2, "0");
    const seconds = String(Math.floor(diff % 60)).padStart(2, "0");
    if (!this.showHoursValue) {
      this.element.textContent = `${minutes}:${seconds}`;
      return;
    }
    this.element.textContent = `${hours}:${minutes}:${seconds}`;
  }
}
