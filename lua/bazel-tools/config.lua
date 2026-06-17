local M = {}

M.defaults = {
  bazel_command = "bazel",
  query_scope = "//...",
  build_kind_filter = "rule",
  run_kind_filter = "cc_binary",
  test_kind_filter = ".*_test",
  overseer = {
    direction = "right",
  },
  dap = {
    adapter = "codelldb",
    build_config = "dbg",
  },
  telescope = {
    enabled = true,
  },
  auto_refresh = {
    enabled = false,
    debounce_ms = 2000,
  },
  refresh_targets = {
    compdb = {
      target = "//:refresh_compile_commands",
      patterns = { "*.c", "*.cc", "*.cpp", "*.cxx", "*.h", "*.hpp", "*.hxx" },
      output = "compile_commands.json",
    },
    rust_project = {
      target = "@rules_rust//tools/rust_analyzer:gen_rust_project",
      patterns = { "*.rs" },
      output = "rust-project.json",
    },
  },
  errorformat = "%f:%l:%c: %trror: %m,%f:%l:%c: %tarning: %m,%f:%l: %trror: %m,%f:%l: %tarning: %m",
}

M.current = vim.deepcopy(M.defaults)

function M.setup(opts)
  M.current = vim.tbl_deep_extend("force", vim.deepcopy(M.defaults), opts or {})
end

--- Parse .bazelrc files for --config names.
--- Looks for lines matching `build:<name>` or `common:<name>`.
function M.read_configs()
  local configs = { "(default)" }
  local seen = {}
  for _, filename in ipairs({ ".bazelrc", "user.bazelrc" }) do
    local path = vim.fn.getcwd() .. "/" .. filename
    if vim.fn.filereadable(path) == 1 then
      for line in io.lines(path) do
        local name = line:match("^%w+:(%S+)%s")
        if name and not seen[name] then
          seen[name] = true
          table.insert(configs, name)
        end
      end
    end
  end
  return configs
end

return M
