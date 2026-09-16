# set-pre-commit

`set-pre-commit` installs opinionated [hk](https://hk.jdx.dev/) configuration in an existing Git repository. It generates a version-pinned `hk.pkl`, registers hk with mise, validates the configuration, and installs repository-local hooks.

It never replaces an existing hk configuration or Git hook.

## Quick start

Install [mise](https://mise.jdx.dev/), enter a Git repository, then run:

```sh
curl -fsSL https://raw.githubusercontent.com/ldelarue/set-pre-commit/main/bin/set-pre-commit | sh -s -- init python
```

The repository page URL cannot be piped to `sh` because it returns HTML. Use the `raw.githubusercontent.com` URL above or a release asset.

After the first tagged release, prefer its immutable URL:

```sh
curl -fsSL https://github.com/ldelarue/set-pre-commit/releases/download/v0.1.0/set-pre-commit | sh -s -- init python
```

Commit the generated files so collaborators receive the same configuration:

```sh
git add hk.pkl mise.toml
git commit -m "build: configure hk checks"
```

Each clone installs its local hooks by running the initializer or:

```sh
mise install
mise exec -- hk install --mise
```

## Profiles

### `code`

Installs a `commit-msg` hook using hk's built-in Conventional Commit validator.

```sh
set-pre-commit init code
```

For example, `feat(parser): support TOML` is accepted while an invalid commit format is rejected.

### `python`

Includes the `code` profile and configures:

- Ruff linting and formatting
- ty type checking
- pytest before committing Python or Python project configuration changes

```sh
set-pre-commit init python
```

hk's builtins configure commands but do not install Ruff, ty, or pytest. Declare those tools in `mise.toml` or in the Python project's package configuration.

## CLI reference

```text
set-pre-commit init code
set-pre-commit init python
set-pre-commit render code
set-pre-commit render python
set-pre-commit list
set-pre-commit --help
set-pre-commit --version
```

`render` writes a profile to standard output without requiring Git or mise. It is useful for reviewing or validating generated configuration.

## Existing configuration

The initializer stops before writing when it finds:

- `hk.pkl` or `.config/hk.pkl`
- `hk.local.pkl` or `.config/hk.local.pkl`
- A relevant existing Git hook

Resolve conflicts manually. When migrating from the Python pre-commit framework, inspect `hk migrate pre-commit`.

## Global hooks

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

The project uses POSIX shell and has no runtime dependency beyond Git, mise, and the tools selected by a profile. Copier is intentionally not used: hk owns hook installation and Pkl provides the configuration model needed for project presets.
