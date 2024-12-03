<script>
	import { onMount } from 'svelte';
	import * as d3 from 'd3';
	import chroma from 'chroma-js';
	import namePatternData from './name_change_patterns.json';
	import IndiaGrid from './IndiaGrid.svelte';

	// Configuration constants
	const CONFIG = {
		baseWidth: 1000,
		baseHeight: 1000,
		width: 1400,
		height: 1000,
		padding: 10,
		pointRadius: 3.5,
		mobilePointRadius: 2.5,
		randomSeed: 421221,
		transitionDuration: 100,
		colors: [
			'#422040', // Dark purple
			'#DDB967', // Gold metallic
			'#BA5B38', // Jasper
			'#639A88', // Zomp
			'#7D8491', // Slate gray
			'#8B4B62', // Deep raspberry (derived)
			'#A7866A', // Warm taupe (derived)
			'#4A725A' // Deep sage (derived)
		],
		fontSize: {
			desktop: {
				label: 16,
				count: 14
			},
			mobile: {
				label: 12,
				count: 10
			}
		}
	};

	// State management
	let canvas;
	let overlayCanvas;
	let ctx;
	let overlayCtx;
	let scale = 1;
	let packedData;
	let selectedState = {
		code: 'PB',
		name: 'Punjab',
		fullName: 'Punjab'
	};
	let previousState = null;
	let transitionProgress = 1;
	let animationFrame;
	let pointPositions = new Map();

	// Tooltip state
	let tooltip = {
		visible: false,
		x: 0,
		y: 0,
		data: null
	};

	// Color mapping
	const patternColors = new Map(
		Array.from(new Set(namePatternData.map((d) => d.change_pattern))).map((pattern, i) => [
			pattern,
			CONFIG.colors[i % CONFIG.colors.length]
		])
	);

	// Utility functions
	const seededRandom = (seed) => {
		const x = Math.sin(seed++) * 10000;
		return x - Math.floor(x);
	};

	const calculatePointPosition = (group, index) => {
		const angle = seededRandom(CONFIG.randomSeed + index) * 2 * Math.PI;
		const radius = seededRandom(CONFIG.randomSeed + index + 1000) * (group.r * 0.9);
		return {
			x: group.x + CONFIG.padding + radius * Math.cos(angle),
			y: group.y + CONFIG.padding + radius * Math.sin(angle)
		};
	};

	const calculateOpacity = (point, baseOpacity = 0.2) => {
		if (!selectedState) return baseOpacity;

		const isSelected = point.data.State_Name === selectedState.fullName;
		const targetOpacity = isSelected ? baseOpacity : baseOpacity * 0.08;
		const startOpacity = previousState
			? point.data.State_Name === previousState.fullName
				? baseOpacity
				: baseOpacity * 0.5
			: baseOpacity;

		return startOpacity + (targetOpacity - startOpacity) * transitionProgress;
	};

	// Visualization functions
	const drawPoint = (point, group, index, isHovered = false) => {
		const { x, y } = calculatePointPosition(group, index);
		const color = patternColors.get(group.data.name);
		const opacity = calculateOpacity(point, 0.6 || 0.2);
		const radius = window.innerWidth < 768 ? CONFIG.mobilePointRadius : CONFIG.pointRadius;

		ctx.beginPath();
		ctx.arc(x, y, radius, 0, 2 * Math.PI);
		ctx.fillStyle = chroma(color).alpha(opacity).css();
		ctx.fill();

		if (selectedState && point.data.State_Name === selectedState.fullName) {
			ctx.strokeStyle = chroma(color).darken().css();
			ctx.lineWidth = 1;
			ctx.stroke();
		}

		if (isHovered) {
			ctx.strokeStyle = chroma(color).darken(2).css();
			ctx.lineWidth = 3;
			ctx.stroke();
		} else {
			ctx.strokeStyle = 'transparent';
			ctx.lineWidth = 0;
			ctx.stroke();
		}

		return { x, y };
	};

	const drawGroupLabel = (group) => {
		const label = group.data.name.replace(/_/g, ' ');
		const count = group.children.length;
		const centerX = CONFIG.width / 2;
		const centerY = CONFIG.height / 2;
		const angleToCenter = Math.atan2(group.y - centerY, group.x - centerX);

		const labelDistance = group.r;
		const labelX = group.x + CONFIG.padding + Math.cos(angleToCenter) * labelDistance;
		const labelY = group.y + CONFIG.padding + Math.sin(angleToCenter) * labelDistance;

		const isMobile = window.innerWidth < 768;
		const fontSize = isMobile ? CONFIG.fontSize.mobile : CONFIG.fontSize.desktop;

		ctx.textAlign = 'center';
		ctx.textBaseline = 'middle';

		// Set up text measurements
		ctx.font = `bold ${fontSize.label}px Asap Variable, Arial, sans-serif`;
		const labelWidth = ctx.measureText(label).width;
		const countText = `(${count})`;
		ctx.font = `${fontSize.count}px Asap Variable, Arial, sans-serif`;
		const countWidth = ctx.measureText(countText).width;

		// Calculate background dimensions
		const maxWidth = Math.max(labelWidth, countWidth) + 16; // Add padding
		const totalHeight = 15; // Adjust based on your needs
		const bgX = labelX - maxWidth / 2;
		const bgY = labelY - totalHeight / 2 - 8;

		// Draw white background with slight opacity
		ctx.fillStyle = 'rgba(255, 255, 255, 0.9)';
		ctx.beginPath();
		ctx.roundRect(bgX, bgY, maxWidth, totalHeight, 4);
		ctx.fill();

		// Draw main label
		ctx.fillStyle = '#1a1a1a';
		ctx.font = `bold ${fontSize.label}px Asap Variable, Arial, sans-serif`;
		ctx.fillText(label, labelX, labelY - 8);

		// Draw count
		ctx.fillStyle = '#666';
		ctx.font = `${fontSize.count}px Asap Variable, Arial, sans-serif`;
		ctx.fillText(countText, labelX, labelY + 14);
	};

	// Add quadtree state
	let quadtree;

	let lastY = 0;
	let offsetX = 0;
	let offsetY = 0;
	let zoom = 1;

	// Modify visualizeData to build quadtree
	const visualizeData = (data) => {
		if (!ctx) return;

		// Clear the entire canvas including the transformed area
		ctx.save();
		ctx.setTransform(1, 0, 0, 1, 0, 0);
		ctx.clearRect(0, 0, canvas.width, canvas.height);
		ctx.restore();

		// Apply pan and zoom transformations
		ctx.save();
		ctx.translate(offsetX, offsetY);
		ctx.scale(scale * zoom, scale * zoom);

		const root = d3
			.hierarchy({
				name: 'root',
				children: Array.from(
					d3.group(data, (d) => d.change_pattern),
					([key, value]) => ({
						name: key,
						value: value.length,
						children: value
					})
				)
			})
			.sum((d) => (d.children ? 0 : 1));

		const pack = d3
			.pack()
			.size([CONFIG.width - 2 * CONFIG.padding, CONFIG.height - 2 * CONFIG.padding])
			.padding(8);

		packedData = pack(root);

		// Clear previous positions
		pointPositions.clear();

		// Build quadtree and draw points first
		const points = [];
		packedData.children.forEach((group) => {
			if (group.children) {
				group.children.forEach((point, i) => {
					const pos = calculatePointPosition(group, i);
					points.push({
						x: pos.x,
						y: pos.y,
						point,
						group,
						index: i
					});
					drawPoint(point, group, i, false);
				});
			}
		});

		// Draw labels after all points
		packedData.children.forEach((group) => {
			drawGroupLabel(group);
		});

		quadtree = d3
			.quadtree()
			.x((d) => d.x)
			.y((d) => d.y)
			.addAll(points);

		ctx.restore();
	};

	// Event handlers
	const handleStateSelect = (event) => {
		previousState = selectedState;
		selectedState = event.detail;

		transitionProgress = 0;
		if (animationFrame) cancelAnimationFrame(animationFrame);
		animate();
	};

	const animate = () => {
		transitionProgress = Math.min(1, transitionProgress + 16 / CONFIG.transitionDuration);
		visualizeData(namePatternData);

		if (transitionProgress < 1) {
			animationFrame = requestAnimationFrame(animate);
		}
	};

	// New optimized handleMouseMove using quadtree
	const handleMouseMove = (event) => {
		if (!quadtree) return;

		const rect = canvas.getBoundingClientRect();
		const mouseX = (event.clientX - rect.left - offsetX) / (scale * zoom);
		const mouseY = (event.clientY - rect.top - offsetY) / (scale * zoom);

		// Clear both canvases
		ctx.clearRect(0, 0, canvas.width, canvas.height);
		overlayCtx.clearRect(0, 0, overlayCanvas.width, overlayCanvas.height);

		// Redraw all points first (this ensures non-hovered state is always visible)
		visualizeData(namePatternData);

		// Find closest point within radius
		const radius = 5;
		let closest = null;

		quadtree.visit((node, x1, y1, x2, y2) => {
			if (!node.length) {
				const d = node.data;
				// Only consider points from the selected state
				if (d.point.data.State_Name === selectedState.fullName) {
					const dx = d.x - mouseX;
					const dy = d.y - mouseY;
					const distance = Math.sqrt(dx * dx + dy * dy);

					if (distance < radius) {
						closest = d;
						return true;
					}
				}
			}
			return (
				x1 > mouseX + radius || x2 < mouseX - radius || y1 > mouseY + radius || y2 < mouseY - radius
			);
		});

		if (closest && closest.point.data.State_Name === selectedState.fullName) {
			// Draw hover effect on overlay canvas
			overlayCtx.save();
			overlayCtx.translate(offsetX, offsetY);
			overlayCtx.scale(scale * zoom, scale * zoom);
			drawPoint(closest.point, closest.group, closest.index, true);
			overlayCtx.restore();

			tooltip = {
				visible: true,
				x: event.clientX + 20,
				y: event.clientY - 10,
				data: {
					pattern: closest.group.data.name,
					state: closest.point.data.State_Name.replace(/_/g, ' '),
					confidence: closest.point.data.Weighted_Similarity,
					Ref_Candidate: closest.point.data.Ref_Candidate,
					newName: closest.point.data.Dummy_Candidate,
					color: patternColors.get(closest.group.data.name)
				}
			};
		} else {
			tooltip.visible = false;
		}
	};

	// Add resize handling
	let container;
	let resizeObserver;

	// Lifecycle
	onMount(() => {
		scale = window.devicePixelRatio || 1;
		ctx = canvas.getContext('2d');

		// Set initial canvas dimensions
		canvas.style.width = CONFIG.width + 'px';
		canvas.style.height = CONFIG.height + 'px';
		canvas.width = CONFIG.width * scale;
		canvas.height = CONFIG.height * scale;

		// Setup overlay canvas
		overlayCanvas = document.createElement('canvas');
		overlayCanvas.style.position = 'absolute';
		overlayCanvas.style.top = '0';
		overlayCanvas.style.left = '0';
		overlayCanvas.style.pointerEvents = 'none';
		overlayCanvas.style.width = CONFIG.width + 'px';
		overlayCanvas.style.height = CONFIG.height + 'px';
		overlayCanvas.width = CONFIG.width * scale;
		overlayCanvas.height = CONFIG.height * scale;
		canvas.parentNode.appendChild(overlayCanvas);
		overlayCtx = overlayCanvas.getContext('2d');

		// Add mouseleave event listener here
		canvas.addEventListener('mouseleave', () => {
			tooltip.visible = false;
			if (overlayCtx) {
				overlayCtx.clearRect(0, 0, overlayCanvas.width, overlayCanvas.height);
			}
			visualizeData(namePatternData); // Redraw to clear hover effect
		});

		// Draw initial visualization
		visualizeData(namePatternData);

		// Initialize ResizeObserver for subsequent resizes
		resizeObserver = new ResizeObserver((entries) => {
			for (const entry of entries) {
				const { width } = entry.contentRect;
				const aspectRatio = CONFIG.baseHeight / CONFIG.baseWidth;

				// Update current dimensions
				CONFIG.width = Math.min(width, CONFIG.baseWidth);
				CONFIG.height = CONFIG.width * aspectRatio;

				// Update canvas dimensions
				canvas.style.width = CONFIG.width + 'px';
				canvas.style.height = CONFIG.height + 'px';
				canvas.width = CONFIG.width * scale;
				canvas.height = CONFIG.height * scale;

				// Update overlay canvas
				overlayCanvas.style.width = CONFIG.width + 'px';
				overlayCanvas.style.height = CONFIG.height + 'px';
				overlayCanvas.width = CONFIG.width * scale;
				overlayCanvas.height = CONFIG.height * scale;

				// Redraw visualization
				visualizeData(namePatternData);
			}
		});

		// Start observing the container
		resizeObserver.observe(container);

		// Update canvas style based on screen size
		const updateCanvasStyle = () => {
			canvas.style.touchAction = window.innerWidth < 768 ? 'auto' : 'none';
		};

		// Initial update
		updateCanvasStyle();

		// Add resize listener to update canvas style
		window.addEventListener('resize', updateCanvasStyle);

		return () => {
			if (animationFrame) cancelAnimationFrame(animationFrame);
			if (resizeObserver) resizeObserver.disconnect();

			// Remove event listener on cleanup
			canvas.removeEventListener('mouseleave', () => {
				tooltip.visible = false;
				if (overlayCtx) {
					overlayCtx.clearRect(0, 0, overlayCanvas.width, overlayCanvas.height);
				}
			});

			overlayCanvas.remove();

			ctx = null;
			overlayCtx = null;
			window.removeEventListener('resize', updateCanvasStyle);
		};
	});
