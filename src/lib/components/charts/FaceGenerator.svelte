<script lang="ts">
	import BackHairSprites from '$assets/face-gen/back-hair.png';
	import FaceShapeSprites from '$assets/face-gen/face-shape.png';
	import FaceSprites from '$assets/face-gen/face.png';
	import FrontHairSprites from '$assets/face-gen/front-hair.png';
	import MinorSprites from '$assets/face-gen/minor.png';
	import MajorSprites from '$assets/face-gen/major.png';
	import seedrandom from 'seedrandom';

	export let seed = 10;
	export let bisim = 0;
	export let dice = 0;
	export let jw = 0;
	export let size = 70;
	export let average = 0;
	let canvas: HTMLCanvasElement;

	// Weights for each feature (total = 1)
	const WEIGHTS = {
		faceShape: 0.7,
		backHair: 0.15,
		frontHair: 0.05,
		face: 0.0,
		minor: 0.1,
		major: 0.0
	};

	const SPRITE_COUNTS = {
		backHair: 4,
		faceShape: 3,
		frontHair: 3,
		face: 3,
		minor: 1,
		major: 1
	};

	const SPRITE_SIZE = 1080; // Original sprite size
	const SPRITE_PADDING = 5;
	$: CANVAS_SIZE = size; // Desired output size

	// Add weights for different similarity metrics (total = 1)
	const SIMILARITY_WEIGHTS = {
		bisim: 0.7,
		dice: 0.25,
		jw: 0.05
	};

	function getFeatureIndex(
		baseSeed: number,
		weight: number,
		metrics: { bisim: number; dice: number; jw: number }
	): number {
		// Calculate weighted similarity
		const weightedSim =
			metrics.bisim * SIMILARITY_WEIGHTS.bisim +
			metrics.dice * SIMILARITY_WEIGHTS.dice +
			metrics.jw * SIMILARITY_WEIGHTS.jw;

		// When average similarity is very low (below 30%), force maximum difference
		if (average < 0.35 || weightedSim < 0.35) {
			const rng = seedrandom(`${baseSeed}-${weight}`);
			let spriteCount;
			if (weight === WEIGHTS.backHair) spriteCount = SPRITE_COUNTS.backHair;
			else if (weight === WEIGHTS.faceShape) spriteCount = SPRITE_COUNTS.faceShape;
			else if (weight === WEIGHTS.frontHair) spriteCount = SPRITE_COUNTS.frontHair;
			else if (weight === WEIGHTS.minor) spriteCount = SPRITE_COUNTS.minor;
			else spriteCount = SPRITE_COUNTS.face;

			// Force maximum offset by using half of the available sprites
			const offset = Math.floor(spriteCount / 2);
			return (baseSeed + offset) % spriteCount;
		}

		// Original logic for higher similarities
		const adjustedSim = Math.pow(weightedSim, 2);
		const maxDistance =
			adjustedSim < 0.1
				? Math.max(
						SPRITE_COUNTS.backHair,
						SPRITE_COUNTS.faceShape,
						SPRITE_COUNTS.frontHair,
						SPRITE_COUNTS.face
					)
				: adjustedSim > 0.7
					? Math.floor(2 * (1 - adjustedSim))
					: Math.floor(1 / adjustedSim);

		const rng = seedrandom(`${baseSeed}-${weight}`);
		const distance = Math.floor(rng() * maxDistance);

		let spriteCount;
		if (weight === WEIGHTS.backHair) spriteCount = SPRITE_COUNTS.backHair;
		else if (weight === WEIGHTS.faceShape) spriteCount = SPRITE_COUNTS.faceShape;
		else if (weight === WEIGHTS.frontHair) spriteCount = SPRITE_COUNTS.frontHair;
		else if (weight === WEIGHTS.minor) spriteCount = SPRITE_COUNTS.minor;
		else spriteCount = SPRITE_COUNTS.face;

		return (baseSeed + distance) % spriteCount;
	}

	function initCanvas() {
		const ctx = canvas.getContext('2d', {
			alpha: true,
			imageSmoothingEnabled: true,
			imageSmoothingQuality: 'high'
		});

		if (!ctx) return;

		// Set canvas size with device pixel ratio for HD rendering
		const dpr = window.devicePixelRatio || 1;
		canvas.width = CANVAS_SIZE * dpr;
		canvas.height = CANVAS_SIZE * dpr;

		// Scale canvas CSS size for proper display
		canvas.style.width = `${CANVAS_SIZE}px`;
		canvas.style.height = `${CANVAS_SIZE}px`;

		// Scale context to account for pixel ratio
		ctx.scale(dpr, dpr);

		// Enable image smoothing for better quality
		ctx.imageSmoothingEnabled = true;
		ctx.imageSmoothingQuality = 'high';

		// Replace normalizedSim with metrics object
		const metrics = { bisim, dice, jw };

		ctx.clearRect(0, 0, canvas.width, canvas.height);

		Promise.all([
			loadImage(FaceShapeSprites),
			loadImage(BackHairSprites),
			loadImage(FrontHairSprites),
			loadImage(FaceSprites),
			loadImage(MinorSprites),
			loadImage(MajorSprites)
		]).then(([faceShapeImg, backHairImg, frontHairImg, faceImg, minorImg, majorImg]) => {
			// Create temporary canvas for each sprite to handle scaling
			const tempCanvas = document.createElement('canvas');
			const tempCtx = tempCanvas.getContext('2d', {
				alpha: true,
				imageSmoothingEnabled: true,
				imageSmoothingQuality: 'high'
			});

			tempCanvas.width = SPRITE_SIZE;
			tempCanvas.height = SPRITE_SIZE;

			if (tempCtx) {
				// Draw features in order (back to front)
				drawFeatureHD(
					ctx,
					tempCtx,
					tempCanvas,
					backHairImg,
					getFeatureIndex(seed, WEIGHTS.backHair, metrics)
				);
				drawFeatureHD(
					ctx,
					tempCtx,
					tempCanvas,
					faceShapeImg,
					getFeatureIndex(seed, WEIGHTS.faceShape, metrics)
				);
				drawFeatureHD(
					ctx,
					tempCtx,
					tempCanvas,
					majorImg,
					getFeatureIndex(seed, WEIGHTS.major, metrics)
				);
				drawFeatureHD(
					ctx,
					tempCtx,
					tempCanvas,
					frontHairImg,
					getFeatureIndex(seed, WEIGHTS.frontHair, metrics)
				);
				drawFeatureHD(
					ctx,
					tempCtx,
					tempCanvas,
					faceImg,
					getFeatureIndex(seed, WEIGHTS.face, metrics)
				);
				drawFeatureHD(
					ctx,
					tempCtx,
					tempCanvas,
					minorImg,
					getFeatureIndex(seed, WEIGHTS.minor, metrics)
				);
			}
		});
	}

	function loadImage(src: string): Promise<HTMLImageElement> {
		return new Promise((resolve) => {
			const img = new Image();
			img.src = src;
			img.onload = () => resolve(img);
		});
	}

	function drawFeatureHD(
		ctx: CanvasRenderingContext2D,
		tempCtx: CanvasRenderingContext2D,
		tempCanvas: HTMLCanvasElement,
		img: HTMLImageElement,
		index: number
	) {
		// Clear temporary canvas
		tempCtx.clearRect(0, 0, SPRITE_SIZE, SPRITE_SIZE);

		// Draw full-size sprite to temp canvas first
		tempCtx.drawImage(
			img,
			index * (SPRITE_SIZE + SPRITE_PADDING * 2) + SPRITE_PADDING,
			SPRITE_PADDING,
			SPRITE_SIZE,
			SPRITE_SIZE,
			0,
			0,
			SPRITE_SIZE,
			SPRITE_SIZE
		);

		// Draw scaled version to main canvas
		ctx.drawImage(tempCanvas, 0, 0, SPRITE_SIZE, SPRITE_SIZE, 0, 0, CANVAS_SIZE, CANVAS_SIZE);
	}

	$: if (bisim !== undefined || dice !== undefined || jw !== undefined || seed) {
		if (canvas) {
			initCanvas();
		}
	}
</script>

<canvas bind:this={canvas} />

<style>
	canvas {
		image-rendering: auto;
		/* Ensure smooth scaling */
		-webkit-font-smoothing: antialiased;
		-moz-osx-font-smoothing: grayscale;
	}
</style>
