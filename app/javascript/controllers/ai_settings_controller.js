import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = ["modelContainer", "modelSelect"];
  static values = { models: Object };

  connect() {
    this.toggleModelVisibility();
  }

  providerChanged(event) {
    this.updateModels(event.target.value);
    this.toggleModelVisibility();
  }

  updateModels(provider) {
    const models = this.modelsValue[provider] || [];
    const select = this.modelSelectTarget;
    const currentValue = select.value;

    select.innerHTML = "";

    models.forEach((model) => {
      const option = document.createElement("option");
      option.value = model;
      option.textContent = model;
      if (model === currentValue) option.selected = true;
      select.appendChild(option);
    });

    if (!models.includes(currentValue) && models.length > 0) {
      select.value = models[0];
    }
  }

  toggleModelVisibility() {
    const providerSelect = this.element.querySelector(
      '[data-ai-settings-target="providerSelect"]',
    );
    const hasProvider =
      providerSelect && providerSelect.value && providerSelect.value !== "";

    if (hasProvider) {
      this.modelContainerTarget.classList.remove("hidden");
      this.updateModels(providerSelect.value);
    } else {
      this.modelContainerTarget.classList.add("hidden");
    }
  }
}
