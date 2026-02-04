import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["select", "textarea"]

  selectTemplate() {
    const value = this.selectTarget.value
    if (value) {
      this.textareaTarget.value = value
    }
  }
}
