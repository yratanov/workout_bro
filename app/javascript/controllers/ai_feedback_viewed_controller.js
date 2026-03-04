import { Controller } from "@hotwired/stimulus";

// Marks AI feedback as viewed when it appears on the page.
// Attached to the streamed AI feedback content div so it fires
// when Turbo replaces the loading spinner with actual content.
export default class extends Controller {
  static values = { url: String };

  connect() {
    this.markViewed();
  }

  async markViewed() {
    if (!this.urlValue) return;

    const csrfToken = document.querySelector(
      'meta[name="csrf-token"]',
    )?.content;

    await fetch(this.urlValue, {
      method: "PATCH",
      headers: {
        "X-CSRF-Token": csrfToken,
        Accept: "text/html",
      },
    });
  }
}
