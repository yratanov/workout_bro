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

  onEnd(event) {
    const { oldIndex, newIndex } = event;
    if (oldIndex === newIndex) return;

    const item = event.item;
    const id = item.dataset.sortableId;
    const url = this.urlValue.replace("%3Aid", id).replace(":id", id);

    fetch(url, {
      method: "PATCH",
      headers: {
        "Content-Type": "application/json",
        "X-CSRF-Token": document.querySelector('meta[name="csrf-token"]')
          .content,
      },
      body: JSON.stringify({
        position: newIndex + 1,
      }),
    });
  }
}
