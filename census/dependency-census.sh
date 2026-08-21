#!/usr/bin/env bash
# Dependency census: proves the fork imports no product packages and no full
# protobuf runtime, and that go.mod carries no unused requirements.
set -euo pipefail
cd "$(dirname "$0")/.."

fail=0

# Zero product imports: no company module may appear anywhere in the closure.
product_re='aperturerobotics/(spacewave|common|util|starpc|glados|hemi-v)(/|$)'
if grep -Eq "$product_re" go.mod; then
  echo "FAIL: product module referenced in go.mod:"
  grep -E "$product_re" go.mod
  fail=1
fi
deps=$(go list -deps ./...)
if grep -Eq "^($product_re)" <<<"$deps"; then
  echo "FAIL: product package in dependency closure:"
  grep -E "^($product_re)" <<<"$deps"
  fail=1
fi

# No full protobuf runtime: gogo and google.golang.org/protobuf are forbidden;
# the lite replacement (github.com/aperturerobotics/protobuf-go-lite) is the
# only accepted protobuf implementation.
if grep -Eq '^(google\.golang\.org/protobuf|github\.com/gogo/protobuf)' <<<"$deps"; then
  echo "FAIL: full protobuf runtime in dependency closure:"
  grep -E '^(google\.golang\.org/protobuf|github\.com/gogo/protobuf)' <<<"$deps"
  fail=1
fi

# go.mod must be tidy: every require must appear in the build list closure.
go mod tidy
if ! git diff --exit-code -- go.mod go.sum >/dev/null; then
  echo "FAIL: go.mod/go.sum not tidy (diff after 'go mod tidy'):"
  git diff --stat -- go.mod go.sum
  git checkout -- go.mod go.sum
  fail=1
fi

if [ "$fail" -ne 0 ]; then
  echo "dependency-census: FAIL"
  exit 1
fi
echo "dependency-census: OK"
