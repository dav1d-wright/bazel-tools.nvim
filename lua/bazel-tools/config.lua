local M = {}

M.defaults = {
  bazel_command = "bazel",
  query_scope = "//...",
  build_kind_filter = "rule",
  run_kind_filter = "cc_binary",
  configs = { "(default)", "dbg" },
  overseer = {
    direction = "right",  -- overseer window direction when opening
  },
  dap = {
    adapter = "cppdbg",
    build_config = "dbg",
  },
  refresh_compdb_target = "//:refresh_compile_commands",
}

M.current = vim.deepcopy(M.defaults)

function M.setup(opts)
  M.current = vim.tbl_deep_extend("force", vim.deepcopy(M.defaults), opts or {})
end

return M
