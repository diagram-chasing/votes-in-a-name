<script>
	import { ArrowLeftRight } from 'lucide-svelte';

	export let initialValue = '';
	export let useThousands = true;

	let isLakhToOther = true;
	let originalValue = parseFloat(initialValue.replace(/,/g, ''));

	function toggleDirection() {
		isLakhToOther = !isLakhToOther;
	}

	$: displayValue = isLakhToOther
		? originalValue / 100000
		: useThousands
			? originalValue
			: originalValue / 1000000;

	$: formattedValue =
		useThousands && !isLakhToOther
			? displayValue.toLocaleString()
			: displayValue.toLocaleString(undefined, {
					maximumFractionDigits: 2,
					minimumFractionDigits: 0
				});

	$: otherUnit = useThousands ? '' : 'million';
</script>

<span class="inline ignore-w-100 w-fit converter-wrapper">
	<button
		class="flex items-center justify-center gap-1 bg-gray-600 toggle"
		on:click={toggleDirection}
	>
		<ArrowLeftRight size={14} />

		{#if !isNaN(displayValue)}
			<span class="value">
				{formattedValue}
				{isLakhToOther ? 'lakh' : otherUnit}
			</span>
		{/if}
	</button>
</span>

<style>
	.converter-wrapper {
		display: inline-flex;
		align-items: center;

		gap: 0.25rem;
		white-space: nowrap;
	}

	.toggle {
		all: unset;
		cursor: pointer;
		display: inline-flex;
		align-items: center;
		gap: 0.25rem;
		padding: 0 0.55rem;
		color: var(--accent, #666);
		transition: color 0.2s;
		background-color: var(--color-gray-200, #666);
		border-radius: 0.15rem;
		border: 1px solid var(--color-gray-600);
	}

	.toggle:hover {
		color: var(--accent-hover, #333);
	}

	.value {
		display: inline-flex;
		align-items: center;
	}
</style>
