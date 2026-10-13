-- https://github.com/kyazdani42/nvim-tree.lua
require("nvim-tree").setup({
  -- 想让文件树在右边就打开这一行（mac / Linux 一致）
  -- view = { side = "right" },
  git = {
    enable = false,
  },
  filters = {
    custom = { "^\\.git$" },
  },
  -- Linux 服务器上大目录很多，避免被 .git / node_modules 拖慢
  respect_buf_cwd = true,
  update_focused_file = {
    enable = true,
  },
})
