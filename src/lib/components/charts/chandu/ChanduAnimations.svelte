<script>
	import { onMount } from 'svelte';
	import ChanduSprites from './chandhu-sprites.png';
	import spritesheetData from './spritesheet.json';
	import { smScreen } from 'svelte-ux';
	import { browser } from '$app/environment';
	let canvas;
	let ctx;
	let isInitialized = false;
	export let step = 4;
	$: CARD_WIDTH = !$smScreen ? 80 : 160;
	$: CARD_HEIGHT = !$smScreen ? 120 : 240;
	const PADDING = 1;

	let spritesheet;

	$: if (browser) {
		spritesheet = new Image();
		spritesheet.src = ChanduSprites;
	}

	let cardOpacities = Array(12).fill(1);
	let cardFlipStates = Array(12).fill(0);
	let animationFrame;
	let startTime = null;
	const FLIP_DURATION = 4000;
	const STAGGER_DELAY = 100;

	let cardPositions = [];
	let shuffleStartTime = null;
	let isShuffling = false;
	const SHUFFLE_DURATION = 1500;
	const SHUFFLE_PAUSE = 300;

	let hasShuffled = false;
	let currentPhase = 'initial';
	let shuffleCount = 0;
	const TOTAL_SHUFFLES = 3;

	let previousStep = 4;
	let animationDirection = 'forward';
	let isTransitioning = false;
	let targetPhase = 'initial';

	const PHASE_MAP = {
		5: 'flipForward',
		6: 'shuffle',
		7: 'flipBack'
	};

	let phaseProgress = {
		fadeIn: 0,
		flipForward: 0,
		shuffle: 0,
		flipBack: 0
	};

	$: {
		if (isInitialized && step !== previousStep) {
			animationDirection = step > previousStep ? 'forward' : 'reverse';
			handleStepChange(step);
			previousStep = step;
		}
	}

	onMount(() => {
		initializeCanvas();
		return () => {
			if (animationFrame) {
				cancelAnimationFrame(animationFrame);
			}
			window.removeEventListener('resize', handleResize);
		};
	});

	async function initializeCanvas() {
		if (!canvas) return;

		ctx = canvas.getContext('2d');
		if (!ctx) return;

		ctx.imageSmoothingEnabled = false;

		// Set initial canvas dimensions
		handleResize();

		// Wait for spritesheet to load
		await new Promise((resolve) => {
			if (spritesheet.complete) {
				resolve();
			} else {
				spritesheet.onload = resolve;
			}
		});

		initializeStates();
		startTime = Date.now();
		isInitialized = true;
		window.addEventListener('resize', handleResize);
		animateCards();
	}

	function handleStepChange(newStep) {
		if (!isInitialized || !ctx) return;

		const newPhase = PHASE_MAP[newStep];
		if (newPhase === currentPhase) return;

		if (isTransitioning) {
			completeCurrentPhase();
		}

		targetPhase = newPhase;
		startTime = Date.now();
		isTransitioning = true;

		if (animationDirection === 'reverse') {
			if (newPhase === 'flipForward') {
				cardFlipStates = Array(12).fill(0);
				shuffleCount = 0;
				hasShuffled = false;
			}
		}

		currentPhase = newPhase;
		if (animationFrame) {
			cancelAnimationFrame(animationFrame);
		}
		animateCards();
	}

	function completeCurrentPhase() {
		switch (currentPhase) {
			case 'flipForward':
				cardFlipStates = Array(12).fill(animationDirection === 'forward' ? 1 : 0);
				break;
			case 'shuffle':
				hasShuffled = animationDirection === 'forward';
				shuffleCount = animationDirection === 'forward' ? TOTAL_SHUFFLES - 1 : 0;
				completeShufflePositions();
				break;
			case 'flipBack':
				cardFlipStates = Array(12).fill(animationDirection === 'forward' ? 0 : 1);
				break;
		}
	}

	function initializeStates() {
		cardOpacities = Array(12).fill(0);
		cardFlipStates = Array(12).fill(0);
		initializeCardPositions();
	}

	function initializeCardPositions() {
		if (!canvas) return;

		const totalCards = 12;
		const cols = 4; // Fixed number of columns for even grid
		const rows = 3; // Fixed number of rows for even grid
		const maxCardWidth = canvas.width / cols;
		const maxCardHeight = canvas.height / rows;
		const scale = Math.min(
			maxCardWidth / (CARD_WIDTH + PADDING),
			maxCardHeight / (CARD_HEIGHT + PADDING)
		);

		// Calculate grid dimensions
		const gridWidth = cols * (CARD_WIDTH + PADDING) * scale;
		const gridHeight = rows * (CARD_HEIGHT + PADDING) * scale;
		// Calculate starting position to center the grid
		const startX = (canvas.width - gridWidth) / 2;
		const startY = (canvas.height - gridHeight) / 2;

		cardPositions = Array(12)
			.fill(null)
			.map((_, i) => {
				const col = i % cols;
				const row = Math.floor(i / cols);
				return {
					x: startX + (i % cols) * (CARD_WIDTH + PADDING) * scale,
					y: startY + Math.floor(i / cols) * (CARD_HEIGHT + PADDING) * scale,
					targetX: startX + col * (CARD_WIDTH + PADDING),
					targetY: startY + row * (CARD_HEIGHT + PADDING),
					index: i,
					scale: 1
				};
			});
	}

	function animateCards() {
		if (!ctx || !canvas || !isInitialized) return;

		function animate() {
			if (!ctx || !canvas) return;

			const currentTime = Date.now();
			const timeElapsed = currentTime - startTime;

			ctx.clearRect(0, 0, canvas.width, canvas.height);
			let isAnimating = true;

			switch (currentPhase) {
				case 'initial':
				case 'fadeIn':
					isAnimating = handleFadeInAnimation();
					break;

				case 'flipForward':
					isAnimating = handleFlipAnimation(timeElapsed, 'forward');
					break;

				case 'shuffle':
					isAnimating = handleShuffleAnimation(currentTime);
					break;

				case 'flipBack':
					isAnimating = handleFlipAnimation(timeElapsed, 'reverse');
					break;
			}

			drawCards();

			if (isAnimating) {
				animationFrame = requestAnimationFrame(animate);
			} else {
				isTransitioning = false;
			}
		}

		animate();
	}

	function handleFadeInAnimation() {
		let stillAnimating = false;
		cardOpacities = cardOpacities.map((opacity) => {
			const newOpacity = Math.min(1, opacity + (animationDirection === 'forward' ? 1 : 1));
			if (newOpacity !== (animationDirection === 'forward' ? 1 : 0)) {
				stillAnimating = true;
			}
			return newOpacity;
		});
		return stillAnimating;
	}

	function handleFlipAnimation(timeElapsed, direction) {
		let stillAnimating = false;
		cardFlipStates = cardFlipStates.map((state, index) => {
			const cardDelay = index * STAGGER_DELAY;
			if (timeElapsed >= cardDelay) {
				const targetState = direction === 'forward' ? 1 : 0;
				const newState =
					direction === 'forward' ? Math.min(1, state + 0.05) : Math.max(0, state - 0.05);
				if (newState !== targetState) {
					stillAnimating = true;
				}
				return newState;
			}
			stillAnimating = true;
			return state;
		});
		return stillAnimating;
	}

	function handleShuffleAnimation(currentTime) {
		if (!isShuffling) {
			isShuffling = true;
			shuffleStartTime = currentTime;
			initializeShufflePositions();
			return true;
		}

		const shuffleTimeElapsed = currentTime - shuffleStartTime;
		if (shuffleTimeElapsed < SHUFFLE_DURATION) {
			updateShufflePositions();
			return true;
		}

		if (shuffleCount < TOTAL_SHUFFLES - 1) {
			shuffleCount++;
			isShuffling = false;
			setTimeout(() => {
				isShuffling = true;
				shuffleStartTime = Date.now();
				initializeShufflePositions();
			}, SHUFFLE_PAUSE);
			return true;
		}

		isShuffling = false;
		hasShuffled = true;
		shuffleCount = 0;
		return false;
	}

	function initializeShufflePositions() {
		if (!canvas) return;

		const totalCards = 12;
		const cols = 4;
		const rows = 3;

		const maxCardWidth = canvas.width / cols;
		const maxCardHeight = canvas.height / rows;
		const scale = Math.min(
			maxCardWidth / (CARD_WIDTH + PADDING),
			maxCardHeight / (CARD_HEIGHT + PADDING)
		);

		const gridWidth = cols * (CARD_WIDTH + PADDING) * scale;
		const gridHeight = rows * (CARD_HEIGHT + PADDING) * scale;
		const startX = (canvas.width - gridWidth) / 2;
		const startY = (canvas.height - gridHeight) / 2;

		const positions = Array(12)
			.fill(null)
			.map((_, i) => ({
				x: startX + (i % cols) * (CARD_WIDTH + PADDING) * scale,
				y: startY + Math.floor(i / cols) * (CARD_HEIGHT + PADDING) * scale
			}));

		// Shuffle positions
		for (let i = positions.length - 1; i > 0; i--) {
			const j = Math.floor(Math.random() * (i + 1));
			[positions[i], positions[j]] = [positions[j], positions[i]];
		}

		cardPositions = cardPositions.map((card, i) => ({
			...card,
			targetX: positions[i].x,
			targetY: positions[i].y,
			scale: scale,
			index: i
		}));
	}

	function completeShufflePositions() {
		cardPositions = cardPositions.map((card) => ({
			...card,
			x: card.targetX,
			y: card.targetY
		}));
	}

	function updateShufflePositions() {
		cardPositions = cardPositions.map((card) => ({
			...card,
			x: card.x + (card.targetX - card.x) * 0.05,
			y: card.y + (card.targetY - card.y) * 0.05
		}));
	}

	function drawCards() {
		if (!ctx || !canvas || !spritesheet) return;

		const cards = [
			{ type: 'chandu', count: 1, sprite: spritesheetData.frames['chandu.png'].frame },
			{ type: 'fake', count: 11, sprite: spritesheetData.frames['fake.png'].frame }
		];

		let cardIndex = 0;

		cards.forEach((card) => {
			for (let i = 0; i < card.count; i++) {
				const flipState = cardFlipStates[cardIndex];
				const opacity = cardOpacities[cardIndex];
				const position = cardPositions[cardIndex];

				if (!position) continue;

				const scaleX = Math.abs(Math.cos(flipState * Math.PI));

				ctx.save();
				ctx.globalAlpha = opacity;

				const xPos = position.x + PADDING / 2;
				const yPos = position.y + PADDING / 2;

				ctx.translate(xPos + CARD_WIDTH / 2, yPos + CARD_HEIGHT / 2);
				ctx.scale(scaleX, 1);
				ctx.translate(-(xPos + CARD_WIDTH / 2), -(yPos + CARD_HEIGHT / 2));

				const sprite = flipState < 0.5 ? card.sprite : spritesheetData.frames['front.png'].frame;

				ctx.drawImage(
					spritesheet,
					sprite.x,
					sprite.y,
					sprite.w,
					sprite.h,
					xPos,
					yPos,
					CARD_WIDTH,
					CARD_HEIGHT
				);

				ctx.restore();
				cardIndex++;
			}
		});
	}

	function handleResize() {
		if (!canvas || !canvas.parentElement) return;

		canvas.width = canvas.parentElement.clientWidth;
		canvas.height = canvas.parentElement.clientHeight;

		if (isInitialized) {
			drawCards();
		}
	}
</script>

<div class="canvas-container">
	<canvas bind:this={canvas}></canvas>
</div>

<style>
	.canvas-container {
		width: 100%;
		height: 100%;
		display: flex;
		align-items: center;
		justify-content: center;
		overflow: hidden;
	}
	canvas {
		background: transparent;
		transform-origin: center center;
		position: absolute;
	}
</style>
