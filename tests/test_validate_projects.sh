#!/usr/bin/env bash
# Exercises the validator against deliberately broken entries in a temp copy.
#
# Each check asserts on BOTH the exit code and the output, because a crashing
# script also exits non-zero. Without the message assertion, a missing pyyaml
# would make every "rejects ..." case pass for the wrong reason.
set -uo pipefail
cd "$(dirname "$0")/.."

# Prefer the project venv, since Homebrew Python is externally managed and
# refuses a bare `pip install`. Fall back to whatever python3 is on PATH,
# which is what CI uses.
if [ -x .venv/bin/python ]; then PY=.venv/bin/python; else PY=python3; fi

pass=0; fail=0

ok()   { echo "  ok   $1"; pass=$((pass+1)); }
bad()  { echo "  FAIL $1: $2"; fail=$((fail+1)); }

expect_valid() { # name
  local out; out=$("$PY" scripts/validate_projects.py 2>&1); local code=$?
  if [ $code -ne 0 ]; then bad "$1" "expected exit 0, got $code: $out"; return; fi
  case "$out" in
    *"All project entries valid."*) ok "$1" ;;
    *) bad "$1" "unexpected output: $out" ;;
  esac
}

expect_rejected() { # name, expected_substring
  local out; out=$("$PY" "$tmp/scripts/validate_projects.py" --root "$tmp" 2>&1); local code=$?
  if [ $code -ne 1 ]; then bad "$1" "expected exit 1, got $code: $out"; return; fi
  case "$out" in
    *Traceback*) bad "$1" "script crashed instead of rejecting: $out"; return ;;
  esac
  case "$out" in
    *"$2"*) ok "$1" ;;
    *) bad "$1" "expected message containing '$2', got: $out" ;;
  esac
}

# 1. The real repository must validate cleanly.
expect_valid "real repo validates"

# 2. Broken fixtures must be rejected, each with a message naming the problem.
tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT
cp -R projects scripts "$tmp"/

printf -- '- title: "X"\n  description: "d"\n  author: "a"\n  date: "2026-01-01"\n  categories: [not_a_category]\n  path: "https://example.com"\n' > "$tmp/projects/links.yml"
expect_rejected "rejects unknown category" "unknown category 'not_a_category'"

printf -- '- title: "X"\n  description: "d"\n  author: "a"\n  date: "2026-01-01"\n  categories: [teaching]\n  tools: [not_a_tool]\n  path: "https://example.com"\n' > "$tmp/projects/links.yml"
expect_rejected "rejects unknown tool" "unknown tool 'not_a_tool'"

printf -- '- title: "X"\n  description: "d"\n  author: "a"\n  date: "2026-01-01"\n  categories: [teaching]\n' > "$tmp/projects/links.yml"
expect_rejected "rejects link entry missing path" "link entries require a 'path' field"

printf -- '- title: "X"\n  description: "d"\n  author: "a"\n  date: "2026-01-01"\n  categories: [teaching]\n  path: "example.com"\n' > "$tmp/projects/links.yml"
expect_rejected "rejects relative path" "must be an absolute http(s) URL"

printf -- '- title: "X"\n  categories: [teaching]\n  path: "https://example.com"\n' > "$tmp/projects/links.yml"
expect_rejected "rejects missing required fields" "missing required field 'description'"

printf -- '[]\n' > "$tmp/projects/links.yml"
printf -- '---\ntitle: "Y"\ndescription: "d"\nauthor: "a"\ndate: "2026-01-01"\ncategories: [teaching]\npath: "https://example.com"\n---\nbody\n' > "$tmp/projects/stray.qmd"
expect_rejected "rejects subpage carrying a path field" "subpages must not set 'path'"

printf -- '- title: "X"\n  description: "d"\n  author: "a"\n  date: "2026-01-01"\n  categories: [teaching]\n  path: "https://example.com"\n  oops: [unclosed\n' > "$tmp/projects/links.yml"
rm -f "$tmp/projects/stray.qmd"
expect_rejected "rejects malformed YAML" "invalid YAML"

echo
echo "$pass passed, $fail failed"
[ "$fail" -eq 0 ]
