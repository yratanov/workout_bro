import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = ["header", "fab"];
  static values = { threshold: { type: Number, default: 200 } };

  connect() {
    this.visible = false;
    this.observer = new IntersectionObserver(
      (entries) => {
        const headerVisible = entries[0].isIntersecting;
        this.toggle(!headerVisible);
      },
      { threshold: 0 },
    );
    if (this.hasHeaderTarget) {
      this.observer.observe(this.headerTarget);
    }
  }

  disconnect() {
    this.observer?.disconnect();
  }

  toggle(show) {
    if (show === this.visible) return;
    this.visible = show;

    if (!this.hasFabTarget) return;

    if (show) {
      this.fabTarget.style.opacity = "1";
      this.fabTarget.style.transform = "scale(1)";
      this.fabTarget.style.pointerEvents = "auto";
    } else {
      this.fabTarget.style.opacity = "0";
      this.fabTarget.style.transform = "scale(0.8)";
      this.fabTarget.style.pointerEvents = "none";
    }
  }
}
