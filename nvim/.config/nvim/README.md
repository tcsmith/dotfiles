# Neovim

Personal Neovim configuration for C++ and general development.

NOTE: all the TODOs 😹 
As i switching Python from `basedpyright` to `ty` and `ruff` i realized that many of the plugins require external tools outside of Neovim. So i've only listed those tonight. You can see all the other language TODOs

## Requirements

- Neovim 0.12+
- Git

## External Tools

Some editor functionality depends on tools installed outside Neovim.

### uv

Install `uv` according to the official documentation so that it can self update

[install `uv` instructions](https://docs.astral.sh/uv/getting-started/installation/)

### Python

Install with `uv`:

```sh
uv tool install ty
uv tool install ruff
```

- `ty` — Python type checking and language server
- `ruff` — Python linting, formatting, and code actions

Verify:

```sh
ty --version
ruff --version
```

### C++

TODO

### PowerShell

TODO

### TypeScript / JavaScript

TODO

### Formatting

TODO
