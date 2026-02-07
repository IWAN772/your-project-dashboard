import { Controller } from "@hotwired/stimulus"

// Handles tag input behavior: clearing field after submission
export default class extends Controller {
  static targets = ["field"]

  connect() {
    // Clear input field after successful Turbo submission
    this.element.addEventListener("turbo:submit-end", (event) => {
      if (event.detail.success) {
        this.fieldTarget.value = ""
        this.fieldTarget.focus()
      }
    })
  }
}
