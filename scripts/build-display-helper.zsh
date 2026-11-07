#!/bin/zsh
emulate -LR zsh
setopt ERR_EXIT NO_UNSET PIPE_FAIL
kit="${0:A:h:h}"
destination="${1:-$HOME/Library/Application Support/aste2d macOS Kit}"
if ! xcrun --find swiftc >/dev/null 2>&1; then
  print -u2 'Hyper+Z 需要 Apple Command Line Tools。先运行 xcode-select --install，完成后重新安装配置。'
  exit 1
fi
mkdir -p "$destination"
cache=$(mktemp -d "${TMPDIR:-/tmp}/display-build.XXXXXX")
trap 'rm -rf -- "$cache"' EXIT
xcrun swiftc -module-cache-path "$cache" -target "$(uname -m)-apple-macosx15.0" -O "$kit/Sources/DetectDisplays.swift" -o "$destination/DetectDisplays.new"
codesign --force --sign - --identifier io.github.aste2d.macos-kit.detect-displays "$destination/DetectDisplays.new"
mv "$destination/DetectDisplays.new" "$destination/DetectDisplays"
"$destination/DetectDisplays" --version
