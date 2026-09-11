# qwreey/type_version_check

Compile-time version pattern matching for string literal types, used by **quad**, not quad-specific. `CheckVersion<Actual, Pattern>` compares a version literal against glob (`*`) / caret (`N^`) patterns; SemVer prerelease and build tails are handled (see the source header for the rules). The same rules are exported as a runtime function, `matchesPattern(actual, pattern)`, which is what `quad_roblox` uses to gate the installed `quad_base` version.

Part of the [quad](https://github.com/qwreey/quad) monorepo. **Documentation (Korean): <https://quad.qwreey.moe/>** — start at [설치](https://quad.qwreey.moe/getting-started/00-installation/) or [왜 Quad인가](https://quad.qwreey.moe/overview/01-why-quad/); the same text is in the repo under [`docs/`](https://github.com/qwreey/quad/tree/main/docs).

All five packages are published together at the same version — `quad_base` is the main one, and the docs show its version:

| Package | Role | You add it? |
|---|---|---|
| `qwreey/quad_base` | engine-agnostic core (reactivity + dispatch engine) | yes |
| `qwreey/quad_roblox` | Roblox backend (`D`, `Tween`/`Animate`, `OnChange`, `Claim`) | yes, for Roblox |
| `qwreey/quad_types` | public type contract (no implementation) | yes, for `--!strict` consumers |
| `qwreey/quad_error` | level-tagged error utility | no — pulled in as a dependency |
| `qwreey/type_version_check` | compile-time version pattern matching | no — pulled in as a dependency |

License: MIT.
