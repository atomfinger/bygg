# Bygg - The Gleam Initializr

> **Very experimental - things might not work as intended**

Project scaffolding for [Gleam](https://gleam.run) inspired by [the Spring Initializr](https://start.spring.io/). Pick a name, select dependencies from a curated catalog, and get a ready-to-run project with `gleam.toml`, starter source code, tests, and optional Docker/config files — all wired up correctly for the selected profile.

## Requirements

- [Gleam](https://gleam.run) >= 1.15
- Erlang/OTP >= 26
- [mise](https://mise.jdx.dev) (optional, for task running)

## Installation

Bygg is not yet published to Hex. Build from source:

```sh
git clone <repo>
cd bygg/packages/cli
gleam build
```

Run via:

```sh
gleam run -m bygg_cli -- <command> [flags]
```

Or use the `mise` tasks from the repo root:

```sh
mise run run-cli -- new my_app --dep=wisp,mist,pog
```

## Commands

### `new`

Scaffold a new Gleam project.

```
bygg new <name> [flags]
```

| Flag | Default | Description |
|---|---|---|
| `--name` | first positional arg | Project name |
| `--version` | `1.0.0` | Package version |
| `--description` | — | Short project description |
| `--target` | `erlang` | Compilation target: `erlang` or `javascript` |
| `--licence` | — | SPDX licence identifier (repeatable) |
| `--gleam` | `>= 1.16.0 and < 2.0.0` | Gleam version constraint |
| `--dep` | — | Runtime dependency by catalog name (repeatable) |
| `--dev-dep` | — | Dev dependency by catalog name (repeatable) |
| `--outdir` | `./<name>` | Output directory |

**Examples:**

```sh
# Minimal Erlang app
bygg new my_app

# Web server with SQLite
bygg new my_api --dep=wisp,mist,sqlight

# Lustre browser SPA (JavaScript target)
bygg new my_spa --target=javascript --dep=lustre

# Lustre server component
bygg new my_lsc --dep=lustre_server_component,wisp,mist
```

### `list-deps`

List all packages available in the catalog for a given target.

```
bygg list-deps [--target erlang|javascript]
```

## What gets generated

| File | Always | Condition |
|---|---|---|
| `gleam.toml` | yes | |
| `src/<name>.gleam` | yes | |
| `test/<name>_test.gleam` | yes | |
| `.gitignore` | yes | |
| `README.md` | yes | |
| `src/<name>/config.gleam` | | dep with config fields (e.g. `pog`) |
| `src/<name>/context.gleam` | | web server or Lustre server component with context fields |
| `.env.example` | | dep with environment variables |
| `docker-compose.yml` | | dep with Docker services, or Erlang web app |
| `Dockerfile` | | Erlang web server or Lustre server component |

## Application profiles

The generated starter code adapts to the selected dependencies:

| Profile | Triggered by |
|---|---|
| `BasicApp` | no special deps |
| `WebServer` | `wisp` + `mist` |
| `BrowserApp` | `lustre` (browser) |
| `LustreComponent` | `lustre_component` |
| `LustreServerComponent` | `lustre_server_component` + a web server |

Conflicting profiles (e.g. `lustre` browser app combined with `wisp`) are rejected with an error.

## Monorepo structure

| Package | Path | Notes |
|---|---|---|
| `core` | `packages/core/` | Catalog, generator, templates, TOML serializer — pure Gleam, both targets |
| `cli` | `packages/cli/` | `glint`-based CLI, `simplifile` output — Erlang target |
| `web` | `packages/web/` | Lustre SPA frontend — planned, not yet implemented |

## Adding a package to the catalog

1. Add a `Package(...)` entry in [`packages/core/src/bygg/catalog.gleam`](packages/core/src/bygg/catalog.gleam), or create `catalog/my_package.gleam` for packages with complex code blocks.
2. Populate `code_blocks` with the appropriate slots (`Import`, `ConfigField`, `MainBody`, `DockerService`, etc.).
3. Run `gleam test` — it will fail if snapshots changed.
4. Run `gleam run -m birdie accept` to approve new snapshots.

## Development

```sh
mise run test                                          # run all tests
mise run run-cli -- new my_app --dep=wisp,mist,sqlight    # smoke test the CLI
gleam run -m birdie accept                             # approve changed snapshots
mise run clean                                         # delete build artefacts
```
