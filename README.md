# Resolving package.exports array target

## Background

ESM can define an array as the exports target:

```json
{
  "exports": {
    ".": [
      "-bad-specifier-",
      "./non-existent.js",
      "./existent.js"
    ]
  }
}
```

Given only `./existent.js` is on disk, `enhanced-resolved` will resolve to `./existent.js` while Node.js will throw a "`./non-existent.js` not found" error.

## Explanation

The [ESM specification](https://nodejs.org/api/esm.html#resolution-algorithm-specification) states the following:

```
PACKAGE_TARGET_RESOLVE(packageURL, target, patternMatch, isImports, conditions)
...
3. Otherwise, if target is an Array, then
...
  2. For each item targetValue in target, do
    1. Let resolved be the result of PACKAGE_TARGET_RESOLVE( packageURL, targetValue, patternMatch, isImports, conditions), continuing the loop on any Invalid Package Target error.
```

Notice the last line `continuing the loop on any Invalid Package Target error.`.

"Invalid Package Target Error" does not mean "File not Found".

This means the above package.json should yield `./non-existent.js` instead of `./existent.js`.

The reason for this is that [`exports` is designed to resolve unambiguously without hitting the disk](https://github.com/nodejs/node/issues/37928#issuecomment-808833604).

Also documented by [here](https://github.com/privatenumber/resolve-pkg-maps#why-do-the-apis-return-an-array-of-paths):

> Node.js's implementation picks the first valid path (without attempting to resolve it) and throws an error if it can't be resolved. Node.js's fallback array is designed for forward compatibility with features (e.g. protocols) that can be syntactically validated:

### enhanced-resolved

As [documented on the Webpack website](https://webpack.js.org/guides/package-exports/#alternatives):

> Instead of providing a single result, the package author may provide a list of results. In such a scenario this list is tried in order and the first valid result will be used.

---

At the moment of writing, I have yet to find a legitimate use case for this feature,
but the behavior from Webpack will lead to people setting up their exports array for some use cases that can break future compatibility.

We have already seen this with the [browser field](https://github.com/defunctzombie/package-browser-field-spec).

---

All build tools has been reported with the same problem with the same discussions over and over again, linking to the issues:

* [vite](https://github.com/vitejs/vite/issues/4439) - conforms to spec ✔
* [esbuild](https://github.com/evanw/esbuild/issues/2974) - conforms to the spec ✔
* [resolve.exports](https://github.com/lukeed/resolve.exports/issues/17) - conforms to the spec ✔
* [resolve-pkg-maps](https://github.com/privatenumber/resolve-pkg-maps#why-do-the-apis-return-an-array-of-paths) - conforms to the spec ✔
* [node.js](https://github.com/nodejs/node/issues/37928)
* typescript - available in 5.0 with `moduleResolution: bundler`, does not conform to the spec according to the [implementation](https://github.com/microsoft/TypeScript/blob/fbcdb8cf4fbbbea0111a9adeb9d0d2983c088b7c/src/compiler/moduleSpecifiers.ts#L917)
* enhanced-resolve - does not conform to the spec as tested by this repo
* [rspack](https://github.com/web-infra-dev/rspack/issues/5052) - undecided

---

# Reproduce

```bash
pnpm install
bash test.sh
```

```
From Node.js:

node:internal/modules/cjs/loader:528
    throw e;
    ^

Error: Cannot find module '/test-esm-exports-array/non-existent.js'
    at createEsmNotFoundErr (node:internal/modules/cjs/loader:1070:15)
    at finalizeEsmResolution (node:internal/modules/cjs/loader:1063:15)
    at trySelf (node:internal/modules/cjs/loader:522:12)
    at Module._resolveFilename (node:internal/modules/cjs/loader:1025:24)
    at Module._load (node:internal/modules/cjs/loader:901:27)
    at Module.require (node:internal/modules/cjs/loader:1115:19)
    at require (node:internal/modules/helpers:130:18)
    at [eval]:1:1
    at Script.runInThisContext (node:vm:122:12)
    at Object.runInThisContext (node:vm:298:38) {
  code: 'MODULE_NOT_FOUND',
  path: '/test-esm-exports-array/package.json'
}

Node.js v20.5.1

----------------------------------------
From esbuild:

✘ [ERROR] Could not resolve "test-esm-exports-array"

    <stdin>:1:7:
      1 │ import('test-esm-exports-array')
        ╵        ~~~~~~~~~~~~~~~~~~~~~~~~

  The module "./non-existent.js" was not found on the file system:

    package.json:6:6:
      6 │       "./non-existent.js",
        ╵       ~~~~~~~~~~~~~~~~~~~

  You can mark the path "test-esm-exports-array" as external to exclude it from the bundle, which
  will remove this error and leave the unresolved path in the bundle. You can also add ".catch()"
  here to handle this failure at run-time instead of bundle-time.

1 error

----------------------------------------
From enhanced-resolve:

dir: /test-esm-exports-array
specifier: test-esm-exports-array
resolved:  /test-esm-exports-array/existent.js
```

Notice `enhanced-resolve` resolved to `./existent.js`, spec compliant implementations reports `./non-existent.js` not found.
