/** @type {import('tailwindcss').Config} */
module.exports = {
  content: [
    './app/**/*.{ts,tsx,js,jsx}',
    './components/**/*.{ts,tsx,js,jsx}',
  ],
  theme: {
    extend: {
      colors: {
        techbes: {
          DEFAULT: '#0b1220',
          gold: '#E0B23A',
          red: '#E53935'
        }
      }
    },
  },
  plugins: [],
}
