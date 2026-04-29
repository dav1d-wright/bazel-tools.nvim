# bazel-tools.nvim

Bazel integration for Neovim. Select targets, build, run, and debug from within the editor using [overseer.nvim](https://github.com/stevearc/overseer.nvim) and [toggleterm.nvim](https://github.com/akinsho/toggleterm.nvim).

Designed to mirror the workflow of [cmake-tools.nvim](https://github.com/Civitasv/cmake-tools.nvim) so both build systems can share keybindings with project-type detection.

## Features

- Target selection via `bazel query` with telescope picker (async, non-blocking)
- Build and run targets through overseer tasks
- Debug with `nvim-dap` (builds with `--config=dbg`, resolves binary via `bazel cquery`)
- Refresh `compile_commands.json` (hedron/bazel-compile-commands-extractor)
- Lualine statusline components
- Persistent state across Neovim restarts (targets, config)
- Auto-discover `--config` values from `.bazelrc`
- Configurable query scope and DAP adapter

## Requirements

- Neovim >= 0.10
- [overseer.nvim](https://github.com/stevearc/overseer.nvim)
- [toggleterm.nvim](https://github.com/akinsho/toggleterm.nvim)
- [nvim-dap](https://github.com/mfussenegger/nvim-dap) (for debugging)
- [telescope.nvim](https://github.com/nvim-telescope/telescope.nvim) (optional, falls back to `vim.ui.select`)
- [codicons](https://github.com/mortepau/codicons.nvim) (for lualine components)
- Bazel installed and on `$PATH`

## Installation

### lazy.nvim

```lua
{
  "david_wright/bazel-tools.nvim",
  dependencies = { "stevearc/overseer.nvim", "akinsho/toggleterm.nvim" },
  config = function()
    require("bazel-tools").setup()
  end,
}
```

For local development:

```lua
{
  dir = "~/projects/bazel-tools.nvim",
  name = "bazel-tools.nvim",
  dependencies = { "stevearc/overseer.nvim", "akinsho/toggleterm.nvim" },
  config = function()
    require("bazel-tools").setup({
      query_scope = "//src/...",
    })
  end,
}
```

## Configuration

All options and their defaults:

```lua
require("bazel-tools").setup({
  bazel_command = "bazel",             -- bazel executable
  query_scope = "//...",               -- scope passed to `bazel query`
  build_kind_filter = "rule",          -- kind filter for build target selection
  run_kind_filter = "cc_binary",       -- kind filter for run target selection
  test_kind_filter = ".*_test",        -- kind filter for test target selection
  overseer = {
    direction = "right",               -- overseer window direction
  },
  dap = {
    adapter = "cppdbg",                -- nvim-dap adapter name
    build_config = "dbg",              -- --config used for debug builds
  },
  refresh_compdb_target = "//:refresh_compile_commands",
})
```

## Commands

| Command | Description |
|---------|-------------|
| `BazelSelectConfig` | Pick a `--config` value (default, dbg, ...) |
| `BazelSelectBuildTarget` | Pick a build target via `bazel query` |
| `BazelSelectRunTarget` | Pick a run target (`cc_binary` rules) |
| `BazelSelectTestTarget` | Pick a test target (test rules) |
| `BazelBuild` | Build the selected target |
| `BazelRun` | Run the selected target |
| `BazelTest` | Run the selected test target |
| `BazelDebug` | Build with debug config, resolve binary, launch DAP |
| `BazelRefreshCompdb` | Run `refresh_compile_commands` for clangd |
| `BazelStopExecutor` | Stop running build tasks |
| `BazelStopRunner` | Stop running run tasks |
| `BazelStopTester` | Stop running test tasks |

## Keybindings

bazel-tools.nvim does not set keybindings. Here is a suggested which-key setup that shares the `<leader>c` prefix with cmake-tools based on project detection:

```lua
local bt = require("bazel-tools")

if bt.is_bazel_project() then
  require("which-key").add({
    { "<leader>c",  group = "Bazel" },
    { "<leader>cc", "<cmd>BazelSelectConfig<cr>",      desc = "Select config" },
    { "<leader>cg", "<cmd>BazelRefreshCompdb<cr>",     desc = "Refresh compile_commands" },
    { "<leader>ct", "<cmd>BazelSelectBuildTarget<cr>", desc = "Select build target" },
    { "<leader>cb", "<cmd>wa<cr><cmd>BazelBuild<cr>",  desc = "Build" },
    { "<leader>cT", "<cmd>BazelSelectRunTarget<cr>",   desc = "Select run target" },
    { "<leader>cr", "<cmd>wa<cr><cmd>BazelRun<cr>",    desc = "Run" },
    { "<leader>cd", "<cmd>wa<cr><cmd>BazelDebug<cr>",  desc = "Debug" },
    { "<leader>cx", "<cmd>BazelSelectTestTarget<cr>",   desc = "Select test target" },
    { "<leader>cX", "<cmd>wa<cr><cmd>BazelTest<cr>",   desc = "Run test" },
    { "<leader>cs", "<cmd>BazelStopExecutor<cr>",      desc = "Stop build" },
    { "<leader>cS", "<cmd>BazelStopRunner<cr>",        desc = "Stop run" },
  })
elseif bt.is_cmake_project() then
  -- cmake-tools keybindings here
end
```

## Lualine

Add Bazel status to your statusline:

```lua
local bt_lualine = require("bazel-tools.lualine").components()

-- Insert into your lualine config
ins_left(bt_lualine.config)       -- "Bazel: [dbg]" — click to change
ins_left(bt_lualine.build_button) -- gear icon — click to build
ins_left(bt_lualine.build_target) -- "[//src/app:main]" — click to change
ins_left(bt_lualine.debug_button) -- debug icon — click to debug
ins_left(bt_lualine.run_button)   -- run icon — click to run
ins_left(bt_lualine.run_target)   -- "[//src/app:main]" — click to change
ins_left(bt_lualine.test_button)  -- "Test" — click to test
ins_left(bt_lualine.test_target)  -- "[//src/test:unit]" — click to change
```

All components are guarded by `is_bazel_project()` and only display in Bazel workspaces.

## API

```lua
local bt = require("bazel-tools")

bt.is_bazel_project()    -- true if MODULE.bazel, WORKSPACE, or WORKSPACE.bazel exists
bt.is_cmake_project()    -- true if CMakeLists.txt exists

bt.get_config()          -- current config name ("default" or "dbg")
bt.get_build_target()    -- current build target label or "[none]"
bt.get_run_target()      -- current run target label or "[none]"
bt.get_test_target()     -- current test target label or "[none]"
```

## How Debugging Works

`BazelDebug` performs three steps:

1. Builds the selected run target with `--config=<dap.build_config>` (default: `dbg`)
2. Resolves the output binary path via `bazel cquery --output=files`
3. Launches nvim-dap with the resolved binary

This requires a `.bazelrc` debug config that produces debuggable binaries:

```
build:dbg -c dbg
build:dbg --copt=-O0
build:dbg --copt=-g
build:dbg --strip=never
```

## License

MIT