</script>

<div class="w-full md:relative" bind:this={container}>
	<div class="block md:hidden">
		<IndiaGrid on:stateSelect={handleStateSelect} {selectedState} />
	</div>
	<canvas
		bind:this={canvas}
		on:mousemove={handleMouseMove}
		on:mouseleave={() => {
			tooltip.visible = false;
			if (overlayCtx) {
				overlayCtx.clearRect(0, 0, overlayCanvas.width, overlayCanvas.height);
			}
		}}
	/>
	<div class="md:block hidden md:absolute bottom-[8%] md:left-[20%]">
		<IndiaGrid on:stateSelect={handleStateSelect} {selectedState} />
	</div>
	{#if tooltip.visible && tooltip.data}
		<div class="tooltip" style="left: {tooltip.x}px; top: {tooltip.y}px;">
			<div class="flex flex-col items-baseline gap-2 mb-2">
				<span class="pattern-label" style="background-color: {tooltip.data.color};">
					{tooltip.data.pattern.replace(/_/g, ' ')}
				</span>
				<h3 class="text-lg font-bold text-gray-800">{tooltip.data.state}</h3>
			</div>

			<div class="space-y-1 text-sm">
				<div class="font-medium text-gray-900">{tooltip.data.Ref_Candidate}</div>
				<div class="font-medium text-gray-500">compared to</div>
				<div class="font-medium text-gray-900">{tooltip.data.newName}</div>
			</div>

			<div class="flex flex-col items-start justify-start mt-3 space-y-1">
				<div class="-mb-1 text-xs font-medium text-gray-600">Similarity</div>
				<div class="text-2xl font-bold text-gray-900">
					{tooltip.data.confidence.toFixed(3)}
				</div>
			</div>
		</div>
	{/if}
</div>

<style>
	canvas {
		max-width: 100%;
		height: auto;
		touch-action: none; /* Prevents default touch behaviors */
		transition: all 0.3s ease; /* Add transition for smooth hover effect */
	}

	.tooltip {
		position: absolute;
		z-index: 10;
		padding: 0.75rem;
		background: white;
		border: 1px solid rgba(0, 0, 0, 0.1);
		border-radius: 0.5rem;
		box-shadow: 0 4px 6px -1px rgba(0, 0, 0, 0.1);
		min-width: 200px;
		max-width: 280px;
		pointer-events: none;
		transition: opacity 0.3s ease; /* Add transition for tooltip */
	}

	.pattern-label {
		padding: 0.125rem 0.5rem;
		font-size: 0.75rem;
		font-weight: 500;
		border-radius: 0.125rem;
		color: white;
	}

	@media (max-width: 768px) {
		.tooltip {
			min-width: 160px;
			max-width: 200px;
		}
	}
</style>
