const defaultTheme = require('tailwindcss/defaultTheme')

module.exports = {
  content: [
    './app/views/**/*.html.erb',
    './app/helpers/**/*.rb',
    './app/assets/stylesheets/**/*.css',
    './app/javascript/**/*.js'
  ],
  // darkMode: 'class',
  theme: {
    fontFamily: {
      'body': [
        'Inter', 
        'ui-sans-serif', 
        'system-ui', 
        '-apple-system', 
        'system-ui', 
        'Segoe UI', 
        'Roboto', 
        'Helvetica Neue', 
        'Arial', 
        'Noto Sans', 
        'sans-serif', 
        'Apple Color Emoji', 
        'Segoe UI Emoji', 
        'Segoe UI Symbol', 
        'Noto Color Emoji'
      ],
      'sans': [
        'Inter', 
        'ui-sans-serif', 
        'system-ui', 
        '-apple-system', 
        'system-ui', 
        'Segoe UI', 
        'Roboto', 
        'Helvetica Neue', 
        'Arial', 
        'Noto Sans', 
        'sans-serif', 
        'Apple Color Emoji', 
        'Segoe UI Emoji', 
        'Segoe UI Symbol', 
        'Noto Color Emoji'
      ]
    },
    extend: {
      fontFamily: {
        sans: ['Inter var', ...defaultTheme.fontFamily.sans],
      },
      colors: {
        primary: {
          "50":"#eff6ff",
          "100":"#dbeafe",
          "200":"#bfdbfe",
          "300":"#93c5fd",
          "400":"#60a5fa",
          "500":"#3b82f6",
          "600":"#2563eb",
          "700":"#1d4ed8",
          "800":"#1e40af",
          "900":"#1e3a8a",
          "950":"#172554"
        }
      }
    },
  },
  plugins: [
    function({ addVariant }) {
      addVariant('light', 'html:not(.dark) &')
    }
  ]
}
