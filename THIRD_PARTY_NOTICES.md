# Third-Party Notices

This file records third-party code, binaries, models, tools, and packages used by depth-map-exporter. The project LICENSE applies only to code, documentation, and assets developed for this repository by its authors/maintainers. Anything not developed by us remains covered by its own license, terms, and notices.

This is a best-effort notice file generated from the current repository state, `electron-ui/package.json`, `electron-ui/package-lock.json`, the installed local `node_modules` package metadata, and upstream model/runtime pages checked while preparing this file. It is not legal advice.

## Bundled or Distributed Third-Party Materials

| Material | Where used | License / terms | Source / notes |
| --- | --- | --- | --- |
| DepthAnythingV2SmallF16.mlpackage | Bundled at `electron-ui/resources/models/DepthAnythingV2SmallF16.mlpackage` | Apache-2.0 | Apple/Hugging Face Core ML Depth Anything V2 Small model: https://huggingface.co/apple/coreml-depth-anything-v2-small and https://developer.apple.com/machine-learning/models/ |
| Electron runtime | Electron GUI and packaged macOS app | MIT for Electron, with Chromium/Node/V8 and other runtime components under their own notices | Electron package: https://github.com/electron/electron. After `npm install`, Electron runtime notices are available at `electron-ui/node_modules/electron/LICENSE`, `electron-ui/node_modules/electron/dist/LICENSE`, and `electron-ui/node_modules/electron/dist/LICENSES.chromium.html`; packaged apps should preserve those runtime notices. |
| htmx | Renderer asset copied from npm package during GUI asset preparation | 0BSD | `htmx.org` npm package / https://github.com/bigskysoftware/htmx |
| npm packages | Electron GUI build/runtime dependencies | See inventory below | Exact package versions and declared licenses come from `electron-ui/package-lock.json`. |

Apple platform frameworks and SDKs used by the Swift CLI, such as AVFoundation, Core ML, Core Image, Metal, and related system libraries, are Apple components and are governed by Apple's applicable SDK/platform terms. They are not relicensed by this repository.

The bundled `electron-ui/resources/bin/depth-exporter` binary is built from this repository's Swift source and uses Apple platform frameworks at runtime.

## Direct npm Dependencies

| Package | Version | Dependency type | Declared license | Source |
| --- | --- | --- | --- | --- |
| @types/node | 24.13.2 | development direct | MIT | https://github.com/DefinitelyTyped/DefinitelyTyped.git |
| autoprefixer | 10.5.2 | development direct | MIT | postcss/autoprefixer |
| electron | 37.10.3 | development direct | MIT | https://github.com/electron/electron |
| electron-builder | 26.15.3 | development direct | MIT | https://github.com/electron-userland/electron-builder.git |
| htmx.org | 2.0.10 | runtime direct | 0BSD | https://github.com/bigskysoftware/htmx.git |
| postcss | 8.5.16 | development direct | MIT | postcss/postcss |
| tailwindcss | 3.4.19 | development direct | MIT | https://github.com/tailwindlabs/tailwindcss.git#v3 |
| typescript | 5.9.3 | development direct | Apache-2.0 | https://github.com/microsoft/TypeScript.git |

## npm License Summary

| Declared license | Package count |
| --- | ---: |
| (MIT OR CC0-1.0) | 1 |
| (WTFPL OR MIT) | 1 |
| 0BSD | 2 |
| Apache-2.0 | 10 |
| BlueOak-1.0.0 | 8 |
| BSD-2-Clause | 6 |
| BSD-3-Clause | 10 |
| CC-BY-4.0 | 1 |
| ISC | 47 |
| MIT | 309 |
| Python-2.0 | 1 |
| WTFPL | 1 |
| WTFPL OR ISC | 1 |

## Full npm Dependency Inventory

Generated from `electron-ui/package-lock.json`. Dev/build dependencies are included because they are part of the reproducible project toolchain even when they are not shipped in the final app.

