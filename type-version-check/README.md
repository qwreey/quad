# qwreey/type_version_check

Compile-time version pattern matching for string literal types, used by **quad**, not quad-specific. `CheckVersion<Actual, Pattern>` compares a version literal against glob (`*`) / caret (`N^`) patterns; SemVer prerelease and build tails are handled (see the source header for the rules).

Part of the [quad](https://github.com/qwreey/quad) monorepo. Documentation (Korean): [`docs/`](https://github.com/qwreey/quad/tree/main/docs) — start at [왜 Quad인가](https://github.com/qwreey/quad/blob/main/docs/overview/01-why-quad.md) and [설치](https://github.com/qwreey/quad/blob/main/docs/getting-started/00-installation.md).

License: MIT.
