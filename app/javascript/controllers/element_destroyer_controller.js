import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["destroyable"]

  destroy() {
    this.destroyableTargets.forEach(element => {
      element.remove()
    })
  }
}
