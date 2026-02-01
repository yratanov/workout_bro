import { Controller } from "@hotwired/stimulus";
import Sortable from "sortablejs";

export default class extends Controller {
  static values = {
    url: String,
  };

  connect() {
    this.sortable = Sortable.create(this.element, {
      animation: 150,
      handle: "[data-sortable-handle]",
      ghostClass: "opacity-50",
      onEnd: this.onEnd.bind(this),
    });
  }

  disconnect() {
    this.sortable.destroy();
  }

  async onEnd(event) {
    const { oldIndex, newIndex } = event;
    if (oldIndex === newIndex) return;

    const item = event.item;
    const id = item.dataset.sortableId;
    const url = this.urlValue.replace("%3Aid", id).replace(":id", id);

    const response = await fetch(url, {
      method: "PATCH",
      headers: {
        "Content-Type": "application/json",
        Accept: "text/vnd.turbo-stream.html",
        "X-CSRF-Token": document.querySelector('meta[name="csrf-token"]')
          .content,
      },
      body: JSON.stringify({ position: newIndex + 1 }),
    });

    const html = await response.text();
    if (html && window.Turbo) {
      window.Turbo.renderStreamMessage(html);
    }
  }
}