| Package | Version | Dependency type | Declared license | Source |
| --- | --- | --- | --- | --- |
| @alloc/quick-lru | 5.2.0 | transitive | MIT | sindresorhus/quick-lru |
| @electron/asar | 3.4.1 | transitive | MIT | https://github.com/electron/asar.git |
| @electron/asar/node_modules/balanced-match | 1.0.2 | transitive | MIT | git://github.com/juliangruber/balanced-match.git |
| @electron/asar/node_modules/brace-expansion | 1.1.15 | transitive | MIT | git://github.com/juliangruber/brace-expansion.git |
| @electron/asar/node_modules/minimatch | 3.1.5 | transitive | ISC | git://github.com/isaacs/minimatch.git |
| @electron/fuses | 1.8.0 | transitive | MIT | https://github.com/electron/fuses.git |
| @electron/fuses/node_modules/fs-extra | 9.1.0 | transitive | MIT | https://github.com/jprichardson/node-fs-extra |
| @electron/fuses/node_modules/jsonfile | 6.2.1 | transitive | MIT | git@github.com:jprichardson/node-jsonfile.git |
| @electron/fuses/node_modules/universalify | 2.0.1 | transitive | MIT | https://github.com/RyanZim/universalify.git |
| @electron/get | 2.0.3 | transitive | MIT | https://github.com/electron/get |
| @electron/notarize | 2.5.0 | transitive | MIT | https://github.com/electron/notarize.git |
| @electron/notarize/node_modules/fs-extra | 9.1.0 | transitive | MIT | https://github.com/jprichardson/node-fs-extra |
| @electron/notarize/node_modules/jsonfile | 6.2.1 | transitive | MIT | git@github.com:jprichardson/node-jsonfile.git |
| @electron/notarize/node_modules/universalify | 2.0.1 | transitive | MIT | https://github.com/RyanZim/universalify.git |
| @electron/osx-sign | 1.3.3 | transitive | BSD-2-Clause | https://github.com/electron/osx-sign.git |
| @electron/osx-sign/node_modules/fs-extra | 10.1.0 | transitive | MIT | https://github.com/jprichardson/node-fs-extra |
| @electron/osx-sign/node_modules/isbinaryfile | 4.0.10 | transitive | MIT | https://github.com/gjtorikian/isBinaryFile |
| @electron/osx-sign/node_modules/jsonfile | 6.2.1 | transitive | MIT | git@github.com:jprichardson/node-jsonfile.git |
| @electron/osx-sign/node_modules/universalify | 2.0.1 | transitive | MIT | https://github.com/RyanZim/universalify.git |
| @electron/rebuild | 4.1.0 | transitive | MIT | https://github.com/electron/rebuild.git |
| @electron/universal | 2.0.3 | transitive | MIT | https://github.com/electron/universal.git |
| @electron/universal/node_modules/balanced-match | 1.0.2 | transitive | MIT | git://github.com/juliangruber/balanced-match.git |
| @electron/universal/node_modules/brace-expansion | 2.1.1 | transitive | MIT | git://github.com/juliangruber/brace-expansion.git |
| @electron/universal/node_modules/fs-extra | 11.3.6 | transitive | MIT | https://github.com/jprichardson/node-fs-extra.git |
| @electron/universal/node_modules/jsonfile | 6.2.1 | transitive | MIT | git@github.com:jprichardson/node-jsonfile.git |
| @electron/universal/node_modules/minimatch | 9.0.9 | transitive | ISC | git://github.com/isaacs/minimatch.git |
| @electron/universal/node_modules/universalify | 2.0.1 | transitive | MIT | https://github.com/RyanZim/universalify.git |
| @electron/windows-sign | 1.2.2 | transitive | BSD-2-Clause | https://github.com/electron/windows-sign.git |
| @electron/windows-sign/node_modules/fs-extra | 11.3.6 | transitive | MIT | https://github.com/jprichardson/node-fs-extra.git |
| @electron/windows-sign/node_modules/jsonfile | 6.2.1 | transitive | MIT | git@github.com:jprichardson/node-jsonfile.git |
| @electron/windows-sign/node_modules/universalify | 2.0.1 | transitive | MIT | https://github.com/RyanZim/universalify.git |
| @isaacs/fs-minipass | 4.0.1 | transitive | ISC | https://github.com/npm/fs-minipass.git |
| @jridgewell/gen-mapping | 0.3.13 | transitive | MIT | https://github.com/jridgewell/sourcemaps.git |
| @jridgewell/resolve-uri | 3.1.2 | transitive | MIT | https://github.com/jridgewell/resolve-uri |
| @jridgewell/sourcemap-codec | 1.5.5 | transitive | MIT | https://github.com/jridgewell/sourcemaps.git |
| @jridgewell/trace-mapping | 0.3.31 | transitive | MIT | https://github.com/jridgewell/sourcemaps.git |
| @malept/cross-spawn-promise | 2.0.0 | transitive | Apache-2.0 | https://github.com/malept/cross-spawn-promise |
| @malept/flatpak-bundler | 0.4.0 | transitive | MIT | https://github.com/malept/flatpak-bundler.git |
| @malept/flatpak-bundler/node_modules/fs-extra | 9.1.0 | transitive | MIT | https://github.com/jprichardson/node-fs-extra |
| @malept/flatpak-bundler/node_modules/jsonfile | 6.2.1 | transitive | MIT | git@github.com:jprichardson/node-jsonfile.git |
| @malept/flatpak-bundler/node_modules/universalify | 2.0.1 | transitive | MIT | https://github.com/RyanZim/universalify.git |
| @noble/hashes | 2.2.0 | transitive | MIT | https://github.com/paulmillr/noble-hashes.git |
| @nodelib/fs.scandir | 2.1.5 | transitive | MIT | https://github.com/nodelib/nodelib/tree/master/packages/fs/fs.scandir |
| @nodelib/fs.stat | 2.0.5 | transitive | MIT | https://github.com/nodelib/nodelib/tree/master/packages/fs/fs.stat |
| @nodelib/fs.walk | 1.2.8 | transitive | MIT | https://github.com/nodelib/nodelib/tree/master/packages/fs/fs.walk |
| @peculiar/asn1-schema | 2.8.0 | transitive | MIT | https://github.com/PeculiarVentures/asn1-schema |
| @peculiar/json-schema | 1.1.12 | transitive | MIT | https://github.com/PeculiarVentures/json-schema.git |
| @peculiar/utils | 2.0.3 | transitive | MIT | https://github.com/PeculiarVentures/pvtsutils |
| @peculiar/webcrypto | 1.7.1 | transitive | MIT | https://github.com/PeculiarVentures/webcrypto |
| @sindresorhus/is | 4.6.0 | transitive | MIT | sindresorhus/is |
| @szmarczak/http-timer | 4.0.6 | transitive | MIT | https://github.com/szmarczak/http-timer.git |
| @types/cacheable-request | 6.0.3 | transitive | MIT | https://github.com/DefinitelyTyped/DefinitelyTyped.git |
| @types/debug | 4.1.13 | transitive | MIT | https://github.com/DefinitelyTyped/DefinitelyTyped.git |
| @types/fs-extra | 9.0.13 | transitive | MIT | https://github.com/DefinitelyTyped/DefinitelyTyped.git |
| @types/http-cache-semantics | 4.2.0 | transitive | MIT | https://github.com/DefinitelyTyped/DefinitelyTyped.git |
| @types/keyv | 3.1.4 | transitive | MIT | https://github.com/DefinitelyTyped/DefinitelyTyped.git |
| @types/ms | 2.1.0 | transitive | MIT | https://github.com/DefinitelyTyped/DefinitelyTyped.git |
| @types/node | 24.13.2 | development direct | MIT | https://github.com/DefinitelyTyped/DefinitelyTyped.git |
| @types/responselike | 1.0.3 | transitive | MIT | https://github.com/DefinitelyTyped/DefinitelyTyped.git |
| @types/yauzl | 2.10.3 | transitive | MIT | https://github.com/DefinitelyTyped/DefinitelyTyped.git |
| @xmldom/xmldom | 0.8.13 | transitive | MIT | git://github.com/xmldom/xmldom.git |
| abbrev | 4.0.0 | transitive | ISC | https://github.com/npm/abbrev-js.git |
| agent-base | 7.1.4 | transitive | MIT | https://github.com/TooTallNate/proxy-agents.git |
| ajv | 8.20.0 | transitive | MIT | ajv-validator/ajv |
| ansi-regex | 5.0.1 | transitive | MIT | chalk/ansi-regex |
| ansi-styles | 4.3.0 | transitive | MIT | chalk/ansi-styles |
| any-promise | 1.3.0 | transitive | MIT | https://github.com/kevinbeaty/any-promise |
| anymatch | 3.1.3 | transitive | ISC | https://github.com/micromatch/anymatch |
| app-builder-lib | 26.15.3 | transitive | MIT | https://github.com/electron-userland/electron-builder.git |
| app-builder-lib/node_modules/@electron/get | 3.1.0 | transitive | MIT | https://github.com/electron/get |
| app-builder-lib/node_modules/@electron/get/node_modules/fs-extra | 8.1.0 | transitive | MIT | https://github.com/jprichardson/node-fs-extra |
| app-builder-lib/node_modules/@electron/get/node_modules/semver | 6.3.1 | transitive | ISC | https://github.com/npm/node-semver.git |
| app-builder-lib/node_modules/ci-info | 4.3.1 | transitive | MIT | github:watson/ci-info |
| app-builder-lib/node_modules/fs-extra | 10.1.0 | transitive | MIT | https://github.com/jprichardson/node-fs-extra |
| app-builder-lib/node_modules/fs-extra/node_modules/jsonfile | 6.2.1 | transitive | MIT | git@github.com:jprichardson/node-jsonfile.git |
| app-builder-lib/node_modules/fs-extra/node_modules/universalify | 2.0.1 | transitive | MIT | https://github.com/RyanZim/universalify.git |
| app-builder-lib/node_modules/semver | 7.7.4 | transitive | ISC | https://github.com/npm/node-semver.git |
| arg | 5.0.2 | transitive | MIT | vercel/arg |
| argparse | 2.0.1 | transitive | Python-2.0 | nodeca/argparse |
| asn1js | 3.0.10 | transitive | BSD-3-Clause | https://github.com/PeculiarVentures/ASN1.js |
| async | 3.2.6 | transitive | MIT | https://github.com/caolan/async.git |
| async-exit-hook | 2.0.1 | transitive | MIT | https://github.com/tapppi/async-exit-hook.git |
| asynckit | 0.4.0 | transitive | MIT | https://github.com/alexindigo/asynckit.git |
| at-least-node | 1.0.0 | transitive | ISC | https://github.com/RyanZim/at-least-node.git |
| autoprefixer | 10.5.2 | development direct | MIT | postcss/autoprefixer |
| aws4 | 1.13.2 | transitive | MIT | github:mhart/aws4 |
| balanced-match | 4.0.4 | transitive | MIT | git://github.com/juliangruber/balanced-match.git |
| base64-js | 1.5.1 | transitive | MIT | git://github.com/beatgammit/base64-js.git |
| baseline-browser-mapping | 2.10.42 | transitive | Apache-2.0 | https://github.com/web-platform-dx/baseline-browser-mapping.git |
| binary-extensions | 2.3.0 | transitive | MIT | sindresorhus/binary-extensions |
| bluebird | 3.7.2 | transitive | MIT | git://github.com/petkaantonov/bluebird.git |
| boolean | 3.2.0 | transitive | MIT | git://github.com/thenativeweb/boolean.git |
| brace-expansion | 5.0.7 | transitive | MIT | https://github.com/juliangruber/brace-expansion.git |
| braces | 3.0.3 | transitive | MIT | micromatch/braces |
| browserslist | 4.28.4 | transitive | MIT | browserslist/browserslist |
| buffer-crc32 | 0.2.13 | transitive | MIT | git://github.com/brianloveswords/buffer-crc32.git |
| buffer-from | 1.1.2 | transitive | MIT | LinusU/buffer-from |
| builder-util | 26.15.3 | transitive | MIT | https://github.com/electron-userland/electron-builder.git |
| builder-util-runtime | 9.7.0 | transitive | MIT | https://github.com/electron-userland/electron-builder.git |
| builder-util/node_modules/fs-extra | 10.1.0 | transitive | MIT | https://github.com/jprichardson/node-fs-extra |
| builder-util/node_modules/jsonfile | 6.2.1 | transitive | MIT | git@github.com:jprichardson/node-jsonfile.git |
| builder-util/node_modules/universalify | 2.0.1 | transitive | MIT | https://github.com/RyanZim/universalify.git |
| bytestreamjs | 2.0.1 | transitive | BSD-3-Clause | git://github.com/PeculiarVentures/ByteStream.js.git |
| cacheable-lookup | 5.0.4 | transitive | MIT | https://github.com/szmarczak/cacheable-lookup.git |
| cacheable-request | 7.0.4 | transitive | MIT | lukechilds/cacheable-request |
| call-bind-apply-helpers | 1.0.2 | transitive | MIT | https://github.com/ljharb/call-bind-apply-helpers.git |
| camelcase-css | 2.0.1 | transitive | MIT | stevenvachon/camelcase-css |
| caniuse-lite | 1.0.30001800 | transitive | CC-BY-4.0 | browserslist/caniuse-lite |
| chalk | 4.1.2 | transitive | MIT | chalk/chalk |
| chokidar | 3.6.0 | transitive | MIT | https://github.com/paulmillr/chokidar.git |
| chokidar/node_modules/glob-parent | 5.1.2 | transitive | ISC | gulpjs/glob-parent |
| chownr | 3.0.0 | transitive | BlueOak-1.0.0 | git://github.com/isaacs/chownr.git |
| chromium-pickle-js | 0.2.0 | transitive | MIT | https://github.com/electron/node-chromium-pickle-js.git |
| ci-info | 4.4.0 | transitive | MIT | github:watson/ci-info |
| cliui | 8.0.1 | transitive | ISC | yargs/cliui |
| clone-response | 1.0.3 | transitive | MIT | https://github.com/sindresorhus/clone-response.git |
| color-convert | 2.0.1 | transitive | MIT | Qix-/color-convert |
| color-name | 1.1.4 | transitive | MIT | git@github.com:colorjs/color-name.git |
| combined-stream | 1.0.8 | transitive | MIT | git://github.com/felixge/node-combined-stream.git |
| commander | 5.1.0 | transitive | MIT | https://github.com/tj/commander.js.git |
| compare-version | 0.1.2 | transitive | MIT | kevva/compare-version |
| concat-map | 0.0.1 | transitive | MIT | git://github.com/substack/node-concat-map.git |
| core-util-is | 1.0.3 | transitive | MIT | git://github.com/isaacs/core-util-is |
| cross-dirname | 0.1.0 | transitive | MIT | https://github.com/JumpLink/cross-dirname.git |
| cross-spawn | 7.0.6 | transitive | MIT | git@github.com:moxystudio/node-cross-spawn.git |
| cross-spawn/node_modules/isexe | 2.0.0 | transitive | ISC | https://github.com/isaacs/isexe.git |
| cross-spawn/node_modules/which | 2.0.2 | transitive | ISC | git://github.com/isaacs/node-which.git |
| cssesc | 3.0.0 | transitive | MIT | https://github.com/mathiasbynens/cssesc.git |
| debug | 4.4.3 | transitive | MIT | git://github.com/debug-js/debug.git |
| decompress-response | 6.0.0 | transitive | MIT | sindresorhus/decompress-response |
| decompress-response/node_modules/mimic-response | 3.1.0 | transitive | MIT | sindresorhus/mimic-response |
| defer-to-connect | 2.0.1 | transitive | MIT | https://github.com/szmarczak/defer-to-connect.git |
| define-data-property | 1.1.4 | transitive | MIT | https://github.com/ljharb/define-data-property.git |
| define-properties | 1.2.1 | transitive | MIT | git://github.com/ljharb/define-properties.git |
| delayed-stream | 1.0.0 | transitive | MIT | git://github.com/felixge/node-delayed-stream.git |
| detect-node | 2.1.0 | transitive | MIT | https://github.com/iliakan/detect-node |
| didyoumean | 1.2.2 | transitive | Apache-2.0 | https://github.com/dcporter/didyoumean.js.git |
| dir-compare | 4.2.0 | transitive | MIT | https://github.com/gliviu/dir-compare |
| dir-compare/node_modules/balanced-match | 1.0.2 | transitive | MIT | git://github.com/juliangruber/balanced-match.git |
| dir-compare/node_modules/brace-expansion | 1.1.15 | transitive | MIT | git://github.com/juliangruber/brace-expansion.git |
| dir-compare/node_modules/minimatch | 3.1.5 | transitive | ISC | git://github.com/isaacs/minimatch.git |
| dlv | 1.1.3 | transitive | MIT | developit/dlv |
| dmg-builder | 26.15.3 | transitive | MIT | https://github.com/electron-userland/electron-builder.git |
| dmg-builder/node_modules/fs-extra | 10.1.0 | transitive | MIT | https://github.com/jprichardson/node-fs-extra |
| dmg-builder/node_modules/jsonfile | 6.2.1 | transitive | MIT | git@github.com:jprichardson/node-jsonfile.git |
| dmg-builder/node_modules/universalify | 2.0.1 | transitive | MIT | https://github.com/RyanZim/universalify.git |
| dotenv | 16.6.1 | transitive | BSD-2-Clause | git://github.com/motdotla/dotenv.git |
| dotenv-expand | 11.0.7 | transitive | BSD-2-Clause | https://github.com/motdotla/dotenv-expand |
| dunder-proto | 1.0.1 | transitive | MIT | https://github.com/es-shims/dunder-proto.git |
| duplexer2 | 0.1.4 | transitive | BSD-3-Clause | deoxxa/duplexer2 |
| ejs | 3.1.10 | transitive | Apache-2.0 | git://github.com/mde/ejs.git |
| electron | 37.10.3 | development direct | MIT | https://github.com/electron/electron |
| electron-builder | 26.15.3 | development direct | MIT | https://github.com/electron-userland/electron-builder.git |
| electron-builder-squirrel-windows | 26.15.3 | transitive | MIT | https://github.com/electron-userland/electron-builder.git |
| electron-builder/node_modules/fs-extra | 10.1.0 | transitive | MIT | https://github.com/jprichardson/node-fs-extra |
| electron-builder/node_modules/jsonfile | 6.2.1 | transitive | MIT | git@github.com:jprichardson/node-jsonfile.git |
| electron-builder/node_modules/universalify | 2.0.1 | transitive | MIT | https://github.com/RyanZim/universalify.git |
| electron-publish | 26.15.3 | transitive | MIT | https://github.com/electron-userland/electron-builder.git |
| electron-publish/node_modules/fs-extra | 10.1.0 | transitive | MIT | https://github.com/jprichardson/node-fs-extra |
| electron-publish/node_modules/jsonfile | 6.2.1 | transitive | MIT | git@github.com:jprichardson/node-jsonfile.git |
| electron-publish/node_modules/universalify | 2.0.1 | transitive | MIT | https://github.com/RyanZim/universalify.git |
| electron-to-chromium | 1.5.387 | transitive | ISC | https://github.com/Kilian/electron-to-chromium.git |
| electron-winstaller | 5.4.0 | transitive | MIT | https://github.com/electron/windows-installer |
| electron-winstaller/node_modules/fs-extra | 7.0.1 | transitive | MIT | https://github.com/jprichardson/node-fs-extra |
| electron/node_modules/@types/node | 22.20.0 | transitive | MIT | https://github.com/DefinitelyTyped/DefinitelyTyped.git |
| electron/node_modules/undici-types | 6.21.0 | transitive | MIT | https://github.com/nodejs/undici.git |
| emoji-regex | 8.0.0 | transitive | MIT | https://github.com/mathiasbynens/emoji-regex.git |
| end-of-stream | 1.4.5 | transitive | MIT | git://github.com/mafintosh/end-of-stream.git |
| env-paths | 2.2.1 | transitive | MIT | sindresorhus/env-paths |
| err-code | 2.0.3 | transitive | MIT | git://github.com/IndigoUnited/js-err-code.git |
| es-define-property | 1.0.1 | transitive | MIT | https://github.com/ljharb/es-define-property.git |
| es-errors | 1.3.0 | transitive | MIT | https://github.com/ljharb/es-errors.git |
| es-object-atoms | 1.1.2 | transitive | MIT | https://github.com/ljharb/es-object-atoms.git |
| es-set-tostringtag | 2.1.0 | transitive | MIT | https://github.com/es-shims/es-set-tostringtag.git |
| es6-error | 4.1.1 | transitive | MIT | https://github.com/bjyoungblood/es6-error.git |
| escalade | 3.2.0 | transitive | MIT | lukeed/escalade |
| escape-string-regexp | 4.0.0 | transitive | MIT | sindresorhus/escape-string-regexp |
| exponential-backoff | 3.1.3 | transitive | Apache-2.0 | https://github.com/coveooss/exponential-backoff.git |
| extract-zip | 2.0.1 | transitive | BSD-2-Clause | maxogden/extract-zip |
| fast-deep-equal | 3.1.3 | transitive | MIT | https://github.com/epoberezkin/fast-deep-equal.git |
| fast-glob | 3.3.3 | transitive | MIT | mrmlnc/fast-glob |
| fast-glob/node_modules/glob-parent | 5.1.2 | transitive | ISC | gulpjs/glob-parent |
| fast-uri | 3.1.3 | transitive | BSD-3-Clause | https://github.com/fastify/fast-uri.git |
| fastq | 1.20.1 | transitive | ISC | https://github.com/mcollina/fastq.git |
| fd-slicer | 1.1.0 | transitive | MIT | git://github.com/andrewrk/node-fd-slicer.git |
| filelist | 1.0.6 | transitive | Apache-2.0 | git://github.com/mde/filelist.git |
| filelist/node_modules/balanced-match | 1.0.2 | transitive | MIT | git://github.com/juliangruber/balanced-match.git |
| filelist/node_modules/brace-expansion | 2.1.1 | transitive | MIT | git://github.com/juliangruber/brace-expansion.git |
| filelist/node_modules/minimatch | 5.1.9 | transitive | ISC | git://github.com/isaacs/minimatch.git |
| fill-range | 7.1.1 | transitive | MIT | jonschlinkert/fill-range |
| form-data | 4.0.6 | transitive | MIT | git://github.com/form-data/form-data.git |
| fraction.js | 5.3.4 | transitive | MIT | ssh://git@github.com/rawify/Fraction.js.git |
| fs-extra | 8.1.0 | transitive | MIT | https://github.com/jprichardson/node-fs-extra |
| fs.realpath | 1.0.0 | transitive | ISC | https://github.com/isaacs/fs.realpath.git |
| fsevents | 2.3.3 | transitive | MIT | https://github.com/fsevents/fsevents.git |
| function-bind | 1.1.2 | transitive | MIT | https://github.com/Raynos/function-bind.git |
| get-caller-file | 2.0.5 | transitive | ISC | https://github.com/stefanpenner/get-caller-file.git |
| get-intrinsic | 1.3.0 | transitive | MIT | https://github.com/ljharb/get-intrinsic.git |
| get-proto | 1.0.1 | transitive | MIT | https://github.com/ljharb/get-proto.git |
| get-stream | 5.2.0 | transitive | MIT | sindresorhus/get-stream |
| glob | 7.2.3 | transitive | ISC | git://github.com/isaacs/node-glob.git |
| glob-parent | 6.0.2 | transitive | ISC | gulpjs/glob-parent |
| glob/node_modules/balanced-match | 1.0.2 | transitive | MIT | git://github.com/juliangruber/balanced-match.git |
| glob/node_modules/brace-expansion | 1.1.15 | transitive | MIT | git://github.com/juliangruber/brace-expansion.git |
| glob/node_modules/minimatch | 3.1.5 | transitive | ISC | git://github.com/isaacs/minimatch.git |
| global-agent | 3.0.0 | transitive | BSD-3-Clause | https://github.com/gajus/global-agent |
| global-agent/node_modules/semver | 7.8.5 | transitive | ISC | https://github.com/npm/node-semver.git |
| globalthis | 1.0.4 | transitive | MIT | git://github.com/ljharb/System.global.git |
| gopd | 1.2.0 | transitive | MIT | https://github.com/ljharb/gopd.git |
| got | 11.8.6 | transitive | MIT | sindresorhus/got |
| graceful-fs | 4.2.11 | transitive | ISC | https://github.com/isaacs/node-graceful-fs |
| has-flag | 4.0.0 | transitive | MIT | sindresorhus/has-flag |
| has-property-descriptors | 1.0.2 | transitive | MIT | https://github.com/inspect-js/has-property-descriptors.git |
| has-symbols | 1.1.0 | transitive | MIT | git://github.com/inspect-js/has-symbols.git |
| has-tostringtag | 1.0.2 | transitive | MIT | https://github.com/inspect-js/has-tostringtag.git |
| hasown | 2.0.4 | transitive | MIT | https://github.com/inspect-js/hasOwn.git |
| hosted-git-info | 4.1.0 | transitive | ISC | https://github.com/npm/hosted-git-info.git |
| htmx.org | 2.0.10 | runtime direct | 0BSD | https://github.com/bigskysoftware/htmx.git |
| http-cache-semantics | 4.2.0 | transitive | BSD-2-Clause | https://github.com/kornelski/http-cache-semantics.git |
| http-proxy-agent | 7.0.2 | transitive | MIT | https://github.com/TooTallNate/proxy-agents.git |
| http2-wrapper | 1.0.3 | transitive | MIT | https://github.com/szmarczak/http2-wrapper.git |
| https-proxy-agent | 7.0.6 | transitive | MIT | https://github.com/TooTallNate/proxy-agents.git |
| inflight | 1.0.6 | transitive | ISC | https://github.com/npm/inflight.git |
| inherits | 2.0.4 | transitive | ISC | git://github.com/isaacs/inherits |
| is-binary-path | 2.1.0 | transitive | MIT | sindresorhus/is-binary-path |
| is-core-module | 2.16.2 | transitive | MIT | https://github.com/inspect-js/is-core-module.git |
| is-extglob | 2.1.1 | transitive | MIT | jonschlinkert/is-extglob |
| is-fullwidth-code-point | 3.0.0 | transitive | MIT | sindresorhus/is-fullwidth-code-point |
| is-glob | 4.0.3 | transitive | MIT | micromatch/is-glob |
| is-number | 7.0.0 | transitive | MIT | jonschlinkert/is-number |
| isarray | 1.0.0 | transitive | MIT | git://github.com/juliangruber/isarray.git |
| isbinaryfile | 5.0.7 | transitive | MIT | https://github.com/gjtorikian/isBinaryFile |
| isexe | 3.1.5 | transitive | BlueOak-1.0.0 | https://github.com/isaacs/isexe |
| jake | 10.9.4 | transitive | Apache-2.0 | git://github.com/jakejs/jake.git |
| jiti | 2.7.0 | transitive | MIT | unjs/jiti |
| js-yaml | 4.3.0 | transitive | MIT | nodeca/js-yaml |
| json-buffer | 3.0.1 | transitive | MIT | git://github.com/dominictarr/json-buffer.git |
| json-schema-traverse | 1.0.0 | transitive | MIT | https://github.com/epoberezkin/json-schema-traverse.git |
| json-stringify-safe | 5.0.1 | transitive | ISC | git://github.com/isaacs/json-stringify-safe |
| json5 | 2.2.3 | transitive | MIT | https://github.com/json5/json5.git |
| jsonfile | 4.0.0 | transitive | MIT | git@github.com:jprichardson/node-jsonfile.git |
| keyv | 4.5.4 | transitive | MIT | https://github.com/jaredwray/keyv.git |
| lazy-val | 1.0.5 | transitive | MIT | develar/lazy-val |
| lilconfig | 3.1.3 | transitive | MIT | https://github.com/antonk52/lilconfig |
| lines-and-columns | 1.2.4 | transitive | MIT | https://github.com/eventualbuddha/lines-and-columns.git |
| lodash | 4.18.1 | transitive | MIT | lodash/lodash |
| lowercase-keys | 2.0.0 | transitive | MIT | sindresorhus/lowercase-keys |
| lru-cache | 6.0.0 | transitive | ISC | git://github.com/isaacs/node-lru-cache.git |
| matcher | 3.0.0 | transitive | MIT | sindresorhus/matcher |
| math-intrinsics | 1.1.0 | transitive | MIT | https://github.com/es-shims/math-intrinsics.git |
| merge2 | 1.4.1 | transitive | MIT | git@github.com:teambition/merge2.git |
| micromatch | 4.0.8 | transitive | MIT | micromatch/micromatch |
| mime | 2.6.0 | transitive | MIT | https://github.com/broofa/mime |
| mime-db | 1.52.0 | transitive | MIT | jshttp/mime-db |
| mime-types | 2.1.35 | transitive | MIT | jshttp/mime-types |
| mimic-response | 1.0.1 | transitive | MIT | sindresorhus/mimic-response |
| minimatch | 10.2.5 | transitive | BlueOak-1.0.0 | git@github.com:isaacs/minimatch |
| minimist | 1.2.8 | transitive | MIT | git://github.com/minimistjs/minimist.git |
| minipass | 7.1.3 | transitive | BlueOak-1.0.0 | https://github.com/isaacs/minipass |
| minizlib | 3.1.0 | transitive | MIT | https://github.com/isaacs/minizlib.git |
| mkdirp | 0.5.6 | transitive | MIT | https://github.com/substack/node-mkdirp.git |
| ms | 2.1.3 | transitive | MIT | vercel/ms |
| mz | 2.7.0 | transitive | MIT | normalize/mz |
| nanoid | 3.3.15 | transitive | MIT | ai/nanoid |
| node-abi | 4.33.0 | transitive | MIT | https://github.com/electron/node-abi.git |
| node-abi/node_modules/semver | 7.8.5 | transitive | ISC | https://github.com/npm/node-semver.git |
| node-api-version | 0.2.1 | transitive | MIT | https://github.com/timfish/node-api-version |
| node-api-version/node_modules/semver | 7.8.5 | transitive | ISC | https://github.com/npm/node-semver.git |
| node-gyp | 12.4.0 | transitive | MIT | git://github.com/nodejs/node-gyp.git |
| node-gyp/node_modules/isexe | 4.0.0 | transitive | BlueOak-1.0.0 | https://github.com/isaacs/isexe |
| node-gyp/node_modules/semver | 7.8.5 | transitive | ISC | https://github.com/npm/node-semver.git |
| node-gyp/node_modules/which | 6.0.1 | transitive | ISC | https://github.com/npm/node-which.git |
| node-int64 | 0.4.0 | transitive | MIT | https://github.com/broofa/node-int64 |
| node-releases | 2.0.50 | transitive | MIT | https://github.com/chicoxyzzy/node-releases.git |
| nopt | 9.0.0 | transitive | ISC | https://github.com/npm/nopt.git |
| normalize-path | 3.0.0 | transitive | MIT | jonschlinkert/normalize-path |
| normalize-url | 6.1.0 | transitive | MIT | sindresorhus/normalize-url |
| object-assign | 4.1.1 | transitive | MIT | sindresorhus/object-assign |
| object-hash | 3.0.0 | transitive | MIT | https://github.com/puleos/object-hash |
| object-keys | 1.1.1 | transitive | MIT | git://github.com/ljharb/object-keys.git |
| once | 1.4.0 | transitive | ISC | git://github.com/isaacs/once |
| p-cancelable | 2.1.1 | transitive | MIT | sindresorhus/p-cancelable |
| p-limit | 3.1.0 | transitive | MIT | sindresorhus/p-limit |
| path-is-absolute | 1.0.1 | transitive | MIT | sindresorhus/path-is-absolute |
| path-key | 3.1.1 | transitive | MIT | sindresorhus/path-key |
| path-parse | 1.0.7 | transitive | MIT | https://github.com/jbgutierrez/path-parse.git |
| pe-library | 0.4.1 | transitive | MIT | https://github.com/jet2jet/pe-library-js.git |
| pend | 1.2.0 | transitive | MIT | git://github.com/andrewrk/node-pend.git |
| picocolors | 1.1.1 | transitive | ISC | alexeyraspopov/picocolors |
| picomatch | 2.3.2 | transitive | MIT | micromatch/picomatch |
| pify | 2.3.0 | transitive | MIT | sindresorhus/pify |
| pirates | 4.0.7 | transitive | MIT | https://github.com/danez/pirates.git |
| pkijs | 3.4.0 | transitive | BSD-3-Clause | git://github.com/PeculiarVentures/PKI.js.git |
| pkijs/node_modules/@noble/hashes | 1.4.0 | transitive | MIT | https://github.com/paulmillr/noble-hashes.git |
| plist | 3.1.0 | transitive | MIT | git://github.com/TooTallNate/node-plist.git |
| postcss | 8.5.16 | development direct | MIT | postcss/postcss |
| postcss-import | 15.1.0 | transitive | MIT | https://github.com/postcss/postcss-import.git |
| postcss-js | 4.1.0 | transitive | MIT | postcss/postcss-js |
| postcss-load-config | 6.0.1 | transitive | MIT | postcss/postcss-load-config |
| postcss-nested | 6.2.0 | transitive | MIT | postcss/postcss-nested |
| postcss-selector-parser | 6.1.4 | transitive | MIT | https://github.com/postcss/postcss-selector-parser.git |
| postcss-value-parser | 4.2.0 | transitive | MIT | https://github.com/TrySound/postcss-value-parser.git |
| postject | 1.0.0-alpha.6 | transitive | MIT | git@github.com:nodejs/postject.git |
| postject/node_modules/commander | 9.5.0 | transitive | MIT | https://github.com/tj/commander.js.git |
| proc-log | 6.1.0 | transitive | ISC | https://github.com/npm/proc-log.git |
| process-nextick-args | 2.0.1 | transitive | MIT | https://github.com/calvinmetcalf/process-nextick-args.git |
| progress | 2.0.3 | transitive | MIT | git://github.com/visionmedia/node-progress |
| promise-retry | 2.0.1 | transitive | MIT | git://github.com/IndigoUnited/node-promise-retry.git |
| proper-lockfile | 4.1.2 | transitive | MIT | git@github.com:moxystudio/node-proper-lockfile.git |
| pump | 3.0.4 | transitive | MIT | git://github.com/mafintosh/pump.git |
| pvtsutils | 1.3.6 | transitive | MIT | https://github.com/PeculiarVentures/pvtsutils |
| pvutils | 1.1.5 | transitive | MIT | https://github.com/PeculiarVentures/pvutils.git |
| queue-microtask | 1.2.3 | transitive | MIT | git://github.com/feross/queue-microtask.git |
| quick-lru | 5.1.1 | transitive | MIT | sindresorhus/quick-lru |
| read-binary-file-arch | 1.0.6 | transitive | MIT | ssh://git@github.com/samuelmaddock/read-binary-file-arch.git |
| read-cache | 1.0.0 | transitive | MIT | https://github.com/TrySound/read-cache.git |
| readable-stream | 2.3.8 | transitive | MIT | git://github.com/nodejs/readable-stream |
| readdirp | 3.6.0 | transitive | MIT | git://github.com/paulmillr/readdirp.git |
| require-directory | 2.1.1 | transitive | MIT | git://github.com/troygoode/node-require-directory.git |
| require-from-string | 2.0.2 | transitive | MIT | floatdrop/require-from-string |
| resedit | 1.7.2 | transitive | MIT | https://github.com/jet2jet/resedit-js.git |
| resolve | 1.22.12 | transitive | MIT | ssh://github.com/browserify/resolve.git |
| resolve-alpn | 1.2.1 | transitive | MIT | https://github.com/szmarczak/resolve-alpn.git |
| responselike | 2.0.1 | transitive | MIT | https://github.com/sindresorhus/responselike.git |
| retry | 0.12.0 | transitive | MIT | git://github.com/tim-kos/node-retry.git |
| reusify | 1.1.0 | transitive | MIT | https://github.com/mcollina/reusify.git |
| rimraf | 2.6.3 | transitive | ISC | git://github.com/isaacs/rimraf.git |
| roarr | 2.15.4 | transitive | BSD-3-Clause | git@github.com:gajus/roarr.git |
| run-parallel | 1.2.0 | transitive | MIT | git://github.com/feross/run-parallel.git |
| safe-buffer | 5.1.2 | transitive | MIT | git://github.com/feross/safe-buffer.git |
| sanitize-filename | 1.6.4 | transitive | WTFPL OR ISC | git@github.com:parshap/node-sanitize-filename.git |
| sax | 1.6.0 | transitive | BlueOak-1.0.0 | ssh://git@github.com/isaacs/sax-js.git |
| semver | 6.3.1 | transitive | ISC | https://github.com/npm/node-semver.git |
| semver-compare | 1.0.0 | transitive | MIT | git://github.com/substack/semver-compare.git |
| serialize-error | 7.0.1 | transitive | MIT | sindresorhus/serialize-error |
| shebang-command | 2.0.0 | transitive | MIT | kevva/shebang-command |
| shebang-regex | 3.0.0 | transitive | MIT | sindresorhus/shebang-regex |
| signal-exit | 3.0.7 | transitive | ISC | https://github.com/tapjs/signal-exit.git |
| simple-update-notifier | 2.0.0 | transitive | MIT | https://github.com/alexbrazier/simple-update-notifier.git |
| simple-update-notifier/node_modules/semver | 7.8.5 | transitive | ISC | https://github.com/npm/node-semver.git |
| source-map | 0.6.1 | transitive | BSD-3-Clause | http://github.com/mozilla/source-map.git |
| source-map-js | 1.2.1 | transitive | BSD-3-Clause | 7rulnik/source-map-js |
| source-map-support | 0.5.21 | transitive | MIT | https://github.com/evanw/node-source-map-support |
| sprintf-js | 1.1.3 | transitive | BSD-3-Clause | https://github.com/alexei/sprintf.js.git |
| stat-mode | 1.0.0 | transitive | MIT | git://github.com/TooTallNate/stat-mode.git |
| string_decoder | 1.1.1 | transitive | MIT | git://github.com/nodejs/string_decoder.git |
| string-width | 4.2.3 | transitive | MIT | sindresorhus/string-width |
| strip-ansi | 6.0.1 | transitive | MIT | chalk/strip-ansi |
| sucrase | 3.35.1 | transitive | MIT | https://github.com/alangpierce/sucrase.git |
| sucrase/node_modules/commander | 4.1.1 | transitive | MIT | https://github.com/tj/commander.js.git |
| sumchecker | 3.0.1 | transitive | Apache-2.0 | https://github.com/malept/sumchecker.git |
| supports-color | 7.2.0 | transitive | MIT | chalk/supports-color |
| supports-preserve-symlinks-flag | 1.0.0 | transitive | MIT | https://github.com/inspect-js/node-supports-preserve-symlinks-flag.git |
| tailwindcss | 3.4.19 | development direct | MIT | https://github.com/tailwindlabs/tailwindcss.git#v3 |
| tailwindcss/node_modules/jiti | 1.21.7 | transitive | MIT | unjs/jiti |
| tar | 7.5.19 | transitive | BlueOak-1.0.0 | https://github.com/isaacs/node-tar.git |
| tar/node_modules/yallist | 5.0.0 | transitive | BlueOak-1.0.0 | https://github.com/isaacs/yallist.git |
| temp | 0.9.4 | transitive | MIT | git://github.com/bruce/node-temp.git |
| temp-file | 3.4.0 | transitive | MIT | develar/temp-file |
| temp-file/node_modules/fs-extra | 10.1.0 | transitive | MIT | https://github.com/jprichardson/node-fs-extra |
| temp-file/node_modules/jsonfile | 6.2.1 | transitive | MIT | git@github.com:jprichardson/node-jsonfile.git |
| temp-file/node_modules/universalify | 2.0.1 | transitive | MIT | https://github.com/RyanZim/universalify.git |
| thenify | 3.3.1 | transitive | MIT | thenables/thenify |
| thenify-all | 1.6.0 | transitive | MIT | thenables/thenify-all |
| tiny-async-pool | 1.3.0 | transitive | MIT | git@github.com:rxaviers/async-pool.git |
| tiny-async-pool/node_modules/semver | 5.7.2 | transitive | ISC | https://github.com/npm/node-semver.git |
| tinyglobby | 0.2.17 | transitive | MIT | https://github.com/SuperchupuDev/tinyglobby.git |
| tinyglobby/node_modules/fdir | 6.5.0 | transitive | MIT | https://github.com/thecodrr/fdir.git |
| tinyglobby/node_modules/picomatch | 4.0.5 | transitive | MIT | micromatch/picomatch |
| tmp | 0.2.7 | transitive | MIT | https://github.com/raszi/node-tmp.git |
| tmp-promise | 3.0.3 | transitive | MIT | git://github.com/benjamingr/tmp-promise.git |
| to-regex-range | 5.0.1 | transitive | MIT | micromatch/to-regex-range |
| truncate-utf8-bytes | 1.0.2 | transitive | WTFPL | https://github.com/parshap/truncate-utf8-bytes.git |
| ts-interface-checker | 0.1.13 | transitive | Apache-2.0 | https://github.com/gristlabs/ts-interface-checker |
| tslib | 2.8.1 | transitive | 0BSD | https://github.com/Microsoft/tslib.git |
| type-fest | 0.13.1 | transitive | (MIT OR CC0-1.0) | sindresorhus/type-fest |
| typescript | 5.9.3 | development direct | Apache-2.0 | https://github.com/microsoft/TypeScript.git |
| undici | 6.27.0 | transitive | MIT | https://github.com/nodejs/undici.git |
| undici-types | 7.18.2 | transitive | MIT | https://github.com/nodejs/undici.git |
| universalify | 0.1.2 | transitive | MIT | https://github.com/RyanZim/universalify.git |
| unzipper | 0.12.5 | transitive | MIT | https://github.com/ZJONSSON/node-unzipper.git |
| unzipper/node_modules/fs-extra | 11.3.1 | transitive | MIT | https://github.com/jprichardson/node-fs-extra |
| unzipper/node_modules/jsonfile | 6.2.1 | transitive | MIT | git@github.com:jprichardson/node-jsonfile.git |
| unzipper/node_modules/universalify | 2.0.1 | transitive | MIT | https://github.com/RyanZim/universalify.git |
| update-browserslist-db | 1.2.3 | transitive | MIT | browserslist/update-db |
| utf8-byte-length | 1.0.5 | transitive | (WTFPL OR MIT) | https://github.com/parshap/utf8-byte-length.git |
| util-deprecate | 1.0.2 | transitive | MIT | git://github.com/TooTallNate/util-deprecate.git |
| webcrypto-core | 1.9.2 | transitive | MIT | https://github.com/PeculiarVentures/webcrypto-core |
| which | 5.0.0 | transitive | ISC | https://github.com/npm/node-which.git |
| wrap-ansi | 7.0.0 | transitive | MIT | chalk/wrap-ansi |
| wrappy | 1.0.2 | transitive | ISC | https://github.com/npm/wrappy |
| xmlbuilder | 15.1.1 | transitive | MIT | git://github.com/oozcitak/xmlbuilder-js.git |
| y18n | 5.0.8 | transitive | ISC | yargs/y18n |
| yallist | 4.0.0 | transitive | ISC | https://github.com/isaacs/yallist.git |
| yargs | 17.7.3 | transitive | MIT | https://github.com/yargs/yargs.git |
| yargs-parser | 21.1.1 | transitive | ISC | https://github.com/yargs/yargs-parser.git |
| yauzl | 2.10.0 | transitive | MIT | https://github.com/thejoshwolfe/yauzl.git |
| yocto-queue | 0.1.0 | transitive | MIT | sindresorhus/yocto-queue |

