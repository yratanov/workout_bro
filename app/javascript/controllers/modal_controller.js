import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = ["container", "backdrop", "dialog"];
  static values = { open: Boolean };

  connect() {
    this.handleKeydown = this.handleKeydown.bind(this);
    document.addEventListener("keydown", this.handleKeydown);
  }

  disconnect() {
    document.removeEventListener("keydown", this.handleKeydown);
  }

  open() {
    this.containerTarget.classList.remove("hidden");
    document.body.classList.add("overflow-hidden");
  }

  close() {
    this.containerTarget.classList.add("hidden");
    document.body.classList.remove("overflow-hidden");
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
