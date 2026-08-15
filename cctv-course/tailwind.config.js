/** @type {import('tailwindcss').Config} */
module.exports = {
  content: [
    './app/**/*.{ts,tsx,js,jsx}',
    './components/**/*.{ts,tsx,js,jsx}',
  ],
  theme: {
    extend: {
      fontFamily: {
        sans: ['"Plus Jakarta Sans"', 'sans-serif'],
        jakarta: ['"Plus Jakarta Sans"', 'sans-serif'],
      },
      colors: {
        gold: {
          DEFAULT: '#F5C842',
          dark:    '#E0B23A',
          light:   '#FFD96A',
        },
        techred: {
          DEFAULT: '#E53935',
          dark:    '#C62828',
          light:   '#EF5350',
        },
        navy: {
          1: '#050912',
          2: '#0A1020',
          3: '#101A2D',
          4: '#111827',
        },
        techblue: '#0EA5E9',
        techbes: {
          DEFAULT: '#0b1220',
          gold: '#E0B23A',
          red:  '#E53935',
        },
        brand: {
          DEFAULT: '#dc2626',
          light:   '#f87171',
          dark:    '#b91c1c',
        },
      },
      keyframes: {
        float: {
          '0%, 100%': { transform: 'translateY(0px)' },
          '50%':       { transform: 'translateY(-14px)' },
        },
        'float-reverse': {
          '0%, 100%': { transform: 'translateY(0px)' },
          '50%':       { transform: 'translateY(10px)' },
        },
        shimmer: {
          '0%':   { backgroundPosition: '-200% 0' },
          '100%': { backgroundPosition:  '200% 0' },
        },
        'pulse-glow': {
          '0%, 100%': { opacity: '0.5' },
          '50%':       { opacity: '1' },
        },
        'spin-slow': {
          '0%':   { transform: 'rotate(0deg)' },
          '100%': { transform: 'rotate(360deg)' },
        },
      },
      animation: {
        float:           'float 7s ease-in-out infinite',
        'float-reverse': 'float-reverse 9s ease-in-out infinite',
        'float-slow':    'float 11s ease-in-out infinite',
        shimmer:         'shimmer 3s linear infinite',
        'pulse-glow':    'pulse-glow 2.5s ease-in-out infinite',
        'spin-slow':     'spin-slow 20s linear infinite',
      },
      screens: {
        xs: '375px',
      },
      maxWidth: {
        section: '1320px',
      },
    },
  },
  plugins: [],
}
