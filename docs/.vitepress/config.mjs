import { defineConfig } from 'vitepress'

// https://vitepress.dev/reference/site-config
export default defineConfig({
  title: "LuauEvent",
  base: "/LuauEvent/",
  lang: 'en-US',
  themeConfig: {
    // https://vitepress.dev/reference/default-theme-config
    nav: [
      { text: 'Into', link: '/intro/introduction' },
      { text: 'API Reference', link: '/classes/bindable' }
    ],

    sidebar: {
      '/intro/': [
        {
          text: 'Introduction',
          items: [
            { text: 'Description', link: '/intro/introduction' },
            { text: 'Features', link: '/intro/features' }
          ]
        },
      ],
      '/classes/': [
        {
          text: 'Classes',
          items: [
            { text: 'Bindable', link: '/classes/bindable' },
            { text: 'Signal', link: '/classes/signal' },
            { text: 'Connection', link: '/classes/connection' },
          ]
        },
      ],
    },

    socialLinks: [
      { icon: 'github', link: 'https://github.com/Aspecky/LuauEvent' }
    ]
  }
})
