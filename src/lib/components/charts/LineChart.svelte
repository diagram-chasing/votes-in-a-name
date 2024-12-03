<script>
	import { Chart, Svg, Axis, Spline, Highlight, Tooltip } from 'layerchart';
	import { scaleTime } from 'd3';
	import { format } from 'date-fns';
	import { formatDate, PeriodType } from '@layerstack/utils';

	const dateSeriesData = Array.from({ length: 100 }, (_, index) => {
		const date = new Date('2022-01-01');
		date.setDate(date.getDate() + index);
		return {
			date,
			value: Math.floor(Math.random() * 1000) + 1
		};
	});
</script>

<div class="h-[300px] w-full p-4 border rounded">
	<Chart
		data={dateSeriesData}
		x="date"
		xScale={scaleTime()}
		y="value"
		yDomain={[0, null]}
		yNice
		padding={{ left: 16, bottom: 24 }}
		tooltip={{ mode: 'bisect-x' }}
	>
		<Tooltip.Root
			classes={{
				root: 'z-[100] bg-white'
			}}
			let:data
		>
			<Tooltip.Header>{format(data.date, 'eee, MMMM do')}</Tooltip.Header>
			<Tooltip.List>
				<Tooltip.Item label="value" value={data.value} />
			</Tooltip.List>
		</Tooltip.Root>
		<Svg>
			<Axis placement="left" grid rule />
			<Axis
				placement="bottom"
				format={(d) => formatDate(d, PeriodType.Day, { variant: 'short' })}
				rule
			/>
			<Spline class="stroke-2 stroke-primary fill-none" />
			<Highlight points lines />
		</Svg>
	</Chart>
</div>
