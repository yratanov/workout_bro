import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = ["content", "trigger", "icon"];

  connect() {
    const isExpanded =
      this.triggerTarget.getAttribute("aria-expanded") === "true";

    const icon = this.iconTarget;

    if (!isExpanded) {
      this.contentTarget.style.maxHeight = "0px";
      icon.style.transform = "rotate(180deg)";
    }
  }

  toggle() {
    const trigger = this.triggerTarget;
    const icon = this.iconTarget;

    const isExpanded = trigger.getAttribute("aria-expanded") === "true";

    // Toggle aria-expanded
    trigger.setAttribute("aria-expanded", String(!isExpanded));

    // Toggle height
    if (isExpanded) {
      this.contentTarget.style.maxHeight = "0px";
      icon.style.transform = "rotate(180deg)";
    } else {
      this.contentTarget.style.maxHeight = null;
      icon.style.transform = "rotate(0deg)";
    }
  }
}