## Direct Dependency License Texts

The following texts are copied from the installed direct dependency packages in `electron-ui/node_modules` at the versions recorded above. Transitive package license files can be inspected after running `npm install` in `electron-ui/`; their declared SPDX license identifiers are listed in the inventory above.

### electron 37.10.3

Declared license: MIT

```text
Copyright (c) Electron contributors
Copyright (c) 2013-2020 GitHub Inc.

Permission is hereby granted, free of charge, to any person obtaining
a copy of this software and associated documentation files (the
"Software"), to deal in the Software without restriction, including
without limitation the rights to use, copy, modify, merge, publish,
distribute, sublicense, and/or sell copies of the Software, and to
permit persons to whom the Software is furnished to do so, subject to
the following conditions:

The above copyright notice and this permission notice shall be
included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
```

### htmx.org 2.0.10

Declared license: 0BSD

```text
Zero-Clause BSD
=============

Permission to use, copy, modify, and/or distribute this software for
any purpose with or without fee is hereby granted.

THE SOFTWARE IS PROVIDED “AS IS” AND THE AUTHOR DISCLAIMS ALL
WARRANTIES WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES
OF MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE
FOR ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY
DAMAGES WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN
AN ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT
OF OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.
```

### tailwindcss 3.4.19

Declared license: MIT

