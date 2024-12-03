/** @type {import('tailwindcss').Config} */
export default {
	content: ['./src/**/*.{html,js,svelte,ts}'],
	theme: {
		extend: {
			fontFamily: {
				asap: ['Asap Variable', 'sans-serif'],
				'asap-italic': ['Asap Variable Italic', 'sans-serif'],
				hindi: ['Alkatra Variable', 'system-ui']
			},
			colors: {
				black: 'oklch(16.76% 0.04 106.83)',
				gray: {
					950: 'oklch(26.83% 0.02 94.63)',
					900: 'oklch(28.5% 0.06 91.57)',
					800: 'oklch(34.38% 0.027 95.72)',
					700: 'oklch(43.34% 0.018 98.6)',
					600: 'oklch(49.81% 0.017 98.53)',
					200: 'oklch(92.07% 0.018 96.12)',
					100: 'oklch(94.82% 0.012 96.43)',
					50: 'oklch(96.65% 0.07 97.35)'
				},
				white: 'oklch(97.89% 0.01 106.42)',
				'white-alpha': 'oklch(100% 0 0 / 90%)',
				accent: 'oklch(58.02% 0.132 40.3)'
			}
		}
	},
	plugins: []
};
