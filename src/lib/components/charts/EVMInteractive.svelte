<script>
	import compareName from './compare-algorithms/calculate-similarity';
	import FaceGenerator from './FaceGenerator.svelte';
	import sampleNamePairs from './compare-algorithms/sample_names.json';
	import { RefreshCw } from 'lucide-svelte';
	import { smScreen, mdScreen, lgScreen, cls } from 'svelte-ux';
	import EVM from '$assets/evm.png';
	import { spring, tweened } from 'svelte/motion';

	function convertNameToSeed(name) {
		return name.split('').reduce((acc, char) => acc + char.charCodeAt(0), 0);
	}

	function generateDifferentSeed(originalSeed) {
		return originalSeed + 999;
	}

	let name1 = '';
	let name2 = '';
	let result = null;
	let secondSeed;

	let bisimValue = tweened(0);
	let diceValue = tweened(0);
	let jwValue = tweened(0);
	let averageValue = tweened(0);

	function handleCompare() {
		if (name1 && name2) {
			result = compareName(name1, name2);
			const threshold = 0.3;
			const firstSeed = convertNameToSeed(name1);
			if (result.average < threshold) {
				secondSeed = generateDifferentSeed(firstSeed);
			} else {
				secondSeed = firstSeed;
			}

			bisimValue.set(result.bisim);
			diceValue.set(result.dice);
			jwValue.set(result.jw);
			averageValue.set(result.average);
		}
	}

	$: if (name1 && name2) {
		handleCompare();
	}

	let currentSamples = [];

	function getRandomSamples(count = 3) {
		const shuffled = [...sampleNamePairs].sort(() => 0.5 - Math.random());
		return shuffled.slice(0, count);
	}

	function refreshSamples() {
		// On mobile, directly set a random pair
		const randomPair = getRandomSamples(1)[0];
		name1 = randomPair.Ref_Candidate;
		name2 = randomPair.Dummy_Candidate;
	}

	refreshSamples();

	let canvasSize;

	$: if (!$smScreen && !$mdScreen) {
		canvasSize = 35;
	} else if (!$mdScreen && !$lgScreen) {
		canvasSize = 100;
	} else if (!$lgScreen) {
		canvasSize = 4;
	}
</script>

