import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["list", "input", "item"]

  add() {
    const input = this.inputTarget
    const value = input.value.trim()
    
    if (!value) return
    
    // Remove empty placeholder if it exists
    const placeholder = document.getElementById("empty-templates-placeholder")
    if (placeholder) placeholder.remove()
    
    // Check for duplicates
    const existingValues = Array.from(this.listTarget.querySelectorAll('input[type="hidden"]'))
      .map(input => input.value)
    
    if (existingValues.includes(value)) {
      input.value = ""
      return
    }
    
    // Create new template item
    const item = document.createElement("div")
    item.className = "flex items-center gap-2"
    item.setAttribute("data-rejection-templates-target", "item")
    item.innerHTML = `
      <input type="hidden" name="event[rejection_reason_templates][]" value="${this.escapeHtml(value)}">
      <span class="flex-1 bg-gray-50 px-3 py-2 rounded-md text-sm text-gray-700">${this.escapeHtml(value)}</span>
      <button type="button" 
              data-action="rejection-templates#remove"
              class="text-red-600 hover:text-red-800 text-sm font-medium">
        Remove
      </button>
    `
    
    this.listTarget.appendChild(item)
    input.value = ""
  }

  remove(event) {
    const item = event.target.closest('[data-rejection-templates-target="item"]')
    if (item) {
      item.remove()
      
      // Add back empty placeholder if no items left
      if (this.itemTargets.length === 0) {
        const placeholder = document.createElement("input")
        placeholder.type = "hidden"
        placeholder.name = "event[rejection_reason_templates][]"
        placeholder.value = ""
        placeholder.id = "empty-templates-placeholder"
        this.listTarget.appendChild(placeholder)
      }
    }
  }

  escapeHtml(text) {
    const div = document.createElement("div")
    div.textContent = text
    return div.innerHTML
  }
}
