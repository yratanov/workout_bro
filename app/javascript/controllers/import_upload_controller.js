import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  setFilename(event) {
    const fileInput = event.target;
    const filenameInput = document.getElementById("original_filename");

    if (fileInput.files.length > 0 && filenameInput) {
      filenameInput.value = fileInput.files[0].name;
    }
  }
}
