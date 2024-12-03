<script>
	import { onMount } from 'svelte';
	import * as d3 from 'd3';
	import data from './namesake_by_party_data.json';

	let width = 800;
	let height = 400;
	const margin = { top: 10, right: 40, bottom: 50, left: 60 };

	const innerWidth = width - margin.left - margin.right;
	const innerHeight = height - margin.top - margin.bottom;

	// Compute scales
	$: xScale = d3
		.scaleLinear()
		.domain([0, d3.max(data, (d) => d.count)])
		.range([0, innerWidth])
		.nice();

	$: yScale = d3
		.scaleLinear()
		.domain([0, d3.max(data, (d) => d.voteShare)])
		.range([innerHeight, 0])
		.nice();

	// Updated color scale to match the reference image
	$: colorScale = d3
		.scaleOrdinal()
		.domain(['default', 'highlighted', 'orange'])
		.range(['#4a4a4a', '#ff6b6b', '#fd7e14']);

	function getPartyColor(party) {
		if (['BJP', 'BSP', 'JD'].includes(party)) return 'orange';
		if (['INC(I)', 'LKD', 'SSP', 'ADM', 'ADS'].includes(party)) return 'default';
		return 'highlighted';
	}

	function getPartySize(party) {
		if (party === 'IND') return 12;
		if (['INC', 'BJP'].includes(party)) return 10;
		return 8;
	}
</script>

<div class="chart-container">
	<svg {width} {height}>
		<g transform="translate({margin.left}, {margin.top})">
			<!-- Grid lines -->
			{#each yScale.ticks() as tick, i}
				{#if i % 2 === 0}
					<line
						x1={0}
						x2={innerWidth}
						y1={yScale(tick)}
						y2={yScale(tick)}
						stroke="#e9ecef"
						stroke-width="1"
					/>
				{/if}
			{/each}

			<!-- {#each xScale.ticks() as tick}
				<line
					x1={xScale(tick)}
					x2={xScale(tick)}
					y1={0}
					y2={innerHeight}
					stroke="#e9ecef"
					stroke-width="1"
				/>
			{/each} -->

			<!-- Lines from origin to points -->
			{#each data as d}
				<line
					x1={0}
					y1={yScale(0)}
					x2={xScale(d.count)}
					y2={yScale(d.voteShare)}
					stroke={colorScale(getPartyColor(d.party))}
					stroke-width="2"
					opacity="0.8"
				/>
			{/each}

			<!-- Data points and labels -->
			{#each data as d}
				<g transform="translate({xScale(d.count)}, {yScale(d.voteShare)})">
					<circle r={getPartySize(d.party)} fill={colorScale(getPartyColor(d.party))} />
					<text
						x={10}
						y={0}
						dy=".32em"
						fill="#333"
						font-weight={d.party === 'IND' ? 'bold' : 'normal'}>{d.party}</text
					>
				</g>
			{/each}

			<!-- X Axis -->
			<g transform="translate(0, {innerHeight})">
				<line x1={0} x2={innerWidth} y1={0} y2={0} stroke="#333" />
				{#each xScale.ticks() as tick}
					<g transform="translate({xScale(tick)}, 0)">
						<line y2={6} stroke="#333" />
						<text y={20} text-anchor="middle">{tick}</text>
					</g>
				{/each}
				<text x={innerWidth / 2} y={40} text-anchor="middle">Number of Namesake Candidates</text>
			</g>

			<!-- Y Axis -->
			<g>
				<line y2={innerHeight} stroke="#333" />
				{#each yScale.ticks() as tick, i}
					{#if i % 2 === 0}
						<g transform="translate(0, {yScale(tick)})">
							<line x2={-6} stroke="#333" />
							<text x={-10} dy=".32em" text-anchor="end">{d3.format('.0%')(tick)}</text>
						</g>
					{/if}
				{/each}
				<text transform="rotate(-90)" x={-innerHeight / 2} y={-40} text-anchor="middle"
					>Average Vote Share per Namesake</text
				>
			</g>
		</g>
	</svg>
</div>

<style>
	.chart-container {
		font-family: -apple-system, system-ui, BlinkMacSystemFont, 'Segoe UI', Roboto, 'Helvetica Neue',
			Arial, sans-serif;
		margin: 2rem auto;
		max-width: 900px;
	}

	text {
		font-size: 12px;
	}
</style>
