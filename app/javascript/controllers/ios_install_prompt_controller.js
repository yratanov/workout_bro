import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = ["banner"];

  connect() {
    if (this.shouldShowPrompt()) {
      this.show();
    }
  }

  shouldShowPrompt() {
    // Only show on iOS Safari when not in standalone mode
    const isIOS =
      /iPad|iPhone|iPod/.test(navigator.userAgent) && !window.MSStream;
    const isInStandaloneMode =
      window.navigator.standalone === true ||
      window.matchMedia("(display-mode: standalone)").matches;
    const isDismissed = localStorage.getItem("ios-install-prompt-dismissed");

    return isIOS && !isInStandaloneMode && !isDismissed;
  }

  show() {
    this.bannerTarget.classList.remove("hidden");
  }

  dismiss() {
    localStorage.setItem("ios-install-prompt-dismissed", "true");
    this.bannerTarget.classList.add("translate-y-full", "opacity-0");
    setTimeout(() => this.bannerTarget.remove(), 300);
  }
}
