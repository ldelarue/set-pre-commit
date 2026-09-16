# set-pre-commit

`set-pre-commit` installs opinionated [hk](https://hk.jdx.dev/) configuration in an existing Git repository. It generates a version-pinned `hk.pkl`, registers hk in the project's `mise.toml`, validates the configuration, and installs repository-local hooks.

It does not replace existing hk configuration or Git hooks.

## Quick start

Install [mise](https://mise.jdx.dev/), then run the script from a Git repository:

```sh
curl -fsSL <versioned-release-asset-url>/set-pre-commit | sh -s -- init python
```

Commit the generated files so collaborators receive the same tool and hook configuration:

```sh
git add hk.pkl mise.toml
git commit -m "build: configure hk checks"
```

Each clone installs its local hooks by running the initializer or:

```sh
mise install
mise exec -- hk install --mise
```

Replace `<versioned-release-asset-url>` with the immutable URL published by this repository's release workflow once a GitHub remote is configured.

## Profiles

### `code`

Installs a `commit-msg` hook using hk's built-in Conventional Commit validator. It accepts Conventional Commit messages such as `feat(parser): support TOML` and rejects invalid formats.

```sh
set-pre-commit init code
```

### `python`

Includes `code` and configures:

- Ruff linting and formatting
- ty type checking
- pytest before committing Python or Python project configuration changes

```sh
set-pre-commit init python
```

The hk builtins configure commands but do not install Ruff, ty, or pytest. Declare those tools in `mise.toml` or in the Python project's package configuration.

## CLI reference

```text
set-pre-commit init code
set-pre-commit init python
set-pre-commit render python
set-pre-commit list
set-pre-commit --help
set-pre-commit --version
```

`render` writes a profile to standard output without requiring Git or mise. It is useful for reviewing or validating generated configuration.

The initializer stops before writing when an hk project or local configuration, or a relevant hook, already exists. Resolve the configuration manually, or use `hk migrate pre-commit` when migrating a supported pre-commit framework configuration.

Git 2.54 and later can use a global launcher instead of per-repository installation:

```sh
mise exec -- hk install --global --mise
```

Repositories without hk configuration are skipped by the global launcher.

## Development

```sh
mise install
mise run check
```

The project uses POSIX shell and has no runtime dependency beyond Git, mise, and the tools selected by a profile. Copier is intentionally not used: hk already owns hook installation and Pkl provides the configuration model needed for project presets.