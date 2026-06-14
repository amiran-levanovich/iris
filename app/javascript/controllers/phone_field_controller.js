import { Controller } from "@hotwired/stimulus"

// Phone input = a flag/dial-code combobox + a local-number field, combined into
// one stored string like "+49 301234567". Mirrors country_select for the dial
// dropdown, then keeps the hidden guest[phone] in sync.
export default class extends Controller {
  static targets = ["hidden", "number", "button", "label", "panel", "search", "option"]

  connect() {
    this.parseExisting()
  }

  toggle() {
    this.panelTarget.hidden ? this.open() : this.close()
  }

  open() {
    this.panelTarget.hidden = false
    this.searchTarget.value = ""
    this.filter()
    this.searchTarget.focus()
  }

  close() {
    this.panelTarget.hidden = true
  }

  filter() {
    const query = this.searchTarget.value.trim().toLowerCase()
    this.optionTargets.forEach((option) => {
      option.closest("li").hidden = !option.dataset.search.includes(query)
    })
  }

  selectDial(event) {
    const option = event.currentTarget
    this.dial = option.dataset.dial
    this.setLabel(option)
    this.close()
    this.recompute()
    this.numberTarget.focus()
  }

  // The dial button shows just the flag + "+code", not the full country name.
  setLabel(option) {
    const flag = option.querySelector(".flag").cloneNode(true)
    const code = document.createElement("span")
    code.className = "dial"
    code.textContent = `+${option.dataset.dial}`
    this.labelTarget.replaceChildren(flag, code)
    this.labelTarget.classList.remove("muted")
  }

  recompute() {
    const number = this.numberTarget.value.trim()
    const prefix = this.dial ? `+${this.dial}` : ""
    this.hiddenTarget.value = [prefix, number].filter(Boolean).join(" ")
  }

  // Split an existing "+49 301234567" back into dial + local number, matching the
  // longest known dial code.
  parseExisting() {
    const value = this.hiddenTarget.value.trim()
    if (!value) return

    const digits = value.replace(/[^\d+]/g, "")
    if (digits.startsWith("+")) {
      const dials = this.optionTargets
        .map((o) => o.dataset.dial)
        .sort((a, b) => b.length - a.length)
      const bare = digits.slice(1)
      const match = dials.find((d) => bare.startsWith(d))
      if (match) {
        this.dial = match
        this.numberTarget.value = bare.slice(match.length)
        const option = this.optionTargets.find((o) => o.dataset.dial === match)
        if (option) this.setLabel(option)
        return
      }
    }
    this.numberTarget.value = value
  }

  closeOnOutside(event) {
    if (!this.element.contains(event.target)) this.close()
  }
}
