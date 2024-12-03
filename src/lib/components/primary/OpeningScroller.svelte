<script>
	import Scroller from '@sveltejs/svelte-scroller';
	import School1 from '$assets/scrolly/school-1.webp';
	import RahulEVM from '$assets/scrolly/rahul-1.webp';
	import ChanduAnimations from '../charts/chandu/ChanduAnimations.svelte';
	import Crowd from '../charts/Crowd.svelte';
	import { smScreen } from 'svelte-ux';
	import outside from '$assets/scrolly/outside-1.webp';
	import cloud1 from '$assets/scrolly/cloud-1.webp';
	import cloud2 from '$assets/scrolly/cloud-2.webp';
	import cloud3 from '$assets/scrolly/cloud-3.webp';
	import { onMount } from 'svelte';
	import { Loader2 } from 'lucide-svelte';
	let index, offset, progress;
	let height;
	let isVisible = false;

	let steps = {
		1: '<center>We begin in Wayanad, Kerala. It is voting day.</center>',
		2: 'You step into the voting booth. The electronic voting machine hums in the converted classroom as the fan whirs overhead. Other voters behind you wait their turn. Your eyes search for the familiar symbol and name amid the rows of text.',
		3: "This is a little weird. There's <span class='ref-candidate'>Rahul Gandhi</span> that you recognize, but below sits another — <span class='dummy-candidate'>Raghul Gandhi</span>, with a different symbol. There's another man with the Gandhi last name right below. And one <span class='dummy-candidate'>Rahul Gandhi KE</span> more. That's an awful lot of Gandhis in one place.",
		4: 'In that election, 2196 voters chose <span class="dummy-candidate">Rahul Gandhi KE</span> – a candidate whose campaign began at the last moment and politcal aspirations ended right after the polls. Whether these votes were because of confusion for the other Rahul Gandhi, or real conviction, is unclear.',
		5: "In 2014, before photos of the candidates were put on EVMs, voters of a constituency in Chhattishgarh were faced between the choice of the BJP candidate <span class='ref-candidate'>Chandu Lal Sahu</span> and <strong>11</strong> other <span class='dummy-candidate'>Chandu Lal Sahu</span>s on the EVM. All spelt almost all the same. Symbols, names, but no photos.",
		6: '<center class="mt-2">There is one real <span class="ref-candidate">Chandu Lal Sahu</span> in here..</center>',
		7: '<center>...did you keep track of the him?</center>',
		8: 'The real <span class="ref-candidate">Chandu</span> still won, but would have gotten at least 30,000 more votes without his duplicates in the running.',
		9: "This doesn't just happen to a single party. Between 1960 to 2024, there are over 8000 candidates who share very similar names with their rivals – close enough to give careful voters pause, and perhaps misdirect the less aware into voting for namesakes who would disappear after election day."
	};

	onMount(() => {
		setTimeout(() => {
			isVisible = true;
		}, 200);
	});
</script>

<svelte:window bind:innerHeight={height} />

