/** @type {import('tailwindcss').Config} */
module.exports = {
  content: [
    './app/**/*.{ts,tsx,js,jsx}',
    './components/**/*.{ts,tsx,js,jsx}',
  ],
  theme: {
    extend: {
      colors: {
        brand: {
          DEFAULT: '#dc2626',
          light: '#f87171',
          dark: '#b91c1c',
        },
        techBlue: '#0ea5e9',
        techbes: {
          DEFAULT: '#0b1220',
          gold: '#E0B23A',
          red: '#E53935',
        },
      },
    },
  },
  plugins: [],
}
