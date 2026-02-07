import { Controller } from "@hotwired/stimulus"

// Quick actions controller for opening projects in editor, terminal, etc.
export default class extends Controller {
  static values = {
    path: String
  }

  openEditor() {
    // Open in Zed using zed:// URI scheme
    const uri = `zed://file${this.pathValue}`
    window.location.href = uri
  }

  openTerminal() {
    // Open in Warp terminal using warp:// URI scheme
    const uri = `warp://action/new_window?path=${encodeURIComponent(this.pathValue)}`
    window.location.href = uri
  }

  copyPath() {
    // Copy path to clipboard
    navigator.clipboard.writeText(this.pathValue).then(() => {
      this.showToast("Path copied to clipboard!")
    }).catch(err => {
      console.error('Failed to copy path:', err)
      this.showToast("Failed to copy path", "error")
    })
  }

  showToast(message, type = "success") {
    // Create a simple toast notification
    const toast = document.createElement('div')
    toast.className = `fixed bottom-4 right-4 px-4 py-3 rounded-lg shadow-lg text-white text-sm font-medium transition-opacity duration-300 z-50 ${
      type === "success" ? "bg-green-600" : "bg-red-600"
    }`
    toast.textContent = message
    document.body.appendChild(toast)

    // Fade out and remove after 3 seconds
    setTimeout(() => {
      toast.style.opacity = "0"
      setTimeout(() => toast.remove(), 300)
    }, 3000)
  }
}
