<script>
	export let side = 'right'; // 'left' or 'right'
	export let width = '200px';
	export let highlight = false;
</script>

<div class="sidenote-container">
	<div class="sidenote {side} {highlight ? 'highlight' : ''}" style="--sidenote-width: {width}">
		<slot />
	</div>
</div>

<style>
	.sidenote-container {
		position: absolute;
		width: 100%;
		margin: 1rem 0;
	}

	.sidenote {
		position: absolute;
		width: var(--sidenote-width);
		padding: 1rem;
		background-color: var(--color-gray-50);
		border: 1px solid var(--color-gray-200);
		border-radius: 4px;
		font-size: 0.9rem;
		line-height: 1.4;
		box-shadow: 0 2px 4px rgba(0, 0, 0, 0.05);
		transition: background-color 0.2s ease;
		top: 0;
	}

	.sidenote.right {
		left: calc(100% + 2rem);
	}

	.sidenote.left {
		right: calc(100% + 2rem);
	}

	.sidenote.highlight {
		background-color: var(--color-accent);
		color: var(--color-white);
	}

	/* Mobile styles */
	@media screen and (max-width: 768px) {
		.sidenote {
			position: relative;
			width: 100%;
			left: 0;
			right: 0;
			margin: 1rem 0;
		}
	}
</style>
