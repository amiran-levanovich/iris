import { Controller } from "@hotwired/stimulus"

// Reloads the available-rooms frame whenever the stay dates change, so the room
// list reflects current availability without resetting the rest of the form.
export default class extends Controller {
  static targets = ["date"]
  static values = { url: String }

  refresh() {
    const params = new URLSearchParams()
    this.dateTargets.forEach((input) => {
      if (!input.value) return
      const key = input.name.replace(/.*\[(.+)\]/, "$1")
      params.set(key, input.value)
    })

    const frame = document.getElementById("available_rooms")
    if (frame) frame.src = `${this.urlValue}?${params}`
  }
}
