import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = ["submitButton", "loading", "context", "charCount"];

  submit() {
    this.submitButtonTarget.disabled = true;
    this.loadingTarget.classList.remove("hidden");
    this.loadingTarget.classList.add("flex");
  }

  updateCharCount() {
    this.charCountTarget.textContent = this.contextTarget.value.length;
  }
}
