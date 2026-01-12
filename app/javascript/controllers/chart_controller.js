import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static values = {
    type: { type: String, default: "bar" },
    labels: Array,
    datasets: Array,
    options: { type: Object, default: {} },
  };

  connect() {
    this.chart = new Chart(this.element, {
      type: this.typeValue,
      data: {
        labels: this.labelsValue,
        datasets: this.datasetsValue,
      },
      options: {
        responsive: true,
        maintainAspectRatio: false,
        ...this.optionsValue,
      },
    });
  }

  disconnect() {
    if (this.chart) {
      this.chart.destroy();
    }
  }
}
