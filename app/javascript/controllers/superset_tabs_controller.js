import { Controller } from "@hotwired/stimulus";

// Connects to data-controller="superset-tabs"
export default class extends Controller {
  static targets = ["tab", "pane"];

  connect() {
    // Show the first tab by default
    if (this.tabTargets.length > 0) {
      this.switchTo(0);
    }
  }

  switch(event) {
    const index = parseInt(event.currentTarget.dataset.index, 10);
    this.switchTo(index);
  }

  switchTo(index) {
    this.tabTargets.forEach((tab, i) => {
      if (i === index) {
        tab.classList.remove("bg-slate-700", "text-slate-300");
        tab.classList.add("bg-blue-600", "text-white");
      } else {
        tab.classList.remove("bg-blue-600", "text-white");
        tab.classList.add("bg-slate-700", "text-slate-300");
      }
    });

    this.paneTargets.forEach((pane, i) => {
      if (i === index) {
        pane.classList.remove("hidden");
      } else {
        pane.classList.add("hidden");
      }
    });
  }
}
