#!/usr/bin/env bash
# Checks the agent contribution path against the repository it describes.
#
# The skill is prose, so nothing else would notice it going stale. Two things can
# rot: a path it tells an agent to open can move, and the closed vocabularies can
# get copied into it, which would make it a fourth enforcer of a schema that is
# meant to have three. Both are checked here.
#
# Assertions name the offending value, not just a count, for the same reason the
# validator tests do: a check that only counts can pass for the wrong reason.
set -uo pipefail
cd "$(dirname "$0")/.."

SKILL=.claude/skills/add-project/SKILL.md
AGENTS=AGENTS.md

pass=0; fail=0
ok()  { echo "  ok   $1"; pass=$((pass+1)); }
bad() { echo "  FAIL $1: $2"; fail=$((fail+1)); }

# 1. Both files exist. Everything below depends on it.
for f in "$SKILL" "$AGENTS"; do
  if [ -f "$f" ]; then ok "$f present"; else bad "$f present" "file missing"; fi
done
[ -f "$SKILL" ] && [ -f "$AGENTS" ] || { echo; echo "$pass passed, $fail failed"; exit 1; }

# 2. The skill needs the frontmatter that makes it loadable as a skill.
for field in name description; do
  if awk '/^---$/{n++; next} n==1' "$SKILL" | grep -q "^$field:"; then
    ok "skill frontmatter has $field"
  else
    bad "skill frontmatter has $field" "no '$field:' in the leading --- block"
  fi
done

# 3. Every repository path either file names in backticks must exist. Paths that
#    only exist after a build or a venv install are deliberately excluded.
missing=""
for f in "$SKILL" "$AGENTS"; do
  for p in $(grep -oE '`[A-Za-z_.][A-Za-z0-9_./-]*`' "$f" | tr -d '`' | sort -u); do
    case "$p" in
      .venv/*|_freeze/|_site/|_freeze/*|_site/*) continue ;;
      projects/*|scripts/*|tests/*|theme/*|.github/*|.claude/*|images/*|fonts/*) ;;
      *.qmd|*.yml|*.md) ;;
      *) continue ;;
    esac
    case "$p" in
      projects/'<slug>'.qmd|*'<'*) continue ;;   # placeholders, not real paths
    esac
    [ -e "$p" ] || missing="$missing $p"
  done
done
if [ -z "$missing" ]; then
  ok "every path named in the skill and AGENTS.md exists"
else
  bad "every path named in the skill and AGENTS.md exists" "not found:$missing"
fi

# 4. The skill must send the agent to the validator for the vocabularies rather
#    than carrying its own copy. This is the whole reason it is not a fourth
#    enforcer of the schema.
if grep -q 'scripts/validate_projects.py' "$SKILL" && grep -q 'CATEGORIES' "$SKILL"; then
  ok "skill reads the vocabularies from the validator"
else
  bad "skill reads the vocabularies from the validator" \
      "SKILL.md no longer points at CATEGORIES in scripts/validate_projects.py"
fi

# 5. Neither file may restate a whole vocabulary. Naming one or two values while
#    explaining a judgement call is fine; carrying the full list is the copy that
#    silently drifts the next time the list changes.
check_no_full_list() { # file, label, values...
  local file="$1" label="$2"; shift 2
  local v hits=0 found=""
  for v in "$@"; do
    if grep -qw -- "$v" "$file"; then hits=$((hits+1)); found="$found $v"; fi
  done
  if [ "$hits" -lt "$#" ]; then
    ok "$file does not restate the $label list"
  else
    bad "$file does not restate the $label list" \
        "contains every value ($found); read them from the validator instead"
  fi
}
cats="teaching research writing data admin tools fun"
tools="claude claude-code chatgpt codex copilot ollama lm-studio"
for f in "$SKILL" "$AGENTS"; do
  check_no_full_list "$f" categories $cats
  check_no_full_list "$f" tools $tools
done

# 6. The vocabularies this test hardcodes must match the validator, or check 5
#    would silently stop testing anything.
for pair in "CATEGORIES:$cats" "TOOLS:$tools"; do
  name=${pair%%:*}; expected=${pair#*:}
  actual=$(grep -E "^$name = " scripts/validate_projects.py \
    | grep -oE '"[a-z-]+"' | tr -d '"' | sort | tr '\n' ' ')
  if [ "$(echo $expected | tr ' ' '\n' | sort | tr '\n' ' ')" = "$actual" ]; then
    ok "$name in this test matches the validator"
  else
    bad "$name in this test matches the validator" \
        "validator has '$actual', this test has '$expected'"
  fi
done

echo
echo "$pass passed, $fail failed"
[ "$fail" -eq 0 ]
