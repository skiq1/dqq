// Import and register all your controllers from the importmap via controllers/**/*_controller
import { application } from "./application"

// Auto-register all controllers
const controllers = import.meta.glob('./*_controller.js', { eager: true })

// confirm_modal_controller.js -> confirm-modal
for (const path in controllers) {
  const module = controllers[path]
  const name = path
    .replace(/^\.\//, '')
    .replace(/_controller\.js$/, '')
    .replace(/_/g, '-')

  application.register(name, module.default)
}
