import { Controller } from "@hotwired/stimulus";

// Connects to data-controller="routine-switcher"
export default class extends Controller {
  connect() {}

  async switch(e) {
    let result = await fetch(
      `/workout_routines/${e.target.value}/workout_routine_days`,
      {
        method: "GET",
        headers: {
          "X-CSRF-Token": document.querySelector("meta[name='csrf-token']")
            .content,
          "Content-Type": "application/json",
          Accept: "text/vnd.turbo-stream.html",
        },
      },
    );

    let html = await result.text();

    Turbo.renderStreamMessage(html);
  }
}
