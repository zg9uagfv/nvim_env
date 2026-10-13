-- https://github.com/nvim-telescope/telescope.nvim

local ok, telescope = pcall(require, "telescope")
if not ok then
  return
end

telescope.setup({
  defaults = {
    file_ignore_patterns = {
      "node_modules",
      "%.git/",
      "%.lock$",
    },
    -- Linux 大仓库下默认排序更快
    sorting_strategy = "ascending",
    layout_config = {
      prompt_position = "top",
    },
  },
  pickers = {
    find_files = {
      -- 装了 fd 就用 fd（跨平台都有），没装自动回落到内部实现
      find_command = (vim.fn.executable("fd") == 1)
          and { "fd", "--type", "f", "--hidden", "--exclude", ".git" }
        or nil,
      hidden = true,
    },
  },
})
