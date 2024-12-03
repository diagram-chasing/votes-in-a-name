<script>
	import { Chart, Circle, Text, ForceSimulation, Svg, Pattern } from 'layerchart';
	import { scaleBand, scaleOrdinal } from 'd3';
	import { forceX, forceManyBody, forceCollide, forceCenter } from 'd3';
	import party1 from '$assets/parties/party-1.png';
	import party2 from '$assets/parties/party-2.png';
	import party3 from '$assets/parties/party-3.png';
	import party4 from '$assets/parties/party-4.png';
	import party5 from '$assets/parties/party-5.png';
	function generatePoolData(poolASize = 5, poolBSize = 12, minValue = 6, maxValue = 12) {
		const generateDots = (category, count) => {
			return Array.from({ length: count }, () => ({
				category,
				value:
					category === 'A'
						? 12 + minValue
						: Math.floor(Math.random() * (maxValue - minValue + 1)) + minValue
			}));
		};

		return [...generateDots('A', poolASize), ...generateDots('B', poolBSize)];
	}

	const categoryColor = (category) => {
		const colors = {
			A: '#ff6b6b',
			B: '#4ecdc4'
		};
		return colors[category] || '#999';
	};

	export let group = false;

	let alpha = 1;
	$: reheatSimulation({ group });
	const xForce = forceX().strength(0.1);
	const chargeForce = forceManyBody().strength(13);
	const collideForce = forceCollide();
	const centerForce = forceCenter();

	function reheatSimulation(args) {
		const _ = args;
		alpha = 0.5;
	}
</script>

<div class="h-[350px] mx-auto w-full max-w-[44rem]">
	<Chart
		data={generatePoolData()}
		x="category"
		xScale={scaleBand()}
		r="value"
		rRange={[10, 22]}
		let:xGet
		let:xScale
		let:rGet
		let:width
		let:height
	>
		{@const nodeStrokeWidth = 1}
		<Svg>
			<Pattern id="line-pattern-1" width={2} height={2}>
				<line x2="100%" class="stroke-[var(--color-accent)]" />
			</Pattern>
			<Text
				x={xScale('A') + xScale.bandwidth() / 2.5}
				y={height - 40}
				value="National or state party candidates"
				class="text-sm font-medium text-center fill-current font-asap"
				textAnchor="middle"
				lineHeight="1.2em"
				width={150}
			/>
			<Text
				x={xScale('B') + xScale.bandwidth() / 2.5}
				y={height - 20}
				value="Independent, candidates with <5% vote share or first time running "
				class="text-sm font-medium text-center fill-current font-asap"
				textAnchor="middle"
				lineHeight="1.2em"
				width={210}
			/>
			<ForceSimulation
				forces={{
					x: xForce.x((d) => (group ? xGet(d) + xScale.bandwidth() / 2 : width / 2)),
					charge: chargeForce,
					collide: collideForce.radius((d) => rGet(d) + nodeStrokeWidth / 2),
					center: centerForce.x(width / 1.8).y(height / 3)
				}}
				cloneData
				bind:alpha
				let:nodes
			>
				{#each nodes as node}
					<Circle
						cx={node.x}
						cy={node.y}
						r={rGet(node)}
						fill={node.category === 'A' ? 'var(--color-accent)' : 'url(#line-pattern-1)'}
						class="stroke-surface-100"
					/>
				{/each}
			</ForceSimulation>
		</Svg>
	</Chart>
</div>