<div class="px-2 outer-container ignore-w-100">
	<div class="comparison-container ignore-w-100">
		<div class="flex flex-col justify-between gap-2 my-4 md:gap-0 md:items-center md:flex-row">
			<div>
				<h4>Enter any two names</h4>
				<p class="text-sm text-gray-600">...and see what your face cards look like</p>
			</div>
			<button
				on:click={refreshSamples}
				class="flex items-center gap-1 px-2 py-2 text-xs bg-gray-100 border-2 rounded-sm ignore-w-100 group border-color-accent hover:bg-gray-200 font-asap-italic whitespace-nowrap"
				>Or choose a random pair from an election
				<RefreshCw
					size={16}
					class="transition-transform group-hover:animate-[spin_0.3s_ease-in-out] duration-300 stroke-gray-600 group-active:animate-[spin_0.3s_ease-in-out]"
				/>
			</button>
		</div>
		<div class="flex flex-col items-center justify-start gap-1 md:gap-6 md:flex-row ignore-w-100">
			<div class="input-field">
				<label for="name1" class="sr-only">First Name</label>
				<input id="name1" type="text" bind:value={name1} placeholder="Type a name..." />
			</div>

			<div class="my-0 comparison-divider">
				<span>compared to</span>
			</div>

			<div class="input-field">
				<label for="name2" class="sr-only">Second Name</label>
				<input id="name2" type="text" bind:value={name2} placeholder="Type another name..." />
			</div>
		</div>

		<div class="results-container">
			<div class="relative">
				<img src={EVM} alt="EVM" class="w-full h-auto" />

				<div
					class="absolute top-0 left-[4%] md:left-[7%] h-full flex flex-col justify-center gap-5 md:gap-6 p-4"
				>
					<div class="flex items-center gap-2 md:gap-4 h-[10%] md:h-[15%]">
						{#if name1}
							<FaceGenerator
								seed={convertNameToSeed(name1)}
								bisim={1}
								dice={1}
								jw={1}
								size={canvasSize}
								average={1}
							/>
							<p
								class="md:text-2xl text-sm first-letter:uppercase max-w-[120px] font-bold font-asap text-gray-950 whitespace-nowrap overflow-hidden text-ellipsis sm:max-w-[150px] md:max-w-[300px]"
							>
								{name1}
							</p>
						{:else}
							<div class="w-[35px] md:w-[100px]"></div>
							<div class="h-[24px] md:h-[32px] max-w-[120px]"></div>
						{/if}
					</div>

					<div class="flex items-center gap-2 md:gap-4 h-[10%] md:h-[15%]">
						{#if result && name2}
							<FaceGenerator
								seed={secondSeed}
								bisim={result.bisim}
								dice={result.dice}
								jw={result.jw}
								size={canvasSize}
								average={result.average}
							/>
							<p
								class="md:text-2xl text-sm max-w-[120px] font-bold font-asap text-gray-950 whitespace-nowrap overflow-hidden first-letter:uppercase text-ellipsis sm:max-w-[150px] md:max-w-[300px]"
							>
								{name2}
							</p>
						{:else}
							<div class="w-[35px] md:w-[100px]"></div>
							<div class="h-[24px] md:h-[32px] max-w-[120px]"></div>
						{/if}
					</div>
				</div>
			</div>
			<!-- <div
				class="absolute px-4 mb-2 bottom-[10%] left-[50%] -translate-x-[50%] text-sm text-center text-gray-600"
			>
				{#if result}
					<p class="px-4 mb-2 text-sm text-center text-gray-600 whitespace-nowrap">
						{#if result.average < 0.3}
							These people would not be confused with each other.
						{:else if result.average < 0.7}
							These people could be confused with each other.
						{:else}
							These people are very similar to each other.
						{/if}
					</p>
				{/if}
			</div> -->
			<div class="z-10 w-full max-w-md pt-1 mx-auto -mt-12 border-t border-gray-200 md:-mt-20">
				<div class="metrics-container" class:inactive={!result}>
					<div class="grid grid-cols-4 gap-4 px-4">
						<div class="flex flex-col items-center justify-center h-16 text-center">
							<span class="text-xs font-medium text-gray-950">BI-SIM</span>
							<span class="text-sm font-bold tabular-nums h-[28px]">
								{result ? ($bisimValue * 100).toFixed(1) + '%' : '—'}
							</span>
						</div>
						<div class="flex flex-col items-center justify-center h-16 text-center">
							<span class="text-xs font-medium text-gray-950">Dice</span>
							<span class="text-sm font-bold tabular-nums h-[28px]">
								{result ? ($diceValue * 100).toFixed(1) + '%' : '—'}
							</span>
						</div>
						<div class="flex flex-col items-center justify-center h-16 text-center">
							<span class="text-xs font-medium text-gray-950">JW</span>
							<span class="text-sm font-bold tabular-nums h-[28px]">
								{result ? ($jwValue * 100).toFixed(1) + '%' : '—'}
							</span>
						</div>
						<div class="flex flex-col items-center justify-center h-16 text-center">
							<span class="text-xs font-medium text-gray-950 whitespace-nowrap"
								>Total Similarity</span
							>

							<span
								class={`tabular-nums text-sm font-bold h-[28px] ${
									result
										? $averageValue < 0.4
											? 'text-red-500'
											: $averageValue >= 0.4 && $averageValue <= 0.71
												? 'text-yellow-400'
												: 'text-green-500'
										: ''
								}`}
							>
								{result ? ($averageValue * 100).toFixed(1) + '%' : '—'}
							</span>
						</div>
					</div>
				</div>
			</div>
		</div>
	</div>
</div>

<style>
	.outer-container {
		width: 100%;
		overflow-x: hidden;
		position: relative; /* Create new containing block */
	}

	.comparison-container {
		width: min(100%, 40rem);
		margin-inline: auto;
	}

	.input-group {
		display: flex;
		align-items: center;
		gap: 1.5rem;
		width: 100%;
		min-width: 0;
	}

	.comparison-divider {
		color: var(--color-gray-600);
		font-size: 0.9rem;
		font-style: italic;
	}

	.input-field {
		flex: 1;
		min-width: 0;
		width: 100%;
	}

	label {
		display: block;
		margin-bottom: 0.5rem;
		font-weight: 600;
		font-size: 0.9rem;
		color: var(--color-gray-700);
	}

	input {
		width: 100%;
		min-width: 0;
		box-sizing: border-box;
		padding: 0.75rem;
		border: 2px solid var(--color-gray-200);
		border-radius: 6px;
		font-size: 1.1rem;
		transition: border-color 0.2s;
	}

	input:focus {
		outline: none;
		border-color: var(--color-gray-400);
	}

	.results-container {
		display: flex;
		flex-direction: column;
		gap: 3rem;
		margin-top: 1rem;
	}

	.evm-container {
		position: relative;
		width: 100%;
	}

	.evm-image {
		width: 100%;
		height: auto;
	}

	.faces-overlay {
		position: absolute;
		top: 0;
		left: 7%;
		height: 100%;

		display: flex;
		flex-direction: column;
		justify-content: center;
		gap: 1.5rem;
		padding: 1rem;
	}

	.face-row {
		display: flex;
		align-items: center;
		gap: 1rem;
		height: 15%;
	}

	.name-label {
		font-size: 1.5rem;
		min-width: 120px;
		font-weight: 700;
		font-family: 'Asap Variable', sans-serif;
		color: var(--color-gray-950);
		/* Ellipsis */
		white-space: nowrap;
		overflow: hidden;
		text-overflow: ellipsis;
		max-width: 300px;
	}

	.samples-header {
		display: flex;
		align-items: center;
		gap: 0.5rem;
		margin-bottom: 0.75rem;
	}

	.samples-title {
		font-size: 0.9rem;
		color: var(--color-gray-600);
		font-style: italic;
	}

	.refresh-button {
		padding: 0.25rem;
		border: none;
		background: transparent;
		color: var(--color-gray-500);
		cursor: pointer;
		border-radius: 4px;
		display: flex;
		align-items: center;
		justify-content: center;
		transition: all 0.2s;
	}

	.refresh-button:hover {
		background: var(--color-gray-200);
		color: var(--color-gray-700);
	}

	.sample-buttons {
		display: flex;
		width: fit-content;
		gap: 0.5rem;
	}

	.sample-button {
		padding: 0.5rem 0.75rem;
		background: white;
		border: 1px solid var(--color-gray-200);
		border-radius: 6px;
		font-size: 0.85rem;
		cursor: pointer;
		transition: all 0.2s;
		display: flex;
		align-items: center;
		gap: 0.5rem;
	}

	.sample-button:hover {
		background: var(--color-gray-100);
		border-color: var(--color-gray-300);
	}

	.sample-separator {
		color: var(--color-gray-400);
	}

	.sample-name {
		max-width: 150px;
		overflow: hidden;
		text-overflow: ellipsis;
		white-space: nowrap;
	}
</style>
