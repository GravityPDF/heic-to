// Decode libheif's own sample images with both src/lib builds and check the
// CSP bundles stay free of dynamic code execution.
//
//   node scripts/smoke-test.cjs <libheif source checkout>
const fs = require('fs');
const path = require('path');

const ROOT = path.resolve(__dirname, '..');
const libheifSrc = process.argv[2];
if (!libheifSrc) {
	console.error('Usage: node scripts/smoke-test.cjs <libheif source checkout>');
	process.exit(2);
}

const fixtures = [
	['examples/example.heic', 1280, 854],
	['tests/data/rainbow-451x461.heic', 451, 461],
	['tests/data/with-alpha-512x512.heic', 512, 512],
	// Clean-aperture crop; libheif 1.22.2 failed to decode this one.
	['tests/data/clap_cropped.heic', 64, 64],
];

// src/lib files are ES modules; load them as CommonJS without a bundler.
function load(file) {
	const src = fs
		.readFileSync(file, 'utf8')
		.replace(/export default buildLibheif;?\s*$/, 'module.exports = buildLibheif;');
	const m = new module.constructor(file);
	m.paths = module.paths;
	m._compile(src, file);
	return m.exports();
}

function decode(libheif, file) {
	const decoder = new libheif.HeifDecoder();
	const images = decoder.decode(fs.readFileSync(file));
	if (!images.length) throw new Error('HEIF image not found');
	const image = images[0];
	const width = image.get_width();
	const height = image.get_height();
	const target = { width, height, data: new Uint8ClampedArray(width * height * 4) };
	return new Promise((resolve, reject) => {
		image.display(target, (out) => {
			images.forEach((i) => i.free());
			libheif.heif_context_free(decoder.decoder);
			out ? resolve({ width, height, data: out.data }) : reject(new Error('display failed'));
		});
	});
}

const failures = [];

(async () => {
	for (const lib of ['src/lib/libheif.js', 'src/lib/libheif-without-unsafe-eval.js']) {
		const libheif = load(path.join(ROOT, lib));
		for (const [fixture, width, height] of fixtures) {
			const label = `${lib} ${fixture}`;
			try {
				const out = await decode(libheif, path.join(libheifSrc, fixture));
				if (out.width !== width || out.height !== height) {
					throw new Error(`expected ${width}x${height}, got ${out.width}x${out.height}`);
				}
				if (out.data.every((v, i) => v === out.data[i % 4])) {
					throw new Error('decoded image is a single flat colour');
				}
				console.log(`ok   ${label} (${width}x${height}, libheif ${libheif.heif_get_version()})`);
			} catch (e) {
				failures.push(label);
				console.log(`FAIL ${label}: ${e.message}`);
			}
		}
	}

	for (const file of ['src/lib/libheif-without-unsafe-eval.js', 'dist/csp/heic-to.js', 'dist/csp/heic-to.min.js']) {
		const hits = (fs.readFileSync(path.join(ROOT, file), 'utf8').match(/new Function|\beval\(/g) || []).length;
		if (hits) failures.push(file);
		console.log(`${hits ? 'FAIL' : 'ok  '} ${file} has ${hits} dynamic code execution call(s)`);
	}

	process.exit(failures.length ? 1 : 0);
})();