<div class="relative scrolly-section">
	{#if !isVisible}
		<div class="absolute transform translate-x-1/2 -translate-y-1/2 top-[4%] z-[100] left-1/2">
			<Loader2 class="w-8 h-8 text-[var(--color-accent)] animate-spin" />
		</div>
	{/if}
	<Scroller top={0.2} bottom={1} bind:index bind:offset bind:progress>
		<div
			slot="background"
			class="relative -mt-32 h-[100dvh] background transition-opacity duration-500"
			class:opacity-0={!isVisible}
			class:opacity-100={isVisible}
		>
			<div class="background-stack">
				<div class="background-layer" style="opacity: {index === 0 ? 1 : 0}">
					<div class="h-[100dvh] relative">
						<img loading="eager" class="background-image" src={outside} alt="Outside" />

						<Crowd
							numberOfPeople={$smScreen ? 250 : 150}
							{height}
							layout="queue"
							trigger={index === 0}
							crowdConfig={{
								rowHeightFactor: 15,
								verticalOffset: $smScreen ? 1 : 0.6,
								jitterY: 110
							}}
						/>
						<img
							loading="eager"
							class="absolute cloud cloud-1 max-w-[190px] top-0 left-0"
							src={cloud1}
							alt="Cloud"
						/>
						<img
							loading="eager"
							class="absolute cloud cloud-2 max-w-[180px] top-0 left-0"
							src={cloud2}
							alt="Cloud"
						/>
						<img
							loading="eager"
							class="absolute cloud cloud-3 max-w-[60px] top-0 left-0"
							src={cloud3}
							alt="Cloud"
						/>
					</div>
				</div>
				<div class="h-full background-layer" style="opacity: {index === 1 ? 1 : 0}">
					<img loading="eager" class="background-image" src={School1} alt="School" />
				</div>

				<div class="background-layer" style="opacity: {index === 2 ? 1 : 0}">
					<img loading="eager" class="background-image" src={RahulEVM} alt="Rahul EVM" />
				</div>

				<div class="background-layer" style="opacity: {index === 3 ? 1 : 0}">
					<div class="h-[100dvh]">
						<Crowd
							numberOfPeople={$smScreen ? 1860 : 1040}
							rows={$smScreen ? 28 : 30}
							{height}
							layout="auto"
							trigger={index === 3}
							crowdConfig={{
								rowHeightFactor: 15,
								verticalOffset: 0.8,
								jitterY: 110
							}}
						/>
					</div>
				</div>

				<div class="background-layer" style="opacity: {index >= 4 ? 1 : 0}">
					<div class="h-[100dvh]">
						<ChanduAnimations step={index} />
					</div>
				</div>
			</div>
		</div>

		<div slot="foreground" class="section-container max-w-52">
			<div class="steps-container">
				{#each Object.keys(steps) as step}
					<section class="step">
						<div class="step-content">
							<p>{@html steps[step]}</p>
						</div>
					</section>
				{/each}
			</div>
		</div>
	</Scroller>
</div>

<style>
	.background-stack {
		position: relative;
		height: 100%;
		width: 100%;
	}

	.background-layer {
		position: absolute;
		top: 0;
		left: 0;
		width: 100%;
		height: 100%;
		transition: opacity 0.5s ease;
	}

	.section-container {
		margin-top: 10em;
		display: flex;
	}

	.steps-container {
		flex: 1 1 100%;
		z-index: 10;
	}

	.step:not(:last-child) {
		min-height: 150vh;
		display: flex;
		place-items: center;
		justify-content: center;
		padding: 2rem 0;
	}

	.step:last-child {
		min-height: 100dvh;
		display: flex;
		place-items: center;
		justify-content: center;
		padding: 2rem 0;
	}

	.step-content {
		background: rgba(255, 255, 255, 0.95);
		padding: 1.5rem;
		border-radius: 8px;
		margin: auto;
		max-width: 650px;
		border: 1px solid rgba(33, 35, 89, 0.8);
		box-shadow:
			rgba(62, 47, 127, 0.12) 0px -10px 0px 0px inset,
			rgba(22, 23, 54, 0.62) 0px 5px 0px 0px;
		background-color: rgb(236, 236, 241);
		position: relative;
	}

	.step-content::after {
		content: '';
		position: absolute;
		height: 100%;
		width: 100%;
		border-radius: inherit;
		left: 0;
		top: 0;
		pointer-events: none;
	}

	.background-image {
		height: 100%;
		width: 100%;
		max-width: none;
		position: absolute;
		left: 50%;
		top: -3%;
		transform: translateX(-50%);
		object-fit: contain;
	}

	@media screen and (min-width: 768px) {
		.step-content {
			position: relative;
			width: 100%;
			margin: 0;
		}
	}

	@media screen and (max-width: 768px) {
		.section-container {
			flex-direction: column;
		}

		.step-content {
			width: 90%;
			margin: auto;
			padding: 1.5rem;
		}

		.step-content p {
			font-size: 1rem;
		}

		.step {
			height: auto;
			min-height: 100dvh;
		}

		p {
			font-size: 1rem;
		}

		.background-image {
			height: 100%;
			width: 190%;
			position: absolute;
			left: 50%;
			transform: translateX(-50%);
			object-fit: contain;
		}
	}

	:global(.svelte-scroller-foreground) {
		pointer-events: none;
	}

	:global(.svelte-scroller-foreground > *) {
		pointer-events: all;
	}

	p {
		line-height: 1.6;
	}

	@keyframes floatCloud {
		from {
			transform: translateX(-100%);
		}
		to {
			transform: translateX(100vw);
		}
	}

	.cloud {
		will-change: transform;
	}

	.cloud-1 {
		animation: floatCloud var(--cloud-1-speed) linear infinite;
		top: var(--cloud-1-top);
	}

	.cloud-2 {
		animation: floatCloud var(--cloud-2-speed) linear infinite;
		top: var(--cloud-2-top);
	}

	.cloud-3 {
		animation: floatCloud var(--cloud-3-speed) linear infinite;
		top: var(--cloud-3-top);
	}

	@media screen and (min-width: 768px) {
		:root {
			--cloud-1-speed: calc(120s);
			--cloud-2-speed: calc(284s);
			--cloud-3-speed: calc(109s);
			--cloud-1-top: -2%;
			--cloud-2-top: -4%;
			--cloud-3-top: -4%;
		}
	}

	@media screen and (max-width: 768px) {
		:root {
			--cloud-1-speed: calc(19000ms);
			--cloud-2-speed: calc(44500ms);
			--cloud-3-speed: calc(29000ms);
			--cloud-1-top: 10%;
			--cloud-2-top: 12%;
			--cloud-3-top: 15%;
		}
	}
</style>
