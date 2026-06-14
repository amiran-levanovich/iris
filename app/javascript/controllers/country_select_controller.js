import { Controller } from "@hotwired/stimulus"

// Searchable country combobox with flag images. A native <select> can't render
// images in its options, so this is a button + filterable panel that writes the
// chosen ISO-2 code into a hidden field.
export default class extends Controller {
  static targets = ["hidden", "button", "label", "panel", "search", "option"]

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
      const match = option.dataset.search.includes(query)
      option.closest("li").hidden = !match
    })
  }

  select(event) {
    const option = event.currentTarget
    this.hiddenTarget.value = option.dataset.value
    // Copy the option's flag + name nodes (trusted, server-rendered) into the
    // label without going through innerHTML.
    this.labelTarget.replaceChildren(...option.cloneNode(true).childNodes)
    this.labelTarget.classList.remove("muted")
    this.close()
  }

  // Close when clicking anywhere outside the component.
  closeOnOutside(event) {
    if (!this.element.contains(event.target)) this.close()
  }
}
