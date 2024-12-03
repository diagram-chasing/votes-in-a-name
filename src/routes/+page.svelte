<script>
	import SEO from '$components/primary/SEO.svelte';
	import { dev } from '$app/environment';
	export let data = {};
</script>

<SEO {...data.metadata} />

<!-- <svelte:head>
	{#if !dev}
		<base href="https://dummy-candidates.netlify.app/" target="_blank" />
	{/if}
</svelte:head> -->

<section class="root-section">
	<svelte:component this={data.content} />
</section>

<style>
	.root-section {
		display: flex;
		flex-direction: column;
		justify-content: center;
		gap: 1rem;
		width: 100%;
		max-width: none;
		margin: 0;
		padding: 0 1rem 1.75rem 1rem;
	}
</style>
