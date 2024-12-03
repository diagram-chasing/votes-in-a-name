<script lang="ts">
	import { onMount, onDestroy } from 'svelte';
	import { line, curveNatural } from 'd3';

	import person1 from '$assets/crowd/1.webp';
	import person2 from '$assets/crowd/2.webp';
	import person3 from '$assets/crowd/3.webp';
	import person4 from '$assets/crowd/4.webp';
	import person5 from '$assets/crowd/5.webp';
	import person6 from '$assets/crowd/6.webp';
	import person7 from '$assets/crowd/7.webp';
	import person8 from '$assets/crowd/8.webp';
	import person9 from '$assets/crowd/9.webp';
	import person10 from '$assets/crowd/10.webp';
	import person11 from '$assets/crowd/11.webp';

	// Add sprite array
	const SPRITES = [
		person1,
		person2,
		person3,
		person4,
		person5,
		person6,
		person7,
		person8,
		person9,
		person10,
		person11
	];

	export let queuePoints: Array<{ x: number; y: number }> = [{ x: 0, y: 0 }];

	// Update Position type to use HTMLImageElement
	type Position = {
		x: number;
		y: number;
		scale: number;
		index: number;
		startY: number;
		targetY: number;
		groupDelay: number;
		opacity: number;
		sprite?: HTMLImageElement; // Add this
		flip: boolean; // Add this property
	};

	// Animation config
	const ANIMATION_CONFIG = {
		duration: 600,
		staggerDelay: 50,
		groupCount: 10,
		elasticStrength: 0.7,
		startOffsetY: 0, // How far above screen to start
		fadeStartDelay: 0.1 // When to start fading in (0-1)
	};

	// Props with defaults
	export let width = 1000;
	export let height = 600;
	export let numberOfPeople = 100;

	type Layout = 'auto' | 'single' | 'double' | 'full' | 'queue';

	// Add to props
	export let layout: Layout = 'full';

	export let rowSpacing = 80; // Can be configured from outside
	export let baseScale = 1; // Base scale for sprites
	export let scaleVariation = 0.02; // How much scale varies between rows

	export let mobileBreakpoint = 768; // Width at which to switch to mobile layout
	export let mobileScale = 0.5; // Scale multiplier for mobile
	export let spriteSize = undefined; // Optional manual sprite size override
	export let bottomOffset = 0.92;

	// Add new prop for trigger
	export let trigger = true;

	$: !isMobile
		? (queuePoints = [
				{ x: -1.2, y: 1 }, // Start at bottom
				{ x: 0.2, y: 0.99 }, // Snake left
				{ x: 1.3, y: 0.8 }, // Snake right
				{ x: -0.2, y: 0.6 }, // Snake left
				{ x: 0.45, y: 0.55 } // End in middle
			])
		: (queuePoints = [
				{ x: 0.2, y: 0.9 }, // Start at bottom
				{ x: 0.2, y: 0.9 }, // Snake left
				{ x: 0.8, y: 0.9 }, // Snake right
				{ x: 0.2, y: 0.6 }, // Snake left
				{ x: 0.15, y: 0.45 } // End in middle
			]);

	// State
	let canvas: HTMLCanvasElement;
	let ctx: CanvasRenderingContext2D;
	let isMobile = false;
	let currentScale = baseScale;

	let positions: Position[] = [];
	let animationFrame: number;

	let startTime: number | null = null;

	// Debug info
	let debugInfo = {
		canvasWidth: 0,
		canvasHeight: 0,
		atlasLoaded: false,
		positionsGenerated: 0,
		fps: 0,
		lastFrameTime: 0
	};

	// Elastic easing function
	function elasticOut(t: number): number {
		return (
			(Math.sin((-13.0 * (t + 1.0) * Math.PI) / 2) * Math.pow(2.0, -10.0 * t) + 1.0) *
				ANIMATION_CONFIG.elasticStrength +
			(1 - ANIMATION_CONFIG.elasticStrength)
		);
	}

	function interpolatePoints(
		points: Array<{ x: number; y: number }>,
		progress: number
	): { x: number; y: number } {
		// Create line generator with curve interpolation
		const lineGenerator = line<{ x: number; y: number }>()
			.x((d) => d.x)
			.y((d) => d.y)
			.curve(curveNatural); // Adjust alpha for curve tension

		// Generate path string
		const pathString = lineGenerator(points) || '';

		// Get total length for precise interpolation
		const tempPath = document.createElementNS('http://www.w3.org/2000/svg', 'path');
		tempPath.setAttribute('d', pathString);
		const totalLength = tempPath.getTotalLength();
		const point = tempPath.getPointAtLength(progress * totalLength);

		return { x: point.x, y: point.y };
	}

	// Fade easing function
	function easeOutQuart(x: number): number {
		return 1 - Math.pow(1 - x, 4);
	}

	function generatePositions(loadedSprites: HTMLImageElement[]) {
		positions = [];
		const centerX = width / 2;
		const maxWidth = width * (isMobile ? 0.95 : 0.9); // Wider on mobile
		const baseY = height * bottomOffset; // Configurable bottom offset

		// Adjust row calculations for mobile
		let totalRows: number;
		let peoplePerRow: number;

		switch (layout) {
			case 'queue':
				// Calculate how many people should be in queue vs scattered
				const queuePeople = Math.floor(numberOfPeople * 0.95); // 70% in queue
				const scatteredPeople = numberOfPeople - queuePeople;

				// Generate queue positions first
				const absolutePoints = queuePoints.map((p) => ({
					x: p.x * width,
					y: p.y * height
				}));

				const spacing = Math.min(width, height) * 0.04;
				const minDistance = spacing * 0.8; // Minimum distance between sprites
				const minDistanceSquared = minDistance * minDistance; // Square it once for faster comparisons

				// Helper function for fast distance check
				const isTooClose = (newX: number, newY: number) => {
					// Only check against last few positions for performance
					const checkLimit = Math.min(10, positions.length);
					for (let i = Math.max(0, positions.length - checkLimit); i < positions.length; i++) {
						const dx = positions[i].x - newX;
						const dy = positions[i].y - newY;
						// Using squared distance to avoid square root calculation
						if (dx * dx + dy * dy < minDistanceSquared) {
							return true;
						}
					}
					return false;
				};

				// Original queue generation logic with distance check
				for (let i = 0; i < queuePeople; i++) {
					const t = i / (queuePeople - 1);
					const basePos = interpolatePoints(absolutePoints, t);

					// Calculate position with jitter
					const nextT = Math.min(1, t + 0.01);
					const nextPos = interpolatePoints(absolutePoints, nextT);
					const tangentX = nextPos.x - basePos.x;
					const tangentY = nextPos.y - basePos.y;
					const tangentLen = Math.sqrt(tangentX * tangentX + tangentY * tangentY) || 1;

					// Try up to 5 different positions
					let finalX = basePos.x;
					let finalY = basePos.y;
					let attempts = 0;
					const maxAttempts = 5;

					do {
						const jitterRange = spacing * 0.15;
						const perpX = -tangentY / tangentLen;
						const perpY = tangentX / tangentLen;
						const jitter = (Math.random() - 0.5) * jitterRange;

						finalX = basePos.x + perpX * jitter;
						finalY = basePos.y + perpY * jitter;
						attempts++;
					} while (isTooClose(finalX, finalY) && attempts < maxAttempts);

					// Determine flip based on movement direction
					const shouldFlip = tangentX < 0;

					// Perspective scaling
					const perspectiveProgress = 1 - basePos.y / height;
					const perspectiveFactor = 0.7 + 0.3 * (1 - perspectiveProgress);

					// Perpendicular jitter
					const jitterRange = spacing * 0.15 * perspectiveFactor;
					const perpX = -tangentY / tangentLen;
					const perpY = tangentX / tangentLen;
					const jitter = (Math.random() - 0.5) * jitterRange;

					positions.push({
						x: finalX + perpX * jitter,
						y: finalY + perpY * jitter,
						targetY: finalY + perpY * jitter,
						startY: finalY + perpY * jitter - 100 * perspectiveFactor,
						scale: baseScale * perspectiveFactor * (0.95 + Math.random() * 0.1),
						index: Math.floor(Math.random() * loadedSprites.length),
						sprite: loadedSprites[Math.floor(Math.random() * loadedSprites.length)],
						groupDelay: t * ANIMATION_CONFIG.staggerDelay * ANIMATION_CONFIG.groupCount,
						opacity: 0,
						flip: shouldFlip
					});
				}

				// Maximum y-coordinate for scattered people
				const minQueueY = 0.55 * height; // Starting point
				const maxQueueY = height * 0.9; // Bottom limit

				// Add scattered people
				for (let i = 0; i < scatteredPeople; i++) {
					const x = Math.random() * width * 0.8 + width * 0.1;
					const y = Math.random() * (maxQueueY - minQueueY) + minQueueY; // Generate Y between minQueueY and maxQueueY

					const perspectiveProgress = 1 - y / height;
					const perspectiveFactor = 0.7 + 0.3 * (1 - perspectiveProgress);

					positions.push({
						x,
						y,
						targetY: y,
						startY: y - 100 * perspectiveFactor,
						scale: baseScale * perspectiveFactor * (0.95 + Math.random() * 0.1),
						index: Math.floor(Math.random() * loadedSprites.length),
						sprite: loadedSprites[Math.floor(Math.random() * loadedSprites.length)],
						groupDelay: Math.random() * ANIMATION_CONFIG.staggerDelay * ANIMATION_CONFIG.groupCount,
						opacity: 0,
						flip: Math.random() > 0.5
					});
				}

				// Sort by y position for proper rendering
				positions.sort((a, b) => a.y - b.y);

				debugInfo.positionsGenerated = positions.length;
				return;
			case 'single':
				totalRows = 1;
				peoplePerRow = numberOfPeople;
				break;
			case 'double':
				totalRows = 2;
				peoplePerRow = Math.ceil(numberOfPeople / 2);
				break;
			case 'auto':
			case 'full':
			default:
				// Adjust number of rows for mobile
				if (isMobile) {
					totalRows = Math.ceil(Math.sqrt(numberOfPeople / (maxWidth / height)) * 1.5);
					peoplePerRow = Math.ceil((numberOfPeople / totalRows) * 0.8);
				} else {
					totalRows = Math.ceil(Math.sqrt(numberOfPeople / (maxWidth / height)));
					peoplePerRow = Math.ceil(numberOfPeople / totalRows);
				}
				break;
		}

		for (let row = 0; row < totalRows; row++) {
			const invertedRow = totalRows - row - 1;

			// Scale calculation based on row position
			const rowScale = baseScale + invertedRow * scaleVariation;

			// Adjust row width based on layout
			const rowWidthFactor = layout === 'single' ? 0.9 : 0.8 + (invertedRow / totalRows) * 0.2;
			const rowWidth = maxWidth * rowWidthFactor;

			// Calculate Y position
			const rowY = baseY - row * rowSpacing;

			// Adjust people per row based on layout
			const actualPeopleInRow =
				layout === 'single' ? numberOfPeople : Math.floor(peoplePerRow * (1 + invertedRow * 0.1));

			const baseSpacing = rowWidth / actualPeopleInRow;

			for (let i = 0; i < actualPeopleInRow && positions.length < numberOfPeople; i++) {
				const baseX = centerX - rowWidth / 2 + i * baseSpacing;

				// Add clustering effect
				const cluster = Math.random() < 0.3;
				if (cluster && layout !== 'single') {
					// Disable clustering for single row
					const clusterSize = 2 + Math.floor(Math.random());
					for (let j = 0; j < clusterSize && positions.length < numberOfPeople; j++) {
						const clusterOffset = baseSpacing * 10;
						const x = baseX + (Math.random() * clusterOffset * 2 - clusterOffset);
						const y = rowY + (Math.random() * clusterOffset - clusterOffset / 2);

						positions.push({
							x,
							y,
							targetY: y,
							startY: y - 200,
							scale: rowScale * (0.9 + Math.random() * 0.2),
							index: Math.floor(Math.random() * loadedSprites.length),
							sprite: loadedSprites[Math.floor(Math.random() * loadedSprites.length)],
							groupDelay:
								Math.random() * ANIMATION_CONFIG.staggerDelay * ANIMATION_CONFIG.groupCount,
							opacity: 0,
							flip: false
						});
					}
				} else {
					const jitterX = Math.random() * baseSpacing * 0.5 - baseSpacing * 0.25;
					const jitterY = Math.random() * baseSpacing * 0.2 - baseSpacing * 0.1;

					positions.push({
						x: baseX + jitterX,
						y: rowY + jitterY,
						targetY: rowY + jitterY,
						startY: rowY + jitterY - 200,
						scale: rowScale * (0.9 + Math.random() * 0.2),
						index: Math.floor(Math.random() * loadedSprites.length),
						sprite: loadedSprites[Math.floor(Math.random() * loadedSprites.length)],
						groupDelay: Math.random() * ANIMATION_CONFIG.staggerDelay * ANIMATION_CONFIG.groupCount,
						opacity: 0,
						flip: false
					});
				}
			}
		}

		positions.sort((a, b) => a.y - b.y);
		debugInfo.positionsGenerated = positions.length;
	}

	function initCanvas() {
		if (!canvas) return false;

		const dpr = window.devicePixelRatio || 1;
		ctx = canvas.getContext('2d')!;

		canvas.width = width * dpr;
		canvas.height = height * dpr;
		canvas.style.width = `${width}px`;
		canvas.style.height = `${height}px`;

		ctx.scale(dpr, dpr);
		ctx.imageSmoothingEnabled = true;
		ctx.imageSmoothingQuality = 'high';

		// Update responsive state
		isMobile = width <= mobileBreakpoint;
		currentScale = isMobile ? baseScale * mobileScale : baseScale;

		debugInfo.canvasWidth = canvas.width;
		debugInfo.canvasHeight = canvas.height;

		return true;
	}

	function drawFrame(timestamp: number) {
		if (!ctx) return;

		if (!startTime) startTime = timestamp;
		const elapsed = timestamp - startTime;

		// Calculate FPS
		const delta = timestamp - debugInfo.lastFrameTime;
		debugInfo.fps = Math.round(1000 / delta);
		debugInfo.lastFrameTime = timestamp;

		// Clear canvas without setting a background color
		ctx.clearRect(0, 0, canvas.width, canvas.height);

		positions.forEach((pos) => {
			if (!pos.sprite) return;

			const adjustedElapsed = Math.max(0, elapsed - pos.groupDelay);
			const progress = Math.min(1, adjustedElapsed / ANIMATION_CONFIG.duration);

			// Position animation with elastic effect
			const positionProgress = elasticOut(progress);
			pos.y = pos.startY + (pos.targetY - pos.startY) * positionProgress;

			// Fade in animation
			const fadeProgress =
				progress < ANIMATION_CONFIG.fadeStartDelay
					? 0
					: easeOutQuart(
							(progress - ANIMATION_CONFIG.fadeStartDelay) / (1 - ANIMATION_CONFIG.fadeStartDelay)
						);
			pos.opacity = fadeProgress;

			// Scale animation
			const currentScaleAnimation = pos.scale * (0.5 + 0.5 * positionProgress);

			// Use manual sprite size if specified, otherwise use default
			const baseSpriteSize = spriteSize || 190;
			const drawWidth = baseSpriteSize * currentScale * currentScaleAnimation;
			const drawHeight = baseSpriteSize * currentScale * currentScaleAnimation;

			// Draw sprite
			ctx.save();
			ctx.globalAlpha = pos.opacity;

			// Apply flip transformation if needed
			if (pos.flip) {
				ctx.scale(-1, 1);
				ctx.drawImage(
					pos.sprite,
					Math.round(-pos.x - drawWidth / 2), // Negative x position when flipped
					Math.round(pos.y - drawHeight),
					drawWidth,
					drawHeight
				);
			} else {
				ctx.drawImage(
					pos.sprite,
					Math.round(pos.x - drawWidth / 2),
					Math.round(pos.y - drawHeight),
					drawWidth,
					drawHeight
				);
			}

			ctx.restore();
		});

		if (
			elapsed <
			ANIMATION_CONFIG.duration + ANIMATION_CONFIG.staggerDelay * ANIMATION_CONFIG.groupCount
		) {
			animationFrame = requestAnimationFrame(drawFrame);
		}
	}

	async function loadSprites() {
		const loadedSprites = await Promise.all(
			SPRITES.map((src) => {
				return new Promise<HTMLImageElement>((resolve, reject) => {
					const img = new Image();
					img.onload = () => resolve(img);
					img.onerror = reject;
					img.src = src;
				});
			})
		);

		return loadedSprites;
	}

	onMount(async () => {
		try {
			const loadedSprites = await loadSprites();

			if (initCanvas()) {
				generatePositions(loadedSprites);
				if (trigger) {
					startTime = null;
					animationFrame = requestAnimationFrame(drawFrame);
				}
			}
		} catch (error) {
			console.error('Setup failed:', error);
		}
	});

	onDestroy(() => {
		if (animationFrame) {
			cancelAnimationFrame(animationFrame);
		}
	});

	let previousTriggerState = false;

	// Update trigger watcher
	$: if (trigger !== previousTriggerState) {
		previousTriggerState = trigger;
		if (trigger && ctx) {
			// Cancel any existing animation
			if (animationFrame) {
				cancelAnimationFrame(animationFrame);
			}
			// Reset positions to initial state
			if (positions.length > 0) {
				positions.forEach((pos) => {
					pos.y = pos.startY;
					pos.opacity = 0;
				});
			}
			// Start new animation
			startTime = null;
			animationFrame = requestAnimationFrame(drawFrame);
		}
	}
</script>

<div class="crowd-container ignore-w-100" bind:clientWidth={width}>
	<canvas bind:this={canvas} style="background: transparent;" />
</div>

<style>
	.crowd-container {
		position: relative;

		margin: 20px auto;
		width: 100% !important;
		max-width: none !important;
	}

	canvas {
		display: block;
		width: 100%;
		height: 100%;
		max-width: none !important;
	}
</style>
