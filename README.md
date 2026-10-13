# 跨平台 Neovim 配置（macOS + Linux）

一份配置，同时跑在 macOS（Intel / Apple Silicon）和 Linux（含 WSL、SSH 远程开发）。
原有使用习惯（leader = `;`、coc.nvim、nvim-tree、telescope、catppuccin）全部保留。

## 1. 部署

```bash
./install.sh --check     # 先看缺什么依赖
./install.sh --dry-run   # 预演，不写文件
./install.sh             # 备份旧配置后部署
```

脚本会把现有的 `~/.config/nvim` 整个移动到 `~/.config/nvim.bak.<时间戳>`，
再拷入新配置。回滚：

```bash
rm -rf ~/.config/nvim && mv ~/.config/nvim.bak.<时间戳> ~/.config/nvim
```

首次启动 `nvim` 会自动 clone lazy.nvim 并安装全部插件，之后用 `:Lazy` 管理。

## 2. 目录结构

```
init.lua                       入口：basic → plugins → keybindings
lua/
├── basic.lua                  与平台无关的基础设置
├── platform.lua               平台探测 + 剪贴板 / OSC 52 / node 定位
├── plugins.lua                lazy.nvim bootstrap + 插件清单
├── keybindings.lua            快捷键
├── colorscheme.lua            catppuccin（由 plugins.lua 调用）
└── plugin-config/
    ├── nvim-tree.lua
    ├── coc-nvim.lua
    ├── telescope.lua
    └── treesitter.lua
coc-settings.json              coc 全局设置
install.sh                     部署脚本
```

## 3. 平台差异处理

| 场景 | macOS | Linux（桌面） | Linux（服务器 / SSH） |
|---|---|---|---|
| 系统剪贴板 | `pbcopy` 直通，挂 `unnamedplus` | 检测到 X11 / Wayland + `xclip`/`xsel`/`wl-copy` 才挂 | 不挂外部工具，改用 OSC 52 |
| 复制到本机剪贴板 | 原生 | 原生 | `;y` 或任意 yank 自动发 OSC 52（终端需支持） |
| undo 目录 | `stdpath("state")/undo` | 同 | 同，自动 `mkdir -p` |
| node（coc 依赖） | brew 通常在 PATH | nvm / fnm / volta 不在 PATH，脚本会去常见路径里找 | 同 |
| 打开目录 | `open` | `xdg-open` | 不支持时提示 |
| 换行符 | `unix,dos` 双识别 | 同 | 同 |

其他统一项：`stdpath()` 推导所有路径、不硬编码任何绝对路径、`fileformats`、
不依赖 bash 专属语法（Windows 不在支持范围）。

## 4. 依赖

必需：`git`、`curl`、`nvim >= 0.10`（用到 `vim.uv` / `vim.lsp.get_clients`）

```bash
# macOS
brew install neovim node ripgrep fd gcc

# Debian / Ubuntu
sudo apt install neovim nodejs npm ripgrep fd-find build-essential xclip

# Fedora / RHEL
sudo dnf install neovim nodejs ripgrep fd-find gcc make xclip

# Arch
sudo pacman -S neovim nodejs ripgrep fd gcc make xclip
```

- `gcc`/`clang`：treesitter parser 编译用
- `rg`（ripgrep）：telescope live_grep 必需
- `fd`：可选，装了文件搜索更快
- `xclip` / `wl-clipboard`：Linux 图形会话下的剪贴板
- Nerd Font：nvim-web-devicons 图标（终端字体需换成 Nerd Font）

## 5. 快捷键（leader = `;`）

| 按键 | 功能 |
|---|---|
| `;;` | 开关文件树 |
| `;p` / `;fg` / `;fb` | 搜索文件 / 全文 grep / 缓冲区列表 |
| `;v` `;sh` `;sc` `;so` | 垂直分屏 / 水平分屏 / 关当前 / 关其他 |
| `;h` `;j` `;k` `;l` | 窗格跳转 |
| `;q` / `;Q` | 全部强退 / 强退当前 |
| `]b` `[b` `;bl` `;bd` `;bk` | buffer 切换 / 列表 / 关闭 / 强制关闭 |
| `gd` `gD` `gi` `gy` `gr` | 定义 / 声明 / 实现 / 类型定义 / 引用 |
| `K` / `[d` `]d` / `;d` | 悬浮文档 / 诊断跳转 / 诊断列表 |
| `;rn` / `;a` | 重命名 / 光标处修复 |
| `;f` | 格式化：优先 prettier，否则 LSP，都没有则提示 |
| `;y` | 复制到「宿主」剪贴板（OSC 52，SSH 场景可用） |
| `;ev` / `;sv` | 编辑配置 / 重载配置 |
| `;od` | 在文件管理器中打开当前目录 |
| `<C-j>` `<C-k>` / `<ESC>` | 5 行快滚 / 清除搜索高亮 |
| Tab / S-Tab / CR（插入模式） | coc 补全：下一项 / 上一项 / 确认 |

## 6. coc 扩展

`lua/plugin-config/coc-nvim.lua` 里通过 `coc_global_extensions` 自动安装：
`coc-json`、`coc-toml`、`coc-snippets`、`coc-marketplace`、`coc-clangd`、
`coc-rust-analyzer`、`coc-prettier`。

手动管理：`:CocInstall <name>` / `:CocList extensions`。
`coc-clangd` 需要系统 `clangd`，`coc-rust-analyzer` 需要 `rust-analyzer`，
`coc-prettier` 需要 `prettier`（`npm i -g prettier`）。

## 7. 常见问题

**treesitter 没高亮**：`:TSInstallInfo` 看 parser 是否已装。离线机器把
`plugin-config/treesitter.lua` 里的 `ensure_installed` 改成 `{}`，再手动 `:TSInstall python`。

**;f 提示没有格式化器**：`npm i -g prettier` 后重启，或在项目里 `npm i -D prettier`。

**Linux SSH 里复制不到本地剪贴板**：需要终端支持 OSC 52
（iTerm2 / WezTerm / Kitty / Alacritty 支持；macOS 自带 Terminal 不支持）。
本机（非 SSH）Linux 桌面请装 `xclip` 或 `wl-clipboard`。

**图标是方块**：终端字体换成 Nerd Font（如 `brew install --cask font-jetbrains-mono-nerd-font`）。

**主题切换**：`NVIM_THEME=latte nvim`（可选 latte / frappe / macchiato / mocha）。

## 8. 与旧配置（packer 版）的差异

- 插件管理器 packer → lazy.nvim（packer 已停止维护）
- 新增 `platform.lua`：平台探测、剪贴板自适应、OSC 52、node 定位、依赖体检
- `;f` 不再硬调 prettier，改为按可用性降级
- 新增 `;y` `;ev` `;sv` `;od`
- undo 目录显式创建，跨 nvim 版本不再踩坑
