import { Controller } from "@hotwired/stimulus";

// Connects to data-controller="workout-type-switcher"
export default class extends Controller {
  static targets = ["strengthToggle", "runToggle"];

  switch(event) {
    let value = event.target.value;

    if (value === "strength") {
      this.strengthToggleTargets.forEach((target) => {
        target.classList.remove("hidden");
      });
      this.runToggleTargets.forEach((target) => {
        target.classList.add("hidden");
      });
    } else {
      this.strengthToggleTargets.forEach((target) => {
        target.classList.add("hidden");
      });
      this.runToggleTargets.forEach((target) => {
        target.classList.remove("hidden");
      });
    }
  }
}
