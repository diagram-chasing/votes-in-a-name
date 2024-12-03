<script>
	export let width = '100vw';
	export let align = 'center';
</script>

<div class="full-bleed" style:--width={width} style:--align={align}>
	<div class="content">
		<slot />
	</div>
</div>

<style>
	.full-bleed {
		width: 100%;
		margin-left: 50%;
		transform: translateX(-50%);
		position: relative;
	}

	.content {
		max-width: 52rem;
		margin: 0 auto;
	}

	/* Breakout styles only apply on desktop */
	@media (min-width: 768px) {
		.full-bleed {
			width: 100%;
		}

		.content :global(.breakout) {
			width: var(--width);
			margin-left: 50%;
			transform: translateX(-50%);
			position: relative;
			max-width: 82rem;
		}

		.content :global(.breakout.align-start) {
			padding-left: calc((100% - 52rem) / 2);
			padding-right: 1rem;
		}

		.content :global(.breakout.align-end) {
			padding-right: calc((100% - 52rem) / 2);
			padding-left: 1rem;
		}
	}
</style>
