import { sveltekit } from '@sveltejs/kit/vite';
import { defineConfig } from 'vite';

import path from 'path';

export default defineConfig({
	plugins: [sveltekit()],
	resolve: {
		alias: {
			$lib: path.resolve('./src/lib'),
			$components: path.resolve('./src/lib/components'),
			$assets: path.resolve('./src/lib/assets'),
			$styles: path.resolve('./src/lib/styles'),
			$utils: path.resolve('./src/utils'),
			$config: path.resolve('./src/config')
		}
	}
});
