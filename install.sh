#!/usr/bin/env bash
#
# 跨平台 Neovim 配置部署脚本（macOS / Linux 通用）
#
#   ./install.sh              备份并部署
#   ./install.sh --dry-run    只打印将要做的事
#   ./install.sh --check      只检查依赖是否齐全
#
set -euo pipefail

SRC="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DST="${XDG_CONFIG_HOME:-$HOME/.config}/nvim"
BACKUP="${DST}.bak.$(date +%Y%m%d%H%M%S)"
DRY_RUN=0

OS="$(uname -s)"
case "$OS" in
  Darwin) PKG_HINT="brew install neovim node ripgrep fd gcc" ;;
  Linux)
    if command -v apt-get >/dev/null 2>&1; then
      PKG_HINT="sudo apt install neovim nodejs npm ripgrep fd-find build-essential xclip"
    elif command -v dnf >/dev/null 2>&1; then
      PKG_HINT="sudo dnf install neovim nodejs ripgrep fd-find gcc make xclip"
    elif command -v pacman >/dev/null 2>&1; then
      PKG_HINT="sudo pacman -S neovim nodejs ripgrep fd gcc make xclip"
    else
      PKG_HINT="请用你的发行版包管理器安装: neovim nodejs ripgrep fd gcc make xclip"
    fi
    ;;
  *) PKG_HINT="未识别的系统 $OS，请自行安装 neovim / node / ripgrep / gcc" ;;
esac

log()  { printf '%s\n' "$*"; }
run()  { if [[ $DRY_RUN -eq 1 ]]; then log "[dry-run] $*"; else eval "$*"; fi; }

check_deps() {
  local missing=()
  for bin in git curl; do
    command -v "$bin" >/dev/null 2>&1 || missing+=("$bin(必需)")
  done
  for bin in node rg fd gcc; do
    command -v "$bin" >/dev/null 2>&1 || missing+=("$bin(可选)")
  done
  if ((${#missing[@]})); then
    log "缺少: ${missing[*]}"
    log "安装建议: $PKG_HINT"
  else
    log "依赖检查通过"
  fi
}

case "${1:-}" in
  --check)   check_deps; exit 0 ;;
  --dry-run) DRY_RUN=1 ;;
  ""|--)     : ;;
  *) log "未知参数: $1"; exit 1 ;;
esac

log "系统: $OS"
log "源目录: $SRC"
log "目标:   $DST"

if [[ -e "$DST" || -L "$DST" ]]; then
  log "备份现有配置 -> $BACKUP"
  run "mv \"$DST\" \"$BACKUP\""
fi

run "mkdir -p \"$DST\""
run "cp -R \"$SRC\"/init.lua \"$SRC\"/lua \"$DST\"/"
if [[ -f "$SRC/coc-settings.json" ]]; then
  run "cp \"$SRC\"/coc-settings.json \"$DST\"/"
fi

log ""
log "部署完成。接下来："
log "  1. nvim                      # 首次启动会自动安装 lazy.nvim 与所有插件"
log "  2. :Lazy                     # 查看插件安装进度"
log "  3. :checkhealth              # 排查环境问题"
log "  4. CocInstall 见 README      # coc 扩展已配置自动安装"
log ""
check_deps
log ""
log "回滚: rm -rf \"$DST\" && mv \"$BACKUP\" \"$DST\""
