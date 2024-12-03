<script>
	export let title = null;
	export let image = '';
</script>

<div class="flex my-4 flex-col items-center max-w-[28rem] mx-auto">
	{#if image}
		<img src={image} alt={title} />
	{/if}
	{#if title}
		<h3>
			{title}
		</h3>
	{/if}
</div>
