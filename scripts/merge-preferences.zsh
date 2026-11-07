#!/bin/zsh
# Pure merge: old plist, incoming plist, top-level dictionary key, output plist.
emulate -LR zsh
setopt ERR_EXIT NO_UNSET PIPE_FAIL
(( $# == 4 )) || exit 64
input="$1"; incoming="$2"; root="$3"; output="$4"
[[ "$input" != "$output" ]] || exit 1
/bin/cp "$input" "$output"
if ! /usr/bin/plutil -extract "$root" raw -expect dictionary -o /dev/null "$output" 2>/dev/null; then
  /usr/bin/plutil -insert "$root" -dictionary "$output"
fi
while IFS= read -r item; do
  escaped="${item//./\\.}"
  if ! /usr/bin/plutil -extract "$root.$escaped" raw -expect dictionary -o /dev/null "$output" 2>/dev/null; then
    /usr/bin/plutil -insert "$root.$escaped" -dictionary "$output"
  fi
  while IFS= read -r key; do
    safe="${key//./\\.}"
    value=$(/usr/bin/plutil -extract "$root.$escaped.$safe" xml1 -o - "$incoming")
    if /usr/bin/plutil -type "$root.$escaped.$safe" "$output" >/dev/null 2>&1; then op=-replace; else op=-insert; fi
    /usr/bin/plutil "$op" "$root.$escaped.$safe" -xml "$value" "$output"
  done < <(/usr/bin/plutil -extract "$root.$escaped" raw -o - "$incoming")
done < <(/usr/bin/plutil -extract "$root" raw -o - "$incoming")
