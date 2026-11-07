#!/bin/zsh
emulate -LR zsh
setopt ERR_EXIT NO_UNSET PIPE_FAIL
kit="${0:A:h}"
case "${1:-$(uname -m)}" in
 arm64|aarch64) arch=aarch64; digest=40d4a7da4543d75f573a5cfcc31543b0b4bf7e02caa122a9ca50654859585839 ;;
 x86_64|x64) arch=x64; digest=b1d6938680f3e411b5961e56591faaa92c95e9676f54ebfdfa98b7eab374023e ;;
 *) print -u2 '支持 arm64 或 x86_64'; exit 1 ;;
esac
name="Clash.Verge_2.5.10_${arch}.dmg"
upstream="https://github.com/clash-verge-rev/clash-verge-rev/releases/download/v2.5.10/$name"
mkdir -p "$kit/Downloads"
partial=$(mktemp "$kit/Downloads/.clash-download.XXXXXX")
trap 'rm -f -- "$partial"' EXIT
# Mirror links with upstream SHA-256 verification.
for base in https://gh-proxy.com/ https://gh-proxy.org/ ''; do
  print -r -- "下载：${base}${upstream}"
  if curl --noproxy '*' --fail --location --connect-timeout 12 --max-time 600 --retry 1 --proto '=https' --proto-redir '=https' "${base}${upstream}" -o "$partial"; then
    actual=$(shasum -a 256 "$partial"); actual="${actual%% *}"
    if [[ "$actual" == "$digest" ]]; then
      mv "$partial" "$kit/Downloads/$name"
      print -r -- "官方 SHA-256 校验通过：$kit/Downloads/$name"
      exit 0
    fi
    print -u2 '校验不匹配，放弃此下载源。'
  fi
done
print -u2 '所有下载源均不可用，请稍后重试或查看官方发布页。'
exit 1
