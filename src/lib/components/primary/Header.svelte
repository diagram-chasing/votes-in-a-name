<script>
	import logo from '$assets/logo.png';
	export let title = 'Votes in a name';
	export let subtitle = 'A simple voting app';
	export let authors = ['Aman Bhargava', 'Reechik Bannerjee'];
</script>

<div class="flex flex-col items-center">
	<a href="https://diagramchasing.fun" target="_blank" class="drop-shadow-xl shadow-black w-44"
		><img src={logo} alt="Diagram Chasing" class="mx-auto max-w-44" /></a
	>
	<span class="text-base font-medium text-center text-gray-950 font-asap-italic"> presents</span>
</div>
<header class="p-2 max-w-[40rem] bg-[#ff7d69] rounded-xl container">
	<div class="bg-[#C3362C] text-center rounded-lg p-6 space-y-4 @container">
		<span class="-mb-4 font-hindi hindi-version">✦ नाम तो सुना ही होगा ✦</span>
		<h1 class="text-center header-text">{title}</h1>
		<p class="md:w-1/2 subtitle text-balance">{subtitle}</p>
	</div>
</header>
<p class="mb-4 text-sm text-center text-black font-asap-italic">
	By <a href="https://diagramchasing.fun/authors/aman" target="_blank">Aman Bhargava</a> <br />
	Art by <a href="https://diagramchasing.fun/authors/reechik" target="_blank">Reechik Banerjee</a>
</p>

<style>
	.header-text {
		font-weight: bold;
		color: var(--color-gray-200);
		text-shadow:
			1px 1px 0 var(--color-gray-100),
			4px 4px 0 var(--color-black),
			6px 6px 0 var(--color-black),
			8px 8px 0 var(--color-black);
		letter-spacing: 2px;
		font-size: clamp(3rem, 8vw + 1rem, 8rem);
		line-height: 0.9;
		text-transform: uppercase;
	}

	a {
		text-decoration: underline;
		color: var(--color-gray-950);
	}
	.hindi-version {
		display: block;
		color: var(--color-gray-200);
		font-size: clamp(0.875rem, 1.5cqi, 1.4rem);
		line-height: 1.4;
	}

	.subtitle {
		font-weight: 500;
		font-size: clamp(1rem, 2cqi, 1.4rem);
		font-family: 'Asap Variable', sans-serif;
		color: var(--color-gray-200);
		line-height: 1.4;
		letter-spacing: 0.5px;
	}

	@container (min-width: 640px) {
		.header-text {
			text-shadow:
				4px 4px 0 var(--color-gray-100),
				6px 6px 0 var(--color-black),
				10px 10px 0 var(--color-black),
				12px 12px 0 var(--color-black);
		}
	}
</style>
