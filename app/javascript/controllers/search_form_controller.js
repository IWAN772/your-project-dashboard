import { Controller } from "@hotwired/stimulus"

// Debounced search controller for filtering projects
export default class extends Controller {
  static targets = ["input"]

  connect() {
    this.timeout = null
  }

  disconnect() {
    if (this.timeout) {
      clearTimeout(this.timeout)
    }
  }

  search() {
    // Clear existing timeout
    if (this.timeout) {
      clearTimeout(this.timeout)
    }

    // Set new timeout for debounced submission
    this.timeout = setTimeout(() => {
      this.submit()
    }, 200) // 200ms debounce
  }

  submit() {
    // Submit the form
    this.element.requestSubmit()
  }
}
