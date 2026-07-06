module.exports = {
  content: [
    "./src/renderer/**/*.html",
    "./src/renderer/**/*.js",
    "./src/main/**/*.ts"
  ],
  theme: {
    extend: {
      fontFamily: {
        sans: ["Inter", "ui-sans-serif", "system-ui", "sans-serif"],
        mono: ["SFMono-Regular", "ui-monospace", "SFMono-Regular", "Menlo", "monospace"]
      }
    }
  },
  plugins: []
};
