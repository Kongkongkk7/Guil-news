export default {
  content: [
    "./index.html",
    "./src/**/*.{js,ts,jsx,tsx}",
  ],
  theme: {
    extend: {
      colors: {
        ' Guilin': {
          'river': '#2DD4BF',
          'mountain': '#0D9488',
          'mist': '#F0FDFA',
          'rock': '#E7E5E4',
          'academic': '#1E3A5F',
          'gold': '#D4AF37',
        }
      },
      backgroundImage: {
        'mountain-pattern': "url('/mountains.svg')",
      }
    },
  },
  plugins: [],
}