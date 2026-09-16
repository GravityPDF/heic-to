# heic-to

Convert HEIC/HEIF images to JPEG, PNG in browser using Javascript.

Inspired by [heic2any](https://github.com/alexcorvi/heic2any) and [libheif-web](https://github.com/joutvhu/libheif-web). The purpose of heic-to is to continuously follow up on releases of [libheif](https://github.com/strukturag/libheif) to be able to preview HEIC/HEIF images in browser.

Currently, heic-to is using [libheif 1.23.4](https://github.com/strukturag/libheif/releases/tag/v1.23.4) and [libde265 1.1.3](https://github.com/strukturag/libde265/releases/tag/v1.1.3) under the hood. 

| Release  | libheif  |
| -------- | -------- |
| 1.6.0-gpdf | 1.23.4 | 
| 1.5.2    | 1.22.2   | 
| 1.5.1    | 1.22.1   | 
| 1.5.0    | 1.22.0   | 
| 1.4.3    | 1.21.2   | 
| 1.4.2    | 1.21.2   | 
| 1.4.1    | 1.21.1   | 
| 1.4.0    | 1.21.0   | 
| 1.3.1    | 1.20.2   | 
| 1.3.0    | 1.20.2   | 
| 1.2.2    | 1.20.2   | 
| 1.2.1    | 1.20.1   | 
| 1.2.0    | 1.20.0   | 
| 1.1.14   | 1.19.8   | 
| 1.1.14   | 1.19.8   | 
| 1.1.13   | 1.19.8   | 
| 1.1.12   | 1.19.7   | 
| 1.1.11   | 1.19.7   | 
| 1.1.10   | 1.19.7   | 
| 1.1.9    | 1.19.7   | 
| 1.1.8    | 1.19.7   | 
| 1.1.7    | 1.19.6   | 
| 1.1.6    | 1.19.5   | 
| 1.1.5    | 1.19.5   | 
| 1.1.4    | 1.19.4   | 
| 1.1.3    | 1.19.3   | 
| 1.1.2    | 1.19.2   | 
| 1.1.1    | 1.19.1   | 
| 1.1.0    | 1.19.0   | 
| 1.0.3    | 1.18.2   |
| 1.0.2    | 1.18.2   |
| 1.0.1    | 1.18.2   |
| 1.0.0    | 1.18.1   |

### Demo

Try the [🌟 live demo](https://hoppergee.github.io/heic-to/example/).

### Usage

#### Check whether the image is HEIC or not 

```js
import { isHeic } from "heic-to"

const file = field.files[0]
await isHeic(file)
```

#### Convert HEIC to JPEG/PNG/Bitmap


```js
import { heicTo } from "heic-to"

const file = field.files[0]

const jpeg = await heicTo({
  blob: file,
  type: "image/jpeg",
  quality: 0.5
})

const png = await heicTo({
  blob: file,
  type: "image/png",
  quality: 0.5
})

const bitmap = await heicTo({
  blob: file,
  type: "bitmap",
  options: {
    imageOrientation: "flipY"
  }
})
```

#### Cotent Security Policy

When meets CSP issue like this:

```
Refused to evaluate a string as JavaScript because 'unsafe-eval' is not an allowed source of script in the following Content Security Policy directive
```

Fix it by using `csp/heic-to` 

```diff
- import { heicTo } from "heic-to"
+ import { heicTo } from "heic-to/csp"
```

#### Access global variable with IIFE build

If you would like to access heic-to with pure JavaScript without package builder like with CDN.

```html
<script src="https://cdn.jsdelivr.net/npm/heic-to@1.5.2/dist/iife/heic-to.js"></script>
<script>
  /*...*/
  if (await HeicTo.isHeic(file)) {
    const jpeg = await HeicTo({
      blob: file,
      type: "image/jpeg",
      quality: 0.5
    })
    /*...*/
  }
  /*...*/
</script>
```

#### Call heic-to in web worker

If you want to call `heicTo` in web workers:

```diff
- import { heicTo } from "heic-to"
+ import { heicTo } from "heic-to/next"
```

### Development guide

#### How to fast test your changes on local?

```bash
yarn s
```

This will open `http://127.0.0.1:8080/example/` for easy testing.

#### How to build libheif.js from [libheif](https://github.com/strukturag/libheif)

`src/lib/libheif.js` and `src/lib/libheif-without-unsafe-eval.js` are built from source inside the [`emscripten/emsdk`](https://hub.docker.com/r/emscripten/emsdk) Docker image, so the only requirements are Docker and Node.

The libheif, libde265 and Emscripten versions are pinned in `scripts/libheif-versions.env`.

```bash
npm run build:libheif   # override with e.g. LIBHEIF_VERSION=1.23.5 npm run build:libheif
npm run build
node scripts/smoke-test.cjs
```

The smoke test decodes libheif's own sample images with both builds and checks that the CSP bundles contain no `eval`/`new Function`. The same steps run in the **Build libheif** GitHub Actions workflow, which fails if the committed `src/lib` and `dist` files don't match a clean build of the pinned versions. Running it by hand with version overrides uploads the rebuilt files as an artifact instead.

The **Check for libheif releases** workflow runs daily. When libheif or libde265 publishes a newer release, it rebuilds with it and opens a pull request if the smoke test passes, or an issue if the build fails.
