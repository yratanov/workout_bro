import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = ["container", "backdrop", "dialog"];
  static values = { open: Boolean, autoOpen: Boolean, turboFrame: String };

  connect() {
    this.handleKeydown = this.handleKeydown.bind(this);
    document.addEventListener("keydown", this.handleKeydown);

    // Auto-open modal when loaded via Turbo frame
    if (this.autoOpenValue) {
      this.open();
    }
  }

  disconnect() {
    document.removeEventListener("keydown", this.handleKeydown);
    document.body.classList.remove("overflow-hidden");
  }

  open() {
    this.containerTarget.classList.remove("hidden");
    document.body.classList.add("overflow-hidden");
  }

  close() {
    this.containerTarget.classList.add("hidden");
    document.body.classList.remove("overflow-hidden");

    // Clear the turbo frame content when closing
    if (this.hasTurboFrameValue && this.turboFrameValue) {
      const frame = document.getElementById(this.turboFrameValue);
      if (frame) {
        frame.innerHTML = "";
      }
    }
  }

  stopPropagation(event) {
    event.stopPropagation();
  }

  handleKeydown(event) {
    if (event.key === "Escape" && !this.containerTarget.classList.contains("hidden")) {
      this.close();
    }
  }
}
