# qwreey/quad_error

Level-tagged error utility used by **quad**, not quad-specific. Tag a function with `setFuncLevel` and `errorAt`/`errorBefore` walk the stack to blame the right caller frame without counting wrapper frames by hand.

Part of the [quad](https://github.com/qwreey/quad) monorepo. **Documentation (Korean): <https://quad.qwreey.moe/>** — start at [설치](https://quad.qwreey.moe/getting-started/00-installation/) or [왜 Quad인가](https://quad.qwreey.moe/overview/01-why-quad/); the same text is in the repo under [`docs/`](https://github.com/qwreey/quad/tree/main/docs).

This package is versioned **on its own** (SemVer, see [`CHANGELOG.md`](./CHANGELOG.md)) — it was published in lockstep with quad up to 3.2.0, and 4.0.0 is its first independent release. The three quad packages below (`quad_base`, `quad_roblox`, `quad_types`) share one version; `quad_base` is the main one, and the docs show its version:

| Package | Role | You add it? |
|---|---|---|
| `qwreey/quad_base` | engine-agnostic core (reactivity + dispatch engine) | yes |
| `qwreey/quad_roblox` | Roblox backend (`D`, `Tween`/`Animate`, `OnChange`, `Claim`) | yes, for Roblox |
| `qwreey/quad_types` | public type contract (no implementation) | yes, for `--!strict` consumers |
| `qwreey/quad_error` | level-tagged error utility (own version) | no — pulled in as a dependency |
| `qwreey/type_version_check` | compile-time version pattern matching (own version) | no — pulled in as a dependency |

License: MIT.
