<script>
	import { Pointer } from 'lucide-svelte';
	// Grid configuration
	const cellSize = 35;
	const padding = 2;

	// Define the grid data
	const stateGrid = [
		{ code: 'JK', name: 'Jammu and Kashmir', row: 1, col: 3 },
		{ code: 'PB', name: 'Punjab', row: 2, col: 3 },
		{ code: 'HP', name: 'Himachal Pradesh', row: 2, col: 4 },
		{ code: 'HR', name: 'Haryana', row: 3, col: 3 },
		{ code: 'UK', name: 'Uttarakhand', row: 3, col: 4 },
		{ code: 'AR', name: 'Arunachal Pradesh', row: 3, col: 9 },
		{ code: 'RJ', name: 'Rajasthan', row: 4, col: 2 },
		{ code: 'DL', name: 'Delhi', row: 4, col: 3 },
		{ code: 'UP', name: 'Uttar Pradesh', row: 4, col: 4 },
		{ code: 'BR', name: 'Bihar', row: 4, col: 5 },
		{ code: 'SK', name: 'Sikkim', row: 4, col: 7 },
		{ code: 'AS', name: 'Assam', row: 4, col: 8 },
		{ code: 'NL', name: 'Nagaland', row: 4, col: 9 },
		{ code: 'GJ', name: 'Gujarat', row: 5, col: 1 },
		{ code: 'MP', name: 'Madhya Pradesh', row: 5, col: 3 },
		{ code: 'JH', name: 'Jharkhand', row: 5, col: 5 },
		{ code: 'WB', name: 'West Bengal', row: 5, col: 6 },
		{ code: 'ML', name: 'Meghalaya', row: 5, col: 8 },
		{ code: 'MN', name: 'Manipur', row: 5, col: 9 },
		{ code: 'MH', name: 'Maharashtra', row: 6, col: 2 },
		{ code: 'CG', name: 'Chhattisgarh', row: 6, col: 4 },
		{ code: 'OD', name: 'Odisha', row: 6, col: 5 },
		{ code: 'TR', name: 'Tripura', row: 6, col: 8 },
		{ code: 'MZ', name: 'Mizoram', row: 6, col: 9 },
		{ code: 'TS', name: 'Telangana', row: 6, col: 3 },
		{ code: 'GA', name: 'Goa', row: 7, col: 2 },
		{ code: 'KA', name: 'Karnataka', row: 7, col: 3 },
		{ code: 'AP', name: 'Andhra Pradesh', row: 7, col: 4 },
		{ code: 'KL', name: 'Kerala', row: 8, col: 3 },
		{ code: 'TN', name: 'Tamil Nadu', row: 8, col: 4 }
	];

	// Calculate SVG dimensions
	const maxRow = Math.max(...stateGrid.map((d) => d.row));
	const maxCol = Math.max(...stateGrid.map((d) => d.col));
	const width = maxCol * (cellSize + padding) + padding;
	const height = maxRow * (cellSize + padding) + padding;

	// Add state name mapping
	const stateNameMapping = {
		JK: 'Jammu_&_Kashmir',
		DL: 'Delhi',
		PB: 'Punjab',
		HP: 'Himachal_Pradesh',
		HR: 'Haryana',
		UK: 'Uttarakhand',
		AR: 'Arunachal_Pradesh',
		RJ: 'Rajasthan',
		UP: 'Uttar_Pradesh',
		BR: 'Bihar',
		SK: 'Sikkim',
		AS: 'Assam',
		NL: 'Nagaland',
		GJ: 'Gujarat',
		MP: 'Madhya_Pradesh',
		JH: 'Jharkhand',
		WB: 'West_Bengal',
		ML: 'Meghalaya',
		MN: 'Manipur',
		MH: 'Maharashtra',
		CG: 'Chhattisgarh',
		OD: 'Odisha',
		TR: 'Tripura',
		MZ: 'Mizoram',
		TS: 'Telangana',
		GA: 'Goa',
		KA: 'Karnataka',
		AP: 'Andhra_Pradesh',
		KL: 'Kerala',
		TN: 'Tamil_Nadu'
	};

	import { createEventDispatcher, onMount } from 'svelte';
	const dispatch = createEventDispatcher();

	function handleStateClick(state) {
		console.log('handleStateClick called with:', state);
		const fullStateName = stateNameMapping[state.code];
		dispatch('stateSelect', {
			...state,
			fullName: fullStateName
		});
	}

	export let selectedState = null;

	onMount(() => {
		console.log('onMount running');
		// Find Punjab state object
		const punjabState = stateGrid.find((state) => state.code === 'PB');
		console.log('punjabState found:', punjabState);

		if (punjabState) {
			// Set selected state
			selectedState = punjabState;
			console.log('selectedState set to:', selectedState);
			// Dispatch event with correct format
			handleStateClick(punjabState);
		}
	});
	import { scaleLinear } from 'd3';

	import stateDistribution from './change_patterns_state_distribution.json';

	const stateCounts = Object.fromEntries(stateDistribution.map((d) => [d.State_Name, d.n]));

	const maxCount = Math.max(...stateDistribution.map((d) => d.n));

	const heightScale = scaleLinear().domain([0, maxCount]).range([0, cellSize]); // Scale from 0 to cellSize height

	function getStateHeight(stateCode) {
		const fullStateName = stateNameMapping[stateCode];
		const count = stateCounts[fullStateName] || 0;
		return heightScale(count);
	}

	import { MousePointerClick } from 'lucide-svelte';
</script>

<div class="relative mx-auto ignore-w-100">
	<MousePointerClick class="absolute z-10 stroke-1 stroke-black bottom-0 left-[50%]" size={26} />
	<svg {width} {height} class="mx-auto ignore-w-100">
		{#each stateGrid as state}
			{@const barHeight = getStateHeight(state.code)}

			<g
				transform="translate({(state.col - 1) * (cellSize + padding)}, {(state.row - 1) *
					(cellSize + padding)})"
				on:click={() => handleStateClick(state)}
			>
				<!-- Background rectangle -->
				<rect
					width={cellSize}
					height={cellSize}
					rx="4"
					ry="4"
					class:selected={selectedState?.code === state.code}
					fill="#f0f0f0"
					stroke="white"
					stroke-width="2"
				/>
				<!-- Proportion bar -->
				<rect
					x="0"
					y={cellSize - barHeight}
					width={cellSize}
					height={barHeight}
					fill="var(--color-accent)"
					opacity="0.8"
					rx="2"
					ry="2"
				/>
				<text x={cellSize / 2} y={cellSize / 2} text-anchor="middle" dominant-baseline="middle">
					{state.code}
				</text>

				<!-- Click hint icon -->
			</g>
		{/each}

		<!-- Add state label -->
		{#if selectedState}
			<text
				x={width * 0.66}
				y={height * 0.33}
				class="uppercase black font- font-asap state-label"
				text-anchor="middle"
			>
				{selectedState.name}
			</text>
		{/if}
	</svg>
</div>

<style>
	svg {
		max-width: fit-content;

		height: auto;
	}

	text {
		font-family: 'Asap Variable', sans-serif;
		font-weight: 600;
		font-size: 14px;
		fill: #333;
		pointer-events: none;
	}

	g:hover rect {
		filter: brightness(0.9);
		cursor: pointer;
	}

	rect.selected {
		stroke: #666;
		stroke-width: 2;
		/* remove the fill property */
	}

	.state-label {
		font-size: 14px;
		font-weight: 800;
		fill: #333;
	}

	:global(.click-hint) {
		opacity: 0;
		transition: opacity 0.2s;
		fill: #666;
	}
</style>
