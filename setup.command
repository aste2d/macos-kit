#!/bin/zsh
emulate -LR zsh
setopt ERR_EXIT NO_UNSET PIPE_FAIL
umask 077
kit="${0:A:h}"
case "${1:-}" in
  --apply|--services|--menu) ;;
  *) print -r -- 'aste2d macOS 整合包
先阅读 README.md 并安装 Karabiner 与对应系统版本的 Raycast（macOS 15：v1；macOS 26+：v2）。
  ./setup.command --apply     启用 Hyper 与系统快捷键，安装 Hyper+Z 显示器工具
  ./setup.command --services  设置 Keka ⌃Space、Ghostty ⌃T 服务快捷键
不传参数只显示说明。Raycast 的命令快捷键按 docs/raycast.md 设置。
  ./setup.command --menu      将 Tab 设为 Minimize 菜单快捷键'; exit 0 ;;
esac
[[ "$(uname -s)" == Darwin && $EUID != 0 ]] || { print -u2 '请以 macOS 当前用户运行，不用 sudo。'; exit 1; }
state="$HOME/Library/Application Support/aste2d macOS Kit"
backup="$state/$(date +%Y%m%d-%H%M%S)-$$"
mkdir -p "$backup"
work=$(mktemp -d "${TMPDIR:-/tmp}/macos-kit.XXXXXX")
trap 'rm -rf -- "$work"' EXIT
merge_domain() {
  local domain="$1" top="$2" source="$3"
  if ! defaults export "$domain" "$backup/$domain.plist" 2>/dev/null; then
    plutil -create xml1 "$backup/$domain.plist"
  fi
  zsh "$kit/scripts/merge-preferences.zsh" "$backup/$domain.plist" "$source" "$top" "$work/merged.plist"
  defaults write "$domain" "$top" "$(plutil -extract "$top" xml1 -o - "$work/merged.plist")"
  defaults export "$domain" "$work/readback.plist"
  [[ "$(plutil -extract "$top" xml1 -o - "$work/readback.plist")" == "$(plutil -extract "$top" xml1 -o - "$work/merged.plist")" ]] || { print -u2 '设置回读校验失败。'; exit 1; }
}
if [[ "$1" == --apply ]]; then
  zsh "$kit/scripts/build-display-helper.zsh" "$state"
  config="$HOME/.config/karabiner/karabiner.json"
  [[ ! -L "$HOME/.config/karabiner" && ! -L "$config" ]] || { print -u2 '配置使用了符号链接，请手动导入 config/karabiner-rules.json。'; exit 1; }
  mkdir -p "${config:h}"
  if [[ -f "$config" ]]; then cp "$config" "$backup/karabiner.json"; fi
  zsh "$kit/scripts/install-profile.zsh" "$config" "$kit/config/karabiner-profile.json" "$work/karabiner.json"
  cp "$work/karabiner.json" "${config}.new"
  mv "${config}.new" "$config"
  merge_domain com.apple.symbolichotkeys AppleSymbolicHotKeys "$kit/config/system-shortcuts.plist"
  defaults export NSGlobalDomain "$backup/NSGlobalDomain.plist"
  defaults write NSGlobalDomain com.apple.keyboard.fnState -bool false
  [[ "$(defaults read NSGlobalDomain com.apple.keyboard.fnState)" == 0 ]] || { print -u2 "功能键模式设置失败"; exit 1; }
  print -r -- 'Hyper 配置已启用。系统快捷键可能需要注销并重新登录后生效。'
elif [[ "$1" == --menu ]]; then
  defaults export NSGlobalDomain "$backup/NSGlobalDomain.plist"
  value=$(plutil -extract NSUserKeyEquivalents.Minimize raw -o - "$kit/config/menu-shortcuts.plist")
  defaults write NSGlobalDomain NSUserKeyEquivalents -dict-add Minimize "$value"
  print -r -- '已设置 Tab 最小化菜单快捷键。'
else
  merge_domain pbs NSServicesStatus "$kit/config/services.plist"
  print -r -- '已设置 Keka / Ghostty 服务快捷键。应用安装后才能使用。'
fi
print -r -- "原设置保存在：$backup"
