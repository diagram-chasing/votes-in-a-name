<script lang="ts">
	import zoteroData from '$assets/bibliography.json';
	interface Reference {
		id: string;
		authors: string[];
		year: number;
		title: string;
		publication?: string;
		url?: string;
		doi?: string;
	}
	interface ZoteroCSL {
		id: string;
		author?: Array<{ family: string; given: string }>;
		issued?: { 'date-parts': number[][] };
		title?: string;
		'container-title'?: string;
		DOI?: string;
		URL?: string;
		publisher?: string;
	}

	export function transformZoteroToReferences(zoteroJson: ZoteroCSL[]): Reference[] {
		return zoteroJson.map((entry) => {
			// Create a unique ID (use the entry's id if available)
			const id =
				entry.id ||
				(() => {
					const year = entry.issued?.['date-parts']?.[0]?.[0] || 0;
					const firstAuthor = entry.author?.[0]?.family?.toLowerCase() || 'unknown';
					return `${firstAuthor}${year}`;
				})();

			// Transform authors from Zotero format to simple strings
			const authors = entry.author?.map((a) => `${a.given} ${a.family}`) || [];
			const year = entry.issued?.['date-parts']?.[0]?.[0] || 0;

			return {
				id,
				authors,
				year,
				title: entry.title || '',
				publication: entry['container-title'] || entry.publisher || '',
				doi: entry.DOI,
				url: entry.URL
			};
		});
	}

	export let references: Reference[] = [];

	// Format authors according to citation style
	function formatAuthors(authors: string[]): string {
		if (authors.length === 0) return '';
		if (authors.length === 1) return authors[0];
		if (authors.length === 2) return `${authors[0]} and ${authors[1]}`;
		return `${authors[0]} et al.`;
	}

	// Sort references by author and year
	$: sortedReferences = [...references].sort((a, b) => {
		const authorA = a.authors[0]?.split(' ').pop() || '';
		const authorB = b.authors[0]?.split(' ').pop() || '';
		if (authorA !== authorB) return authorA.localeCompare(authorB);
		return a.year - b.year;
	});

	$: references = transformZoteroToReferences(zoteroData);
</script>

<div class="pt-6 border-t border-gray-200 bibliography">
	<h2 class="text-2xl font-bold text-color-accent font-asap">References</h2>
	<div class="space-y-4">
		{#each sortedReferences as ref}
			<div class="reference-item" id={ref.id}>
				<p class="text-sm text-gray-800">
					<span class="font-medium">{formatAuthors(ref.authors)}</span>
					<span class="ml-1">({ref.year})</span>
					<span class="ml-1">{ref.title}.</span>
					{#if ref.publication}
						<span class="italic">{ref.publication}</span>.
					{/if}
					{#if ref.doi}
						<a
							href="https://doi.org/{ref.doi}"
							target="_blank"
							rel="noopener noreferrer"
							class="ml-1 text-gray-600 transition-colors hover:text-gray-900"
						>
							doi:{ref.doi}
						</a>
					{/if}
					{#if ref.url && !ref.doi}
						<a
							href={ref.url}
							target="_blank"
							rel="noopener noreferrer"
							class="ml-1 text-gray-600 transition-colors hover:text-gray-900"
						>
							[link]
						</a>
					{/if}
				</p>
			</div>
		{/each}
	</div>
</div>

<style>
	.bibliography {
		width: 100%;
		max-width: 40rem;
		margin: 0rem auto;
	}

	.reference-item {
		border-radius: 0.25rem;
		transition: background-color 0.2s;
	}

	.reference-item:target {
		background-color: var(--color-gray-100);
	}

	:global(.reference-item a) {
		text-decoration: none;
	}

	:global(.reference-item a:hover) {
		text-decoration: underline;
	}

	@media (max-width: 768px) {
		.bibliography {
			padding: 1.2rem 0rem;
		}
	}
</style>
