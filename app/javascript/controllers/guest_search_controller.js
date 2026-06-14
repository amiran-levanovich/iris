import { Controller } from "@hotwired/stimulus"

// Debounced guest search that drops an autocomplete panel below the search bar
// (a Turbo Frame). Picking a result fills the hidden guest_id in place; no match
// offers a link to the full new-guest form.
export default class extends Controller {
  static targets = ["input", "results", "hidden", "display"]
  static values = { url: String }

  search() {
    clearTimeout(this.timeout)
    this.timeout = setTimeout(() => {
      const query = this.inputTarget.value.trim()
      if (query === "") {
        this.close()
        return
      }
      this.resultsTarget.src = `${this.urlValue}?q=${encodeURIComponent(query)}`
    }, 250)
  }

  // The search box lives inside the booking form; Enter would otherwise submit
  // the whole reservation instead of just confirming a guest search.
  preventSubmit(event) {
    event.preventDefault()
  }

  pick(event) {
    event.preventDefault()
    const { guestId, guestName } = event.currentTarget.dataset
    this.hiddenTarget.value = guestId
    this.displayTarget.textContent = guestName
    this.displayTarget.classList.remove("muted")
    this.inputTarget.value = guestName
    this.close()
  }

  // Dismiss the panel when the field loses focus, delayed so a click on a
  // result (which blurs the input first) still registers.
  hide() {
    this.timeout = setTimeout(() => this.close(), 150)
  }

  close() {
    this.resultsTarget.removeAttribute("src")
    this.resultsTarget.replaceChildren()
  }
}
