// To see this message, add the following to the `<head>` section in your
// views/layouts/application.html.erb
//
//    <%= vite_client_tag %>
//    <%= vite_javascript_tag 'application' %>

// If using a TypeScript entrypoint file:
//     <%= vite_typescript_tag 'application' %>
//
// If you want to use .jsx or .tsx, add the extension:
//     <%= vite_javascript_tag 'application.jsx' %>

// Example: Load Rails libraries in Vite.
//
// import * as Turbo from '@hotwired/turbo'
// Turbo.start()
//
// import ActiveStorage from '@rails/activestorage'
// ActiveStorage.start()
//
// // Import all channels.
// const channels = import.meta.glob('./**/*_channel.js', { eager: true })

// Example: Import a stylesheet in app/frontend/index.css
// import '~/index.css'
import '@hotwired/turbo-rails'
import '../controllers'
import * as bootstrap from 'bootstrap'
import '../styles/application.scss'

import { createApp } from 'vue'

// Automatyczne montowanie Vue na [data-vue-component]
document.addEventListener('turbo:load', () => {
  const vueComponents = document.querySelectorAll('[data-vue-component]')

  vueComponents.forEach(element => {
    const componentName = element.dataset.vueComponent

    import(`../components/${componentName}.vue`).then((module) => {
      const app = createApp(module.default)
      app.mount(element)
    })
  })
})