```text
MIT License

Copyright (c) Tailwind Labs, Inc.

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
```

### typescript 5.9.3

Declared license: Apache-2.0

```text
Apache License

Version 2.0, January 2004

http://www.apache.org/licenses/ 

TERMS AND CONDITIONS FOR USE, REPRODUCTION, AND DISTRIBUTION

1. Definitions.

"License" shall mean the terms and conditions for use, reproduction, and distribution as defined by Sections 1 through 9 of this document.

"Licensor" shall mean the copyright owner or entity authorized by the copyright owner that is granting the License.

"Legal Entity" shall mean the union of the acting entity and all other entities that control, are controlled by, or are under common control with that entity. For the purposes of this definition, "control" means (i) the power, direct or indirect, to cause the direction or management of such entity, whether by contract or otherwise, or (ii) ownership of fifty percent (50%) or more of the outstanding shares, or (iii) beneficial ownership of such entity.

"You" (or "Your") shall mean an individual or Legal Entity exercising permissions granted by this License.

"Source" form shall mean the preferred form for making modifications, including but not limited to software source code, documentation source, and configuration files.

"Object" form shall mean any form resulting from mechanical transformation or translation of a Source form, including but not limited to compiled object code, generated documentation, and conversions to other media types.

"Work" shall mean the work of authorship, whether in Source or Object form, made available under the License, as indicated by a copyright notice that is included in or attached to the work (an example is provided in the Appendix below).

"Derivative Works" shall mean any work, whether in Source or Object form, that is based on (or derived from) the Work and for which the editorial revisions, annotations, elaborations, or other modifications represent, as a whole, an original work of authorship. For the purposes of this License, Derivative Works shall not include works that remain separable from, or merely link (or bind by name) to the interfaces of, the Work and Derivative Works thereof.

"Contribution" shall mean any work of authorship, including the original version of the Work and any modifications or additions to that Work or Derivative Works thereof, that is intentionally submitted to Licensor for inclusion in the Work by the copyright owner or by an individual or Legal Entity authorized to submit on behalf of the copyright owner. For the purposes of this definition, "submitted" means any form of electronic, verbal, or written communication sent to the Licensor or its representatives, including but not limited to communication on electronic mailing lists, source code control systems, and issue tracking systems that are managed by, or on behalf of, the Licensor for the purpose of discussing and improving the Work, but excluding communication that is conspicuously marked or otherwise designated in writing by the copyright owner as "Not a Contribution."

"Contributor" shall mean Licensor and any individual or Legal Entity on behalf of whom a Contribution has been received by Licensor and subsequently incorporated within the Work.

2. Grant of Copyright License. Subject to the terms and conditions of this License, each Contributor hereby grants to You a perpetual, worldwide, non-exclusive, no-charge, royalty-free, irrevocable copyright license to reproduce, prepare Derivative Works of, publicly display, publicly perform, sublicense, and distribute the Work and such Derivative Works in Source or Object form.

3. Grant of Patent License. Subject to the terms and conditions of this License, each Contributor hereby grants to You a perpetual, worldwide, non-exclusive, no-charge, royalty-free, irrevocable (except as stated in this section) patent license to make, have made, use, offer to sell, sell, import, and otherwise transfer the Work, where such license applies only to those patent claims licensable by such Contributor that are necessarily infringed by their Contribution(s) alone or by combination of their Contribution(s) with the Work to which such Contribution(s) was submitted. If You institute patent litigation against any entity (including a cross-claim or counterclaim in a lawsuit) alleging that the Work or a Contribution incorporated within the Work constitutes direct or contributory patent infringement, then any patent licenses granted to You under this License for that Work shall terminate as of the date such litigation is filed.

4. Redistribution. You may reproduce and distribute copies of the Work or Derivative Works thereof in any medium, with or without modifications, and in Source or Object form, provided that You meet the following conditions:

You must give any other recipients of the Work or Derivative Works a copy of this License; and

You must cause any modified files to carry prominent notices stating that You changed the files; and

You must retain, in the Source form of any Derivative Works that You distribute, all copyright, patent, trademark, and attribution notices from the Source form of the Work, excluding those notices that do not pertain to any part of the Derivative Works; and

If the Work includes a "NOTICE" text file as part of its distribution, then any Derivative Works that You distribute must include a readable copy of the attribution notices contained within such NOTICE file, excluding those notices that do not pertain to any part of the Derivative Works, in at least one of the following places: within a NOTICE text file distributed as part of the Derivative Works; within the Source form or documentation, if provided along with the Derivative Works; or, within a display generated by the Derivative Works, if and wherever such third-party notices normally appear. The contents of the NOTICE file are for informational purposes only and do not modify the License. You may add Your own attribution notices within Derivative Works that You distribute, alongside or as an addendum to the NOTICE text from the Work, provided that such additional attribution notices cannot be construed as modifying the License. You may add Your own copyright statement to Your modifications and may provide additional or different license terms and conditions for use, reproduction, or distribution of Your modifications, or for any such Derivative Works as a whole, provided Your use, reproduction, and distribution of the Work otherwise complies with the conditions stated in this License.

5. Submission of Contributions. Unless You explicitly state otherwise, any Contribution intentionally submitted for inclusion in the Work by You to the Licensor shall be under the terms and conditions of this License, without any additional terms or conditions. Notwithstanding the above, nothing herein shall supersede or modify the terms of any separate license agreement you may have executed with Licensor regarding such Contributions.

6. Trademarks. This License does not grant permission to use the trade names, trademarks, service marks, or product names of the Licensor, except as required for reasonable and customary use in describing the origin of the Work and reproducing the content of the NOTICE file.

7. Disclaimer of Warranty. Unless required by applicable law or agreed to in writing, Licensor provides the Work (and each Contributor provides its Contributions) on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied, including, without limitation, any warranties or conditions of TITLE, NON-INFRINGEMENT, MERCHANTABILITY, or FITNESS FOR A PARTICULAR PURPOSE. You are solely responsible for determining the appropriateness of using or redistributing the Work and assume any risks associated with Your exercise of permissions under this License.

8. Limitation of Liability. In no event and under no legal theory, whether in tort (including negligence), contract, or otherwise, unless required by applicable law (such as deliberate and grossly negligent acts) or agreed to in writing, shall any Contributor be liable to You for damages, including any direct, indirect, special, incidental, or consequential damages of any character arising as a result of this License or out of the use or inability to use the Work (including but not limited to damages for loss of goodwill, work stoppage, computer failure or malfunction, or any and all other commercial damages or losses), even if such Contributor has been advised of the possibility of such damages.

9. Accepting Warranty or Additional Liability. While redistributing the Work or Derivative Works thereof, You may choose to offer, and charge a fee for, acceptance of support, warranty, indemnity, or other liability obligations and/or rights consistent with this License. However, in accepting such obligations, You may act only on Your own behalf and on Your sole responsibility, not on behalf of any other Contributor, and only if You agree to indemnify, defend, and hold each Contributor harmless for any liability incurred by, or claims asserted against, such Contributor by reason of your accepting any such warranty or additional liability.

END OF TERMS AND CONDITIONS
```

