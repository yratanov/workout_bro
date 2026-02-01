import { Controller } from "@hotwired/stimulus";

// Connects to data-controller="superset-form"
export default class extends Controller {
  static targets = [
    "exerciseTab",
    "supersetTab",
    "exercisePane",
    "supersetPane",
  ];

  connect() {
    this.showExercise();
  }

  showExercise() {
    if (!this.hasExerciseTabTarget) return;

    this.updateTabStyles(this.exerciseTabTarget, this.supersetTabTarget);
    this.exercisePaneTarget.classList.remove("hidden");
    if (this.hasSupersetPaneTarget) {
      this.supersetPaneTarget.classList.add("hidden");
    }
  }

  showSuperset() {
    if (!this.hasSupersetTabTarget) return;

    this.updateTabStyles(this.supersetTabTarget, this.exerciseTabTarget);
    this.exercisePaneTarget.classList.add("hidden");
    this.supersetPaneTarget.classList.remove("hidden");
  }

  updateTabStyles(activeTab, inactiveTab) {
    const activeClasses = activeTab.dataset.activeClass.split(" ");
    const inactiveClasses = activeTab.dataset.inactiveClass.split(" ");

    activeTab.classList.remove(...inactiveClasses);
    activeTab.classList.add(...activeClasses);

    inactiveTab.classList.remove(...activeClasses);
    inactiveTab.classList.add(...inactiveClasses);
  }
}
