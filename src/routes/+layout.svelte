<script>
	import '../lib/styles/app.css';
	import logo from '$assets/logo.png';
	import Crowd from '../lib/components/charts/Crowd.svelte';
</script>

<div class="relative pb-10 mx-auto overflow-x-hidden app">
	<main class="mx-auto space-y-4">
		<slot />
		<span class="text-base font-medium text-center text-gray-950 font-asap-italic">
			Read more at</span
		>

		<a href="https://diagramchasing.fun" target="_blank" class="drop-shadow-xl shadow-black w-44"
			><img src={logo} alt="Diagram Chasing" class="mx-auto my-2 max-w-44" /></a
		>
		<div class="w-full">
			<Crowd
				height={200}
				layout="single"
				mobileScale={1}
				bottomOffset={1}
				rowSpacing={0.5}
				numberOfPeople={200}
			/>
		</div>
	</main>
</div>

<style>
	.app {
		display: flex;
		flex-direction: column;
		min-height: 100vh;
		width: 100%;
	}

	main {
		flex: 1;
		display: flex;
		flex-direction: column;

		width: 100%;
		margin: 0 auto;
		box-sizing: border-box;
	}
</style>
