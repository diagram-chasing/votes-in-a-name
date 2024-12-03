<script lang="ts">
	import { onMount } from 'svelte';
	import { scaleLinear } from 'd3';
	import chroma from 'chroma-js';
	import data from './similarity_by_state.json';
	import { browser } from '$app/environment';
	import { MoveRight, MoveLeft } from 'lucide-svelte';

	let margin;
	let width = 800;

	let states = [...new Set(data.map((d) => d.State_Name))].map(formatStateName);
	let tooltip = {
		visible: false,
		x: 0,
		y: 0,
		data: null as {
			state: string;
			scores: { algorithm: string; score: number }[];
			names: string[];
			parties: string[];
		} | null
	};
	let canvas: HTMLCanvasElement;
	let ctx: CanvasRenderingContext2D;
	let dpr = browser ? window.devicePixelRatio : 1;

	// Track mouse position for hit detection
	let mouseX = 0;
	let mouseY = 0;
	let hoveredLine: any = null;

	// Add visibility state for algorithms
	let visibleAlgorithms = {
		'Bi-gram Similarity': true,
		'Dice Coefficient': true,
		'Jaro-Winkler': true
	};
	// Function to generate color properties
	function generateColorProperties(baseColor) {
		return {
			base: baseColor,
			get dark() {
				return chroma(this.base).darken(1.2).hex();
			},
			get light() {
				return chroma(this.base).brighten(0.5).alpha(0.9).css();
			},
			get text() {
				return chroma(this.base).darken(3).desaturate(1).hex();
			}
		};
	}

	// Colors for different algorithms
	const algorithmColors = {
		'Bi-gram Similarity': generateColorProperties('#809848'),
		'Dice Coefficient': generateColorProperties('#9893DA'),
		'Jaro-Winkler': generateColorProperties('#fdc086')
	};

	function formatStateName(name: string): string {
		return name.replace(/_/g, ' ');
	}

	export let height = 900;

	$: isMobile = width <= 1000 ? true : false;
	$: if (isMobile) {
		margin = { top: 50, right: 0, bottom: 20, left: 0 };
	} else {
		margin = { top: 50, right: 120, bottom: 20, left: 140 };
	}
	$: if (isMobile) {
		height = 900;
	} else {
		height = 600;
	}

	$: xScale = scaleLinear()
		.domain([0.5, 1.0])
		.range([0, width - margin.left - margin.right]);

	$: yScale = scaleLinear()
		.domain([-0.5, states.length - 0.5])
		.range([0, height - margin.top - margin.bottom + (isMobile ? 10 : 0)]);

	$: stateLines = states.map((state, stateIdx) => {
		const stateData = data.filter((d) => formatStateName(d.State_Name) === state);
		return {
			state,
			y: yScale(stateIdx),
			scores: stateData.map((d) => ({
				algorithm: d.algorithm,
				points: d.points.map((point) => ({
					x: xScale(point.score),
					color: algorithmColors[d.algorithm].light,
					score: point.score,
					names: [point.ref, point.dummy],
					parties: [point.refParty, point.dummyParty],
					ids: []
				}))
			}))
		};
	});

	//Function to handle algorithm toggling
	function toggleAlgorithm(algorithm: string) {
		if (
			visibleAlgorithms[algorithm] &&
			Object.values(visibleAlgorithms).filter((v) => v).length === 1
		) {
			// If clicking the only visible algorithm, show all
			visibleAlgorithms = Object.keys(visibleAlgorithms).reduce(
				(acc, key) => ({
					...acc,
					[key]: true
				}),
				{}
			);
		} else {
			// Set all to false, then toggle the clicked one to true
			visibleAlgorithms = Object.keys(visibleAlgorithms).reduce(
				(acc, key) => ({
					...acc,
					[key]: key === algorithm
				}),
				{}
			);
		}
		draw();
	}

	onMount(() => {
		// Force initial render with setTimeout
		setTimeout(() => {
			ctx = canvas.getContext('2d')!;
			canvas.width = width * dpr;
			canvas.height = height * dpr;
			canvas.style.width = `${width}px`;
			canvas.style.height = `${height}px`;
			ctx.scale(dpr, dpr);
			draw();
		}, 0);
	});

	// Add more specific reactive statement
	$: {
		if (width && height && ctx) {
			canvas.width = width * dpr;
			canvas.height = height * dpr;
			canvas.style.width = `${width}px`;
			canvas.style.height = `${height}px`;
			ctx.scale(dpr, dpr);
			draw();
		}
	}

	// Draw function
	function draw() {
		if (!ctx) return;

		ctx.clearRect(0, 0, width, height);
		ctx.save();
		ctx.translate(margin.left, margin.top);

		stateLines.forEach(({ state, scores, y }) => {
			scores.forEach(({ algorithm, points }) => {
				const isAlgorithmVisible = visibleAlgorithms[algorithm];
				if (!isAlgorithmVisible) return; // Skip invisible algorithms

				points.forEach(({ x, color, score }) => {
					ctx.beginPath();
					ctx.moveTo(x, y - 10);
					ctx.lineTo(x, y + 10);

					// Simplified hover check
					const isHovered =
						hoveredPoint.x === x && hoveredPoint.y === y && hoveredPoint.algorithm === algorithm;

					if (isHovered) {
						ctx.lineWidth = isMobile ? 4 : 3;
						ctx.strokeStyle = algorithmColors[algorithm].dark;
						ctx.globalAlpha = 1;
					} else {
						ctx.lineWidth = 1;
						ctx.strokeStyle = color;
						ctx.globalAlpha = 0.9;
					}

					ctx.stroke();
				});
			});
		});

		ctx.restore();
	}

	$: if (width && height) {
		draw();
	}

	// Add this near the top with other state variables
	let hoveredPoint = {
		x: null,
		y: null,
		state: null,
		algorithm: null
	};

	function handleMouseMove(event: MouseEvent) {
		const rect = canvas.getBoundingClientRect();
		mouseX = event.clientX - rect.left;
		mouseY = event.clientY - rect.top;

		const x = mouseX - margin.left;
		const y = mouseY - margin.top;

		let closest = null;
		let minDistance = Infinity;
		let closestPoint = { x: null, y: null, state: null, algorithm: null };

		stateLines.forEach(({ state, scores, y: stateY }) => {
			if (Math.abs(y - stateY) > 15) return; // Skip if too far vertically

			scores.forEach(({ algorithm, points }) => {
				if (!visibleAlgorithms[algorithm]) return;

				points.forEach((point) => {
					const distance = Math.abs(x - point.x);
					if (distance < minDistance && distance < 10) {
						minDistance = distance;
						closest = {
							state,
							scores: scores.map((score) => ({
								algorithm: score.algorithm,
								score:
									score.points.find(
										(p) => p.names[0] === point.names[0] && p.names[1] === point.names[1]
									)?.score || 0
							})),
							names: point.names,
							parties: point.parties,
							x: point.x + margin.left,
							y: stateY + margin.top
						};
						closestPoint = {
							x: point.x,
							y: stateY,
							state,
							algorithm
						};
					}
				});
			});
		});

		if (closest !== hoveredLine) {
			hoveredLine = closest;
			hoveredPoint = closestPoint;
			if (closest) {
				tooltip.visible = true;
				tooltip.data = closest;
				tooltip.x = closest.x;
				tooltip.y = closest.y - margin.top;
			} else {
				tooltip.visible = false;
			}
			draw();
		}
	}

	function handleMouseLeave() {
		hoveredLine = null;
		tooltip.visible = false;
		draw();
	}
