import { findBestMatch } from 'string-similarity';
import distance from 'jaro-winkler';

const normalizeString = (str) => {
	// Remove extra spaces and trim
	return str.toLowerCase().replace(/\s+/g, ' ').trim();
};

const calculateBiSim = (X, Y) => {
	// Normalize strings before processing
	X = normalizeString(X);
	Y = normalizeString(Y);

	// Add prefix following paper specs - duplicates first letter and capitalizes it
	X = X.charAt(0).toUpperCase() + X.charAt(0) + X.slice(1);
	Y = Y.charAt(0).toUpperCase() + Y.charAt(0) + Y.slice(1);

	// if both strings are equal, return 1
	if (X === Y) return 1;

	const m = X.length;
	const n = Y.length;
	const offset = 1;

	// Initialize dynamic programming array
	let S = new Array(n - offset).fill(0);

	// Split strings into character arrays
	const X_chars = X.split('');
	const Y_chars = Y.split('');

	// Main dynamic programming loop for bigram LCS
	for (let i = 1; i < m - offset; i++) {
		let prev = 0;

		for (let j = 1; j < n - offset; j++) {
			const curr = S[j - 1];

			const curr_match = X_chars[i].toLowerCase() === Y_chars[j].toLowerCase() ? 1 : 0;
			const prev_match = X_chars[i - 1].toLowerCase() === Y_chars[j - 1].toLowerCase() ? 1 : 0;
			const ident = curr_match + prev_match;

			const diag = prev + ident / 2;

			S[j - 1] = Math.max(diag, curr, S[Math.max(0, j - 2)]);

			prev = curr;
		}
	}

	// Changed this line to use the correct index
	const score = S[n - offset - 2]; // -2 instead of -1 because we're using 0-based indexing
	return score / (Math.max(m, n) - 1);
};

// Replace the custom DC and JW implementations with package versions
const calculateDC = (str1, str2) => {
	// Normalize strings before comparison
	str1 = normalizeString(str1);
	str2 = normalizeString(str2);
	return findBestMatch(str1, [str2]).ratings[0].rating;
};

const calculateJW = (s1, s2) => {
	// Normalize strings before comparison
	s1 = normalizeString(s1);
	s2 = normalizeString(s2);
	return distance(s1, s2);
};

// Main comparison function
const compareName = (name1, name2) => {
	const bisim = calculateBiSim(name1, name2);
	const dice = calculateDC(name1, name2);
	const jw = calculateJW(name1, name2);

	// Use the same weights as FaceGenerator.svelte
	const average = bisim * 0.6 + dice * 0.39 + jw * 0.01;

	return {
		bisim: Math.round(bisim * 1000) / 1000,
		dice: Math.round(dice * 1000) / 1000,
		jw: Math.round(jw * 1000) / 1000,
		average: Math.round(average * 1000) / 1000
	};
};

export default compareName;
