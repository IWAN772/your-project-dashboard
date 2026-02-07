import { Controller } from "@hotwired/stimulus"
import { Turbo } from "@hotwired/turbo-rails"

// Clickable table rows with link preservation
// Entire row is clickable, but links within the row still work normally
export default class extends Controller {
  static values = {
    url: String
  }

  navigate(event) {
    // Don't navigate if user clicked on an actual link or button
    if (event.target.tagName === "A" || event.target.closest("a")) {
      return
    }

    // Don't navigate if user is selecting text
    if (window.getSelection().toString().length > 0) {
      return
    }

    // Support cmd/ctrl+click to open in new tab
    if (event.metaKey || event.ctrlKey) {
      window.open(this.urlValue, "_blank")
    } else {
      Turbo.visit(this.urlValue)
    }
  }
}
