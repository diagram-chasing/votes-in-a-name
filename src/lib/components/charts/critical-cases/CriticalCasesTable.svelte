<script>
	import * as d3 from 'd3';
	import chroma from 'chroma-js';
	import critical_cases from './critical_cases.json';
	import FaceGenerator from '../FaceGenerator.svelte';

	$: sortedData = [...critical_cases].sort((a, b) => a.Original_Margin - b.Original_Margin);

	const ORANGE_COLOR = '#d95f0e';

	$: marginColorScale = d3.scaleLinear().domain([0, 1000]).range(['#fff7bc', ORANGE_COLOR]);

	$: getBackgroundColor = (value) => {
		return marginColorScale ? marginColorScale(value) : '#ffffff';
	};

	$: getTextColor = (backgroundColor) => {
		return chroma(backgroundColor).luminance() > 0.5 ? '#000000' : '#ffffff';
	};

	function toTitleCase(str) {
		return str
			.toLowerCase()
			.split(' ')
			.map((word) => word.charAt(0).toUpperCase() + word.slice(1))
			.join(' ');
	}

	// Add state code mapping (copied from IndiaGrid)
	const stateCodeMapping = {
		Karnataka: 'KA',
		Andhra_Pradesh: 'AP',
		Bihar: 'BR',
		Kerala: 'KL',
		Madhya_Pradesh: 'MP',
		Punjab: 'PB',
		Tamil_Nadu: 'TN',
		Uttar_Pradesh: 'UP',
		West_Bengal: 'WB',
		Uttarakhand: 'UK',
		Assam: 'AS',
		Odisha: 'OR',
		Chhattisgarh: 'CG',
		Jharkhand: 'JH',
		Telangana: 'TL',
		Meghalaya: 'ML',
		Manipur: 'MN',
		Goa: 'GA',
		Arunachal_Pradesh: 'AR',
		Maharashtra: 'MH',
		Gujarat: 'GJ',
		Himachal_Pradesh: 'HP',
		Jammu_Kashmir: 'JK',
		Karnataka: 'KA',
		Kerala: 'KL',
		Madhya_Pradesh: 'MP',
		Chhattisgarh: 'CG',
		Delhi: 'DL',
		Chandigarh: 'CH'
	};

	$: getLocation = (row) => {
		const stateName = row.State_Name.replace(/_/g, ' ');
		const stateCode = stateCodeMapping[row.State_Name] || stateName;
		const constituency = row.Constituency_Name;

		return {
			stateName,
			stateCode,
			constituency
		};
	};

	function convertNameToSeed(name) {
		return name.split('').reduce((acc, char) => acc + char.charCodeAt(0), 0);
	}

	function generateDifferentSeed(originalSeed) {
		return originalSeed;
	}

	$: getSecondSeed = (row) => {
		const firstSeed = convertNameToSeed(row.Ref_Candidate);
		return row.Similarity < 0.24 ? generateDifferentSeed(firstSeed) : firstSeed;
	};

	// Proper Svelte action
	function scrollTableToEnd(node) {
		// Initial scroll
		if (window.innerWidth <= 768) {
			node.scrollLeft = node.scrollWidth;
		}

		return {
			// Optional: Update on resize
			update() {
				if (window.innerWidth <= 768) {
					node.scrollLeft = node.scrollWidth;
				}
			},
			// Optional: Cleanup
			destroy() {}
		};
	}
</script>

