<script lang="ts">
	import { onMount } from 'svelte';

	interface Props {
		title?: string;
		description?: string;
		keywords?: string;
		author?: string;
		canonicalUrl?: string;
		ogImage?: string;
		twitterHandle?: string;
		twitterCardType?: 'summary' | 'summary_large_image';
	}

	export let title = 'Default Title';
	export let description = 'Default description of your website';
	export let keywords = 'svelte, seo, web development';
	export let author = 'Your Name';
	export let canonicalUrl = '';
	export let ogImage = '/default-og-image.jpg';
	export let twitterHandle = '@yourtwitterhandle';
	export let twitterCardType = 'summary_large_image';

	let currentUrl;

	onMount(() => {
		currentUrl = window.location.href;
	});
</script>

<svelte:head>
	<!-- Basic Meta Tags -->
	<title>{title}</title>
	<meta name="description" content={description} />
	<meta name="keywords" content={keywords} />
	<meta name="author" content={author} />
	<meta name="robots" content="index, follow" />
	<meta name="viewport" content="width=device-width, initial-scale=1" />

	<!-- Canonical URL -->
	<link rel="canonical" href={canonicalUrl || currentUrl} />

	<!-- Open Graph Tags -->
	<meta property="og:title" content={title} />
	<meta property="og:description" content={description} />
	<meta property="og:image" content="https://dummy-candidates.netlify.app/sharecard.jpg" />
	<meta property="og:url" content={canonicalUrl || currentUrl} />
	<meta property="og:type" content="website" />

	<!-- Twitter Card Tags -->
	<meta name="twitter:card" content={twitterCardType} />
	<meta name="twitter:site" content={twitterHandle} />
	<meta name="twitter:title" content={title} />
	<meta name="twitter:description" content={description} />
	<meta name="twitter:image" content="https://dummy-candidates.netlify.app/sharecard.jpg" />

	<!-- Additional Meta Tags -->
	<meta name="language" content="English" />
	<meta name="revisit-after" content="7 days" />
	<meta name="distribution" content="global" />
	<meta http-equiv="Content-Type" content="text/html; charset=utf-8" />
</svelte:head>
