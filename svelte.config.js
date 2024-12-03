import adapter from '@sveltejs/adapter-static';
import { mdsvex } from 'mdsvex';
import { vitePreprocess } from '@sveltejs/vite-plugin-svelte';

const mdsvexOptions = {
	extensions: ['.md', '.mdx']
};

/** @type {import('@sveltejs/kit').Config} */
const config = {
	extensions: ['.svelte', '.md', '.mdx'],
	kit: {
		adapter: adapter()
	},
	preprocess: [vitePreprocess(), mdsvex(mdsvexOptions)]
};

export default config;