</script>

<div class="relative w-full max-w-[60rem] mx-auto barcode-plot" bind:clientWidth={width}>
	<div class="flex max-w-md gap-2 mx-auto mb-4">
		{#each Object.entries(algorithmColors) as [algorithm, colors]}
			<button
				class="px-3 py-1 text-xs font-bold transition-all border rounded md:text-sm font-asap"
				style="border-color: {colors.dark}; 
					   background-color: {visibleAlgorithms[algorithm]
					? chroma(colors.base).darken(1.2).hex()
					: 'transparent'}; 
					   color: {visibleAlgorithms[algorithm] ? 'white' : colors.text};"
				on:click={() => toggleAlgorithm(algorithm)}
			>
				{algorithm === 'Bi-gram Similarity' ? 'BI-SIM' : algorithm}
			</button>
		{/each}
	</div>

	{#if tooltip.visible && tooltip.data}
		<div
			class="absolute z-10 p-3 max-w-[35rem] w-full flex justify-center flex-col bg-[#ffffff] border rounded-lg shadow-lg tooltip"
			style="left: {tooltip.x}px; top: {tooltip.y}px; transform: translate(-50%, 50%);"
		>
			<!-- Header with State -->
			<div class="flex flex-col items-baseline gap-2 mb-2">
				<h3 class="text-lg font-bold text-gray-800">{tooltip.data.state}</h3>
			</div>

			<!-- Names -->
			<div class="space-y-1 text-sm">
				<div class="font-medium text-gray-900">
					{tooltip.data.names[0]} <span class="text-xs">({tooltip.data.parties[0]})</span>
				</div>
				<div class="font-medium text-gray-500">compared to</div>
				<div class="font-medium text-gray-900">
					{tooltip.data.names[1]} <span class="text-xs">({tooltip.data.parties[1]})</span>
				</div>
			</div>

			<!-- All Scores -->
			<div class="flex flex-col gap-2 mt-3">
				{#each tooltip.data.scores as { algorithm, score }}
					<div class="flex items-center justify-between gap-1">
						<span
							class="px-2 py-0.5 text-center text-xs font-medium rounded-sm"
							style="background-color: {algorithmColors[algorithm].dark}; 
								   opacity: {visibleAlgorithms[algorithm] ? '1' : '0.3'}; 
								   color: var(--color-white);"
						>
							{algorithm === 'Bi-gram Similarity'
								? 'BI-SIM'
								: algorithm === 'Dice Coefficient'
									? 'DICE'
									: 'J-W'}
						</span>
						<span
							class="text-lg font-bold transition-all textt-center"
							style="color: {visibleAlgorithms[algorithm] ? 'rgb(17 24 39)' : 'rgb(156 163 175)'}"
						>
							{score.toFixed(3)}
						</span>
					</div>
				{/each}
			</div>
		</div>
	{/if}

	<div class="relative">
		<canvas
			bind:this={canvas}
			width={width || 800}
			{height}
			style="width: {width || 800}px; height: {height}px;"
			on:mousemove={handleMouseMove}
			on:mouseleave={handleMouseLeave}
		/>

		<svg class="absolute top-0 left-0 pointer-events-none" {width} {height}>
			<!-- Y-axis -->
			{#each states as state, i}
				<text
					x={isMobile ? width / 2 : margin.left - 10}
					y={margin.top + yScale(i) + (isMobile ? 25 : 0)}
					text-anchor={isMobile ? 'middle' : 'end'}
					class="text-xs md:text-sm font-asap fill-gray-600"
				>
					{state}
				</text>
			{/each}

			<!-- X-axis -->
			<line
				x1={margin.left}
				x2={width - margin.right}
				y1={margin.top}
				y2={margin.top}
				class="stroke-gray-300"
			/>
			{#each xScale.ticks(6) as tick}
				<text
					x={margin.left + xScale(tick)}
					y={margin.top - 15}
					text-anchor="middle"
					class="text-xs uppercase md:text-sm font-asap fill-gray-600"
				>
					{tick.toFixed(1)}
				</text>
				<line
					x1={margin.left + xScale(tick)}
					x2={margin.left + xScale(tick)}
					y1={margin.top}
					y2={margin.top - 10}
					class="stroke-gray-300"
				/>
			{/each}

			<!-- X-axis label -->
			<g transform={`translate(${margin.left - 30}, ${margin.top - 38})`}>
				<text
					x="20"
					text-anchor="start"
					class="text-xs font-bold uppercase font-asap fill-gray-600"
				>
					🠐 Less Similarity
				</text>
			</g>

			<g transform={`translate(${width - margin.right + 30}, ${margin.top - 38})`}>
				<text x="-20" text-anchor="end" class="text-xs font-bold uppercase font-asap fill-gray-600">
					More Similarity 🠒
				</text>
			</g>
		</svg>
	</div>
</div>

<style>
	.barcode-plot {
		font-family: -apple-system, system-ui, sans-serif;
	}

	.tooltip {
		min-width: 200px;
		max-width: 280px;
		border-color: rgba(0, 0, 0, 0.1);
		transition: opacity 0.2s ease-in-out; /* Smooth transition for tooltip */
	}

	/* Add styles for the axes */
	:global(.tick text) {
		font-size: 12px;
		fill: #333;
	}

	:global(.tick line) {
		stroke: #ddd;
	}

	:global(.domain) {
		stroke: #ddd;
	}
	g {
		width: fit-content;
	}

	@media (max-width: 768px) {
		.tooltip {
			min-width: 160px;
			max-width: 200px;
		}
	}
</style>
