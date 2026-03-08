import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = ["today"];
  static values = { hasToday: Boolean };

  connect() {
    if (this.hasTodayValue && this.hasTodayTarget) {
      this.todayTarget.scrollIntoView({ behavior: "instant", block: "center" });
    }
  }
}
