# Agents Guide for dotfiles Repository

## Build, Lint, and Test Commands

- Build all tmux themes: `make build` (in `tmux-themepack` plugin)
- Run all tests: `make test` (runs `go test -count=1 -v ./...` in `test` directory)
- Run lint: `make lint` (runs `golangci-lint` in `test` directory)
- To run a single test, use `go test -run <TestName>` inside the `test` directory

## Code Style Guidelines

- **Indentation:** 2 spaces, no tabs (see vim modelines)
- **Lua code:** Use snake_case for variables, camelCase for functions
- **Imports:** Use `require` with relative paths for modular plugin configs
- **Formatting:** Use `conform.nvim` with `stylua` for Lua formatting
- **Error Handling:** Use `pcall` for optional plugin loading or extensions
- **Naming:** Descriptive names for keymaps and functions
- **Comments:** Use comments liberally to explain configuration and usage

## Plugin Configuration

- Plugins are lazy-loaded with event triggers (e.g., `VimEnter`, `BufReadPre`)
- Keymaps are set with descriptive `desc` fields for clarity

## Additional Notes

## Cursor and Copilot Rules

- No Cursor rules or Copilot instructions found in the repo
- Follow existing patterns in `nvim/lua/kickstart/plugins` for new plugin configs

## Install Script Design Blueprint

- Modular script structure for easy extension to other apps
- Idempotent operations to avoid redundant installs or changes
- Environment and dependency checks before proceeding
- Clear, informative logging and user feedback during install
- Use of standard shell tools and minimal external dependencies
- Consistent error handling and exit codes for reliability

---

This file is intended to guide autonomous agents working in this repository.
