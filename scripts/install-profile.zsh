#!/bin/zsh
# Pure file transformation: input JSON, profile JSON, output JSON.
emulate -LR zsh
setopt ERR_EXIT NO_UNSET PIPE_FAIL
(( $# == 3 )) || exit 64
input="$1"; profile="$2"; output="$3"
[[ "$input" != "$output" ]] || { print -u2 'Input and output must differ.'; exit 1; }
if [[ -f "$input" ]]; then /bin/cp "$input" "$output"; else print -r -- '{"profiles":[]}' > "$output"; fi
/usr/bin/plutil -convert xml1 "$output"
count=$(/usr/bin/plutil -extract profiles raw -expect array -o - "$output")
name=$(/usr/bin/plutil -extract name raw -o - "$profile")
# Replace only our own profile, preserving every other profile and device record.
for ((i=count-1;i>=0;i--)); do
  existing=$(/usr/bin/plutil -extract "profiles.$i.name" raw -o - "$output")
  if [[ "$existing" == "$name" ]]; then /usr/bin/plutil -remove "profiles.$i" "$output"
  else /usr/bin/plutil -replace "profiles.$i.selected" -bool false "$output"; fi
done
/usr/bin/plutil -insert profiles.0 -json "$(/bin/cat "$profile")" "$output"
/usr/bin/plutil -convert json -r "$output"
