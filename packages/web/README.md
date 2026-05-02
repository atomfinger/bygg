# bygg_web

The Bygg web UI — a browser-based project scaffolder for Gleam. Compiles to JavaScript and runs fully client-side.

## Prerequisites

- [Gleam](https://gleam.run) 1.16+
- [Node.js](https://nodejs.org) 22+
- [mise](https://mise.jdx.dev) (optional, for repo-level tasks)

## Setup

Install npm dependencies (required once before first run or after `package.json` changes):

```sh
npm install
```

## Development

Start the dev server with live reload:

```sh
gleam run -m lustre/dev start
```

The app is served at `http://localhost:1234` by default.

## Build

Produce a minified production bundle in `priv/static/`:

```sh
gleam run -m lustre/dev build --minify
```

## Format

```sh
gleam format
```

## Version

The displayed version is read from `gleam.toml`. After bumping the version field, regenerate `src/bygg_web/version.gleam` with:

```sh
mise run web-version
```

Or manually:

```sh
gleam.toml version → src/bygg_web/version.gleam
```

## Deployment

The GitHub Actions workflow (`.github/workflows/deploy-web.yml`) deploys to GitHub Pages automatically when the version in `gleam.toml` has not previously been tagged. To trigger a deploy, bump the version, run `mise run web-version`, and push to `main`.
