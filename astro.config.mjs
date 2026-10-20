import { defineConfig } from 'astro/config';
import tailwindcss from '@tailwindcss/vite';

export default defineConfig({
  site: 'https://caromancie.be',
  output: 'static',
  vite: { plugins: [tailwindcss()] },
});