<div class="w-full max-w-[48rem] mx-auto my-4 bg-white">
	<div class="border-b border-gray-200">
		<h2 class="py-1.5 text-sm font-bold text-center text-black uppercase font-asap">
			Elections that could have flipped
		</h2>
		<p class="pb-1.5 text-xs text-center text-gray-600">
			Instances with similarly-named candidates and close margins
		</p>
	</div>

	<div class="overflow-x-auto" use:scrollTableToEnd>
		<table class="w-full text-sm border-collapse">
			<thead>
				<tr>
					<th
						class="w-[60px] px-2 py-1.5 font-normal text-left text-gray-800 border-b border-gray-200 bg-zinc-50"
					>
						Year
					</th>
					<th
						class="px-2 py-1.5 font-normal text-left text-gray-800 border-b border-gray-200 bg-zinc-50"
					>
						Election <span class="block text-[10px] text-gray-600">(State/Constituency)</span>
					</th>
					<th
						class="w-1/4 px-2 py-1.5 font-normal text-right text-gray-800 border-b border-gray-200 bg-zinc-50"
					>
						<div class="flex items-center justify-end gap-1">
							<span>Candidate</span>
						</div>
					</th>
					<th
						class="px-2 py-1.5 font-normal text-center text-gray-800 border-b border-gray-200 whitespace-nowrap bg-zinc-50"
					>
						Margin
					</th>
					<th
						class="w-1/4 px-2 py-1.5 font-normal text-left text-gray-800 border-b border-gray-200 bg-zinc-50"
					>
						<div class="flex items-center gap-1">
							<span>Namesake</span>
						</div>
					</th>
					<th
						class="px-2 py-1.5 font-normal text-center text-right text-gray-800 border-b border-gray-200 bg-zinc-50"
					>
						Similarity
					</th>
				</tr>
			</thead>
			<tbody class="text-xs bg-zinc-100">
				{#each sortedData as row}
					<tr>
						<td class="px-2 py-1 border-b border-gray-200">{row.Year}</td>
						<td class="px-2 py-1 border-b border-gray-200">
							<span class="text-[10px] font-medium size-4 bg-gray-200 px-1 rounded-sm">
								{getLocation(row).stateCode}
							</span>
							{toTitleCase(getLocation(row).constituency)}
						</td>
						<td class="px-2 py-1 border-b border-gray-200">
							<div class="flex items-center justify-end gap-1">
								<div class="text-right">
									<div class="font-medium break-words max-w-[150px]">
										{toTitleCase(row.Ref_Candidate)}
									</div>
									<div class="text-[12px] text-gray-800">
										{row.Ref_Votes.toLocaleString()} votes
									</div>
								</div>
								<FaceGenerator
									seed={convertNameToSeed(row.Ref_Candidate)}
									bisim={1}
									dice={1}
									jw={1}
									size={40}
									average={1}
								/>
							</div>
						</td>
						<td
							class="px-2 py-1 text-sm font-medium text-center border-b border-gray-200"
							style="background-color: {getBackgroundColor(
								row.Original_Margin
							)}; color: {getTextColor(getBackgroundColor(row.Original_Margin))}"
						>
							{row.Original_Margin}
						</td>
						<td class="px-2 py-1 border-b border-gray-200">
							<div class="flex items-center gap-1">
								<FaceGenerator
									seed={getSecondSeed(row)}
									bisim={row.Similarity}
									dice={row.Similarity}
									jw={row.Similarity}
									size={40}
									average={row.Similarity}
								/>
								<div class="min-w-0">
									<div class="font-medium break-words max-w-[150px]">
										{toTitleCase(row.Dummy_Candidate)}
									</div>
									<div class="text-[12px] text-gray-800">
										{row.Dummy_Votes.toLocaleString()} votes
									</div>
								</div>
							</div>
						</td>
						<td class="px-2 py-1 text-right border-b border-gray-200"
							>{(row.Similarity * 100).toFixed(1)}%</td
						>
					</tr>
				{/each}
			</tbody>
		</table>
	</div>

	<div class="px-2 py-1.5 text-[10px] text-gray-600">
		Only the state assembly elections are considered <br />¹ Table shows examples where the
		simulation returned a 50% or more probability of the candidate winning
	</div>
</div>

<style>
	table {
		font-family: 'Asap Variable', sans-serif !important;
	}

	.overflow-x-auto {
		-webkit-overflow-scrolling: touch;
		scrollbar-width: thin;
		max-width: 100vw;
	}

	.overflow-x-auto::-webkit-scrollbar {
		height: 6px;
	}

	.overflow-x-auto::-webkit-scrollbar-track {
		background: #f1f1f1;
	}

	.overflow-x-auto::-webkit-scrollbar-thumb {
		background: #888;
		border-radius: 3px;
	}

	.break-words {
		word-wrap: break-word;
		hyphens: auto;
	}
</style>
