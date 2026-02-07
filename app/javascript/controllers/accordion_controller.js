import { Controller } from "@hotwired/stimulus"

// Accordion controller for collapsible content sections
export default class extends Controller {
  static targets = ["content", "icon"]

  toggle(event) {
    const button = event.currentTarget
    const content = button.nextElementSibling
    const icon = button.querySelector('[data-accordion-target="icon"]')

    if (content.classList.contains('hidden')) {
      // Expand
      content.classList.remove('hidden')
      if (icon) {
        icon.style.transform = 'rotate(180deg)'
      }
      button.setAttribute('aria-expanded', 'true')
    } else {
      // Collapse
      content.classList.add('hidden')
      if (icon) {
        icon.style.transform = 'rotate(0deg)'
      }
      button.setAttribute('aria-expanded', 'false')
    }
  }
}
