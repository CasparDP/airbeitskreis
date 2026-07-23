# AGENTS.md

Guidance for AI agents working in this repository. Harness-neutral: Claude Code loads
`.claude/skills/add-project/SKILL.md` on its own, and any other agent can read the same
file as an ordinary path.

## Adding a project

**Follow `.claude/skills/add-project/SKILL.md`.** It is the procedure, and it is the only
copy of it. Read it before writing an entry rather than reconstructing the steps from this
page.

## What this repository is

A Quarto website showcasing how a group of academics actually uses AI in teaching and
research. It is public and open source, and it lives at
https://caspardp.github.io/airbeitskreis. The display title is **A(I)rbeitskreis**; the
repository, URLs, and paths are all lowercase `airbeitskreis`.

Most contributors are academics with little or no git experience, and the documented
contribution path runs entirely through the GitHub web interface. Any change that makes
contributing harder is a regression, even if it makes the code nicer.

## Commands

```bash
quarto preview                      # live reload; Quarto prints the URL
quarto render                       # build to _site/

# The schema check CI runs. It needs pyyaml, and Homebrew Python refuses a bare
# pip install (PEP 668), so use a virtual environment:
python3 -m venv .venv && .venv/bin/pip install pyyaml
.venv/bin/python scripts/validate_projects.py
./tests/test_validate_projects.sh
```

There is no build step beyond Quarto and no JavaScript toolchain.

## How the site fits together

`projects/index.qmd` defines one listing whose `contents` pulls from two sources:
`projects/*.qmd` for full subpages and `projects/links.yml` for external links. Both render
into the same grid with the same fields, sorting, and filters, so adding a contribution
never touches configuration. Quarto ignores paths beginning with `_`, which is why
`projects/_template.qmd` sits beside real entries without rendering.

## Constraints

- **The frontmatter schema has three enforcers that must stay in sync:**
  `scripts/validate_projects.py` (the machine check, and the source of truth for the closed
  category and tool vocabularies), `contribute.qmd` (the human-readable reference), and
  `.github/ISSUE_TEMPLATE/add-project.yml` (the dropdowns for the no-git path). Changing a
  vocabulary means changing all three in one pull request. Nothing else may restate those
  lists: read them from the validator instead of copying them.
- **CI never installs a contributor's language runtime.** A page that executes R or Python
  must set `freeze: auto` and commit `_freeze/`. Anything else breaks deploys for everyone.
- **`_quarto.yml` uses an explicit `render:` allowlist.** A new top-level page has to be
  added to it, or it will not be rendered.
- **`main` is protected.** Pull requests only, and one approving review from a code owner.
  Never commit or push to `main`.
- **Theming is a three-file split.** `theme/light.scss` and `theme/dark.scss` hold palettes
  (`scss:defaults`); `theme/shared.scss` holds every rule (`scss:rules`) and references
  palette variables. Hardcoding a color in `shared.scss` silently breaks one of the themes.
