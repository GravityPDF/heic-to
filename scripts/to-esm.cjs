// Apply heic-to's hand edits to raw build-emscripten.sh output.
// Usage: node to-esm.cjs <in libheif.js> <out.js> "<provenance comment>"
const fs = require('fs');
const [input, output, provenance] = process.argv.slice(2);

const replacements = [
	['var libheif = (() => {', 'var buildLibheif = (() => {'],
	["  if (typeof __filename != 'undefined') _scriptName ||= __filename;\n", ''],
	[
		"if (typeof exports === 'object' && typeof module === 'object')\n  module.exports = libheif;\nelse if (typeof define === 'function' && define['amd'])\n  define([], () => libheif);\n",
		'\nexport default buildLibheif',
	],
];

let src = fs.readFileSync(input, 'utf8');
for (const [from, to] of replacements) {
	if (!src.includes(from)) {
		throw new Error(`Expected snippet not found: ${JSON.stringify(from.slice(0, 60))}`);
	}
	src = src.replace(from, to);
}
fs.writeFileSync(output, `// ${provenance}\n${src}`);
