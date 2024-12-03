<script>
	import * as d3 from 'd3';
	function scrollTableToEnd(node) {
		// Initial scroll
		if (window.innerWidth <= 768) {
			node.scrollLeft = node.scrollWidth;
		}

		return {
			update() {
				if (window.innerWidth <= 768) {
					node.scrollLeft = node.scrollWidth;
				}
			}
		};
	}
	const data = [
		{
			state: 'Assam',
			referenceName: 'PRODIP HAZARIKA',
			similarName: 'Pradip Hazarika',
			jw: 81.3,
			biSim: 86.7,
			dice: 85.7
		},
		{
			state: 'Bihar',
			referenceName: 'DEVANDRA PRASAD YADAV',
			similarName: 'DEVENDRA PRASAD YADAV',
			jw: 83.5,
			biSim: 90.5,
			dice: 80.0
		},
		{
			state: 'Gujarat',
			referenceName: 'RAJESHBHAI CHIMANBHAI VASAVA',
			similarName: 'RAMANBHAI CHIMANBHAI VASAVA',
			jw: 77.0,
			biSim: 82.1,
			dice: 64.2
		},
		{
			state: 'Madhya Pradesh',
			referenceName: 'MAHENDRA SINGH BHADORIYA',
			similarName: 'DEVENDRA SINGH BHADORIYA',
			jw: 75.0,
			biSim: 81.2,
			dice: 87.0
		},
		{
			state: 'Tamil Nadu',
			referenceName: 'NAGESWARI THIRUMATHI.N.',
			similarName: 'MAHESWARI THIRUMATHI .A.',
			jw: 76.9,
			biSim: 84.1,
			dice: 66.7
		},
		{
			state: 'Uttar Pradesh',
			referenceName: 'DR. NARENDRA KUMAR SINGH GAUR',
			similarName: 'NARENDRA KUMAR SINGH YADAVA',
			jw: 70.8,
			biSim: 78.6,
			dice: 71.7
		}
	];

	const PURPLE_COLOR = '#d95f0e';

	$: colorScale = d3.scaleLinear().domain([64, 100]).range(['#fff7bc', PURPLE_COLOR]);

	$: getBackgroundColor = (value) => {
		return colorScale ? colorScale(value) : '#ffffff';
	};

	function toTitleCase(str) {
		return str
			.toLowerCase()
			.split(' ')
			.map((word) => word.charAt(0).toUpperCase() + word.slice(1))
			.join(' ');
	}
</script>

<div class="w-full my-6 max-w-[56rem] mx-auto bg-white">
	<div class="border-b border-gray-200">
		<h2
			class="py-1.5 sm:py-2 text-sm sm:text-base font-bold text-center text-black uppercase font-asap"
		>
			Differences in scoring
		</h2>
	</div>

	<div class="overflow-x-auto" use:scrollTableToEnd>
		<table class="w-full border-collapse">
			<thead>
				<tr>
					<th
						class="w-12 px-2 sm:px-3 py-1.5 sm:py-2 text-sm font-normal text-left text-gray-800 border-b border-gray-200 bg-zinc-50"
						>State</th
					>
					<th
						class="px-2 sm:px-3 py-1.5 sm:py-2 text-sm font-normal text-left text-gray-800 border-b border-gray-200 bg-zinc-50"
						>Reference Name</th
					>
					<th
						class="px-2 sm:px-3 py-1.5 sm:py-2 text-sm font-normal text-left text-gray-800 border-b border-gray-200 bg-zinc-50"
						>Similar Name</th
					>
					<th
						class="w-16 sm:w-20 px-2 sm:px-3 py-1.5 sm:py-2 text-sm font-normal text-center text-gray-800 border-b border-gray-200 bg-zinc-50"
						>JW¹</th
					>
					<th
						class="w-16 sm:w-20 px-2 sm:px-3 py-1.5 sm:py-2 text-sm font-normal text-center text-gray-800 border-b border-gray-200 whitespace-nowrap bg-zinc-50"
						>BI-SIM¹</th
					>
					<th
						class="w-16 sm:w-20 px-2 sm:px-3 py-1.5 sm:py-2 text-sm font-normal text-center text-gray-800 border-b border-gray-200 bg-zinc-50"
						>Dice¹</th
					>
				</tr>
			</thead>
			<tbody class="bg-zinc-100">
				{#each data as row}
					<tr>
						<td
							class="py-1 sm:py-1.5 px-2 sm:px-3 text-sm border-b border-gray-200 whitespace-nowrap"
							>{row.state}</td
						>
						<td
							class="py-1 sm:py-1.5 px-2 sm:px-3 text-sm border-b border-gray-200 whitespace-nowrap"
							>{toTitleCase(row.referenceName)}</td
						>
						<td
							class="py-1 sm:py-1.5 px-2 sm:px-3 text-sm border-b border-gray-200 whitespace-nowrap"
							>{toTitleCase(row.similarName)}</td
						>
						<td
							class="py-1 sm:py-1.5 px-2 sm:px-3 border-b border-gray-200 text-center text-xs sm:text-sm"
							style="background-color: {getBackgroundColor(row.jw)}"
						>
							{row.jw.toFixed(1)}%
						</td>
						<td
							class="py-1 sm:py-1.5 px-2 sm:px-3 border-b border-gray-200 text-center text-xs sm:text-sm"
							style="background-color: {getBackgroundColor(row.biSim)}"
						>
							{row.biSim}%
						</td>
						<td
							class="py-1 sm:py-1.5 px-2 sm:px-3 border-b border-gray-200 text-center text-xs sm:text-sm"
							style="background-color: {getBackgroundColor(row.dice)}"
						>
							{row.dice}%
						</td>
					</tr>
				{/each}
			</tbody>
		</table>
	</div>

	<div class="px-2 sm:px-3 py-1.5 sm:py-2 text-[10px] sm:text-xs text-gray-600">
		¹ JW = Jaro-Winkler, BI-SIM = BI-SIM (Kondrak, 2003), Dice = Dice Coefficient
	</div>
</div>