### postcss 8.5.16

Declared license: MIT

```text
The MIT License (MIT)

Copyright 2013 Andrey Sitnik <andrey@sitnik.es>

Permission is hereby granted, free of charge, to any person obtaining a copy of
this software and associated documentation files (the "Software"), to deal in
the Software without restriction, including without limitation the rights to
use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of
the Software, and to permit persons to whom the Software is furnished to do so,
subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS
FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR
COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER
IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
```

### autoprefixer 10.5.2

Declared license: MIT

```text
The MIT License (MIT)

Copyright 2013 Andrey Sitnik <andrey@sitnik.es>

Permission is hereby granted, free of charge, to any person obtaining a copy of
this software and associated documentation files (the "Software"), to deal in
the Software without restriction, including without limitation the rights to
use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of
the Software, and to permit persons to whom the Software is furnished to do so,
subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS
FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR
COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER
IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
```

### electron-builder 26.15.3

Declared license: MIT

```text
The MIT License (MIT)

Copyright (c) 2015 Loopline Systems

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
```

### @types/node 24.13.2

Declared license: MIT

```text
MIT License

    Copyright (c) Microsoft Corporation.

    Permission is hereby granted, free of charge, to any person obtaining a copy
    of this software and associated documentation files (the "Software"), to deal
    in the Software without restriction, including without limitation the rights
    to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
    copies of the Software, and to permit persons to whom the Software is
    furnished to do so, subject to the following conditions:

    The above copyright notice and this permission notice shall be included in all
    copies or substantial portions of the Software.

    THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
    IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
    FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
    AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
    LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
    OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
    SOFTWARE
```

## Model License Note

The bundled Depth Anything V2 Small Core ML model is identified by its model card as Apache-2.0. The upstream Depth Anything V2 repository also carries the Apache License 2.0. The model is not relicensed by this repository's LICENSE; it remains under its upstream Apache-2.0 terms. The Apache-2.0 text is included above in the TypeScript direct dependency license section, and the canonical text is published at https://www.apache.org/licenses/LICENSE-2.0. If the bundled model is replaced with another model variant or source, update this notice because other Depth Anything V2 variants may use different terms.
