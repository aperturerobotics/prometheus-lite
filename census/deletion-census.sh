#!/usr/bin/env bash
# Deletion census: fails while any deleted Prometheus subsystem remains
# present on disk or importable from the retained package set.
set -euo pipefail
cd "$(dirname "$0")/.."

fail=0
while read -r p; do
  case "$p" in ''|'#'*) continue ;; esac
  if [ -e "$p" ]; then
    echo "FAIL: forbidden subsystem present on disk: $p"
    fail=1
  fi
done < census/forbidden-paths.txt

if [ -d tsdb ]; then
  while IFS= read -r d; do
    rel=${d#./}
    keep=0
    while read -r e; do
      case "$e" in ''|'#'*) continue ;; esac
      if [ "$rel" = "$e" ] || [[ "$rel" == "$e"/* ]]; then keep=1; break; fi
    done < census/tsdb-exceptions.txt
    if [ "$keep" -eq 0 ]; then
      echo "FAIL: non-allowlisted tsdb path present: $rel"
      fail=1
    fi
  done < <(find tsdb -type d -not -path '*/.*' | sort)
fi

# No retained package may depend on a deleted subsystem.
deps=$(go list -deps ./...)
modpath=$(go list -m)
while read -r p; do
  case "$p" in ''|'#'*) continue ;; esac
  if grep -qx "$modpath/$p" <<<"$deps"; then
    echo "FAIL: forbidden package still in dependency closure: $p"
    fail=1
  fi
done < census/forbidden-paths.txt
if grep -qE "^$modpath/tsdb/" <<<"$deps"; then
  while read -r dep; do
    rel=${dep#"$modpath"/}
    keep=0
    while read -r e; do
      case "$e" in ''|'#'*) continue ;; esac
      if [[ "$rel" == "$e" || "$rel" == "$e"/* ]]; then keep=1; break; fi
    done < census/tsdb-exceptions.txt
    if [ "$keep" -eq 0 ]; then
      echo "FAIL: non-allowlisted tsdb package in dependency closure: $rel"
      fail=1
    fi
  done < <(grep -E "^$modpath/tsdb/" <<<"$deps")
fi

if [ "$fail" -ne 0 ]; then
  echo "deletion-census: FAIL"
  exit 1
fi
echo "deletion-census: OK"
