<script>
	import * as d3 from 'd3';
	import { smScreen } from 'svelte-ux';
	import dataFile from '$assets/vote_share.json';
	// Props
	export let rawData = dataFile;
	export let width;
	export let height = 200;
	export let marginTop = 23;
	export let marginRight = 20;
	export let marginBottom = 40;
	export let marginLeft = 25;
	export let bins = 4;

	// Process the raw data into histogram bins
	$: data = d3
		.bin()
		.thresholds(bins)(rawData)
		.map((bin) => ({
			bin_start: bin.x0,
			bin_end: bin.x1,
			count: bin.length
		}));

	// Reactive declarations for dimensions
	$: innerWidth = width - marginLeft - marginRight;
	$: innerHeight = height - marginTop - marginBottom;

	// Scales
	$: xScale = d3
		.scaleLinear()
		.domain([0, d3.max(data, (d) => d.bin_end)])
		.range([0, innerWidth]);

	$: yScale = d3
		.scaleLinear()
		.domain([0, d3.max(data, (d) => d.count)])
		.range([innerHeight, 0]);

	$: isMobile = !$smScreen;
</script>

<div class="w-full max-w-[40rem] mx-auto" bind:clientWidth={width}>
	<svg {width} {height}>
		<g transform="translate({marginLeft}, {marginTop})">
			<!-- Bars -->
			{#each data as bar}
				<rect
					x={xScale(bar.bin_start)}
					y={yScale(bar.count)}
					width={xScale(bar.bin_end) - xScale(bar.bin_start)}
					height={innerHeight - yScale(bar.count)}
					fill="var(--color-accent)"
				/>
			{/each}

			<!-- X-axis -->
			<g transform="translate(0, {innerHeight})">
				<!-- <line x1={0} y1={0} x2={innerWidth} y2={0} stroke="black" /> -->
				{#each xScale.ticks(5) as tick}
					<g transform="translate({xScale(tick)}, 0)">
						<line y2={5} stroke="black" />
						<text y={20} text-anchor="middle">{tick === 0 ? 0 : (tick * 100).toFixed(1)}</text>
					</g>
				{/each}
				<text x={innerWidth / 2} y={40} text-anchor="middle" font-size="12px">
					Vote Share (%)
				</text>
			</g>

			<!-- Y-axis -->
			<g>
				<!-- <line x1={0} y1={0} x2={0} y2={innerHeight} stroke="black" /> -->
				{#each yScale.ticks(5) as tick, i}
					<g transform="translate(0, {yScale(tick)})">
						<line x2={-5} stroke="black" />
						<text x={-10} dy="0.32em" text-anchor="end">
							{i === yScale.ticks(5).length - 1 ? `${(tick / 1000).toFixed(0)}K` : tick / 1000}
						</text>
					</g>
				{/each}
				<!-- Y-axis label above the tallest bar -->
				<text
					x={xScale(data[0].bin_end / 2) + (isMobile ? 65 : 0)}
					y={yScale(d3.max(data, (d) => d.count)) + 20}
					text-anchor="middle"
					font-size="12px"
					fill={isMobile ? 'black' : 'white'}
					class="font-bold font-asap"
				>
					<tspan>Namesake</tspan>
					<tspan x={xScale(data[0].bin_end / 2) + (isMobile ? 65 : 0)} dy="1.2em">candidates</tspan>
				</text>
			</g>
		</g>
	</svg>
</div>

<style>
	text {
		font-family: 'Asap Variable', sans-serif;
		font-weight: 400;

		font-size: 13px;
	}
</style>
