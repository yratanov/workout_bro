import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = ["routineSection", "customSection"];

  showCustom() {
    this.routineSectionTargets.forEach((element) => {
      element.classList.add("hidden");
    });
    this.customSectionTargets.forEach((element) => {
      element.classList.remove("hidden");
    });
  }

  showRoutine() {
    this.routineSectionTargets.forEach((element) => {
      element.classList.remove("hidden");
    });
    this.customSectionTargets.forEach((element) => {
      element.classList.add("hidden");
    });
  }
}
