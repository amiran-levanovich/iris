import { Controller } from "@hotwired/stimulus"

// Debounced guest search that drops an autocomplete panel below the search bar
// (a Turbo Frame). Picking a result fills the hidden guest_id in place; no match
// offers a link to the full new-guest form.
export default class extends Controller {
  static targets = ["input", "results", "hidden", "display"]
  static values = { url: String, returnTo: String }

  search() {
    clearTimeout(this.timeout)
    this.timeout = setTimeout(() => {
      const query = this.inputTarget.value.trim()
      if (query === "") {
        this.close()
        return
      }
      const params = new URLSearchParams({ q: query })
      const returnTo = this.bookingReturnPath()
      if (returnTo) params.set("return_to", returnTo)
      this.resultsTarget.src = `${this.urlValue}?${params}`
    }, 250)
  }

  // Path back to the current booking form, carrying the dates the operator has
  // entered, so a "create new guest" detour can return here with them intact.
  bookingReturnPath() {
    if (!this.hasReturnToValue || this.returnToValue === "") return null

    const url = new URL(this.returnToValue, window.location.origin)
    const form = this.element.closest("form")
    if (form) {
      const checkIn = form.querySelector('[name="reservation[check_in_on]"]')?.value
      const checkOut = form.querySelector('[name="reservation[check_out_on]"]')?.value
      if (checkIn) url.searchParams.set("check_in_on", checkIn)
      if (checkOut) url.searchParams.set("check_out_on", checkOut)
    }
    return url.pathname + url.search
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
