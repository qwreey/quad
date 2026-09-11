# qwreey/quad_types

Public type contract of **quad** (no implementation). Backends and plugins depend on this instead of the full `quad_base`; it also carries the compile-time version-compatibility type function.

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
