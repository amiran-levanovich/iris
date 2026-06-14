import { Controller } from "@hotwired/stimulus"

// Debounced guest search into a Turbo Frame; picking a result fills the hidden
// guest_id in place, no round trip. Inline create comes back as a Turbo Stream.
export default class extends Controller {
  static targets = ["input", "results", "hidden", "display"]
  static values = { url: String }

  search() {
    clearTimeout(this.timeout)
    this.timeout = setTimeout(() => {
      const query = this.inputTarget.value.trim()
      this.resultsTarget.src = `${this.urlValue}?q=${encodeURIComponent(query)}`
    }, 250)
  }

  pick(event) {
    event.preventDefault()
    const { guestId, guestName } = event.currentTarget.dataset
    this.hiddenTarget.value = guestId
    this.displayTarget.textContent = guestName
    this.displayTarget.classList.remove("muted")
    this.inputTarget.value = guestName
    this.resultsTarget.replaceChildren()
  }
}
