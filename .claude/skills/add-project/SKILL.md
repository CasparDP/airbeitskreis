---
name: add-project
description: Use when someone wants a project added to the A(I)rbeitskreis site (caspardp.github.io/airbeitskreis): a workflow they want written up here, a link to something they already published, or any request to add, submit, or contribute an entry to the projects grid.
---

# Adding a project to A(I)rbeitskreis

The site is a Quarto listing that renders two kinds of entry into one grid. Everything
below produces one of them.

| The contributor has | Entry type | Where it goes |
| --- | --- | --- |
| A URL to something already published | Link | An entry appended to `projects/links.yml` |
| A workflow they want written up here | Subpage | A new `projects/<slug>.qmd` |

If they have a URL, it is a link entry. Do not write a page that duplicates something that
already exists elsewhere.

## What finished means

A finished contribution is a branch containing **one** new entry, which
`scripts/validate_projects.py` accepts and `quarto render` builds, pushed, with a pull
request open against `main`. Report the PR URL.

Those two commands are what CI runs. Running them before you commit is what makes the pull
request pass unmodified.

## Steps

**1. Get into the repository.** You are already in it if `projects/index.qmd` and
`scripts/validate_projects.py` both exist; work in place, whatever the remote is called.
Only if they are missing, clone one: `gh repo clone CasparDP/airbeitskreis`. Never clone
into a checkout you are already standing in.

**2. Read the controlled vocabularies from the validator. Never recall them from memory.**

```bash
grep -E '^(CATEGORIES|TOOLS) =' scripts/validate_projects.py
```

That file is the source of truth. The lists are closed and they change by PR.

**3. Collect the fields in one batch.** Ask for everything missing in a single message,
then write. Do not interview the contributor one question at a time; they are here to
contribute a project, not to be onboarded.

| Field | Required | Where it comes from |
| --- | --- | --- |
| `title` | yes | Specific and concrete. "Grading 120 theses with a rubric agent", not "Using AI for grading". |
| `description` | yes | One sentence of roughly 15 to 25 words. It is the only text on the card, so a clause-stacked run-on reads as a wall of grey on the grid. |
| `author` | yes | As they want to be credited. |
| `date` | yes | Today, `YYYY-MM-DD`. Read the clock; do not guess the year. |
| `categories` | yes | From `CATEGORIES`. See the mapping rule below. |
| `tools` | no | From `TOOLS`. Omit the field if nothing matches. |
| `image` | no | Optional thumbnail, e.g. `/images/my-thumb.png`. Omitting it gives the card a designed monogram tile, so never invent a path. |
| `path` | link only | Absolute `https://` URL. A subpage must not have this field at all. |

**Categorize by what the work is for, not what it is about.** A tool that screens
literature is `research` even when the literature is about teaching. `teaching` means the
contributor's own courses and students; `admin` means university administration;
`writing` means drafting prose; `tools` means something built for other people to run.

**4. Write the entry.**

- *Link:* append to `projects/links.yml`, matching the quoting and the blank line between
  entries that the existing entries use.
- *Subpage:* copy `projects/_template.qmd` to `projects/<slug>.qmd`, where `<slug>` is the
  title in lowercase kebab-case. Never prefix it with `_`; Quarto ignores those files, so
  the entry would silently not appear. Fill in the frontmatter, delete the template's
  guidance comments, and write the three sections from what the contributor told you.

**5. Validate.** Both commands must pass before anything is committed.

```bash
# The validator needs pyyaml. Homebrew Python is externally managed and refuses a
# bare pip install, so the repository uses a gitignored venv. Test for the import
# rather than the directory: a half-built venv from an earlier attempt has the
# interpreter but not the package.
.venv/bin/python -c "import yaml" 2>/dev/null || {
  python3 -m venv .venv && .venv/bin/pip install --quiet pyyaml
}
.venv/bin/python scripts/validate_projects.py   # must print "All project entries valid."
quarto render                                   # must complete without error
```

A `ModuleNotFoundError: No module named 'yaml'` means the venv step was skipped, not that
the entry is fine.

If the validator names a problem, fix the entry and run it again. Never commit past it.

**6. Branch, commit, push, open a pull request.**

```bash
git switch -c add-<slug>
git add projects/
git commit -m "Add project: <title>"
git push -u origin add-<slug>
gh pr create --fill
```

Never commit to `main` and never push to it; it is protected and the push will be
rejected. If the push is refused for lack of write access, fork and push there instead.
Name the remote explicitly, because `gh` otherwise calls it `origin` and renames the
existing one:

```bash
gh repo fork --remote --remote-name fork
git push -u fork add-<slug>
gh pr create --fill --repo CasparDP/airbeitskreis
```

## Rules

**Do not invent the workflow.** The contributor describes what they actually did; you
format it. If a section would be generic filler, you are missing information: ask for it.
A fabricated write-up on a site of named academics is worse than no write-up.

**Do not write an entry you know is invalid.** If the tool they used is not in `TOOLS`,
omit the `tools` field. Do not add the value, and do not substitute something adjacent:
Gemini is not `chatgpt`. Adding to either vocabulary is a separate PR touching
`scripts/validate_projects.py`, `contribute.qmd`, and
`.github/ISSUE_TEMPLATE/add-project.yml` together; offer that as its own change, never as
part of this one.

**Subpages are prose.** If the page must execute R or Python, it needs `freeze: auto` in
its frontmatter and a committed freeze. CI renders without installing anyone's packages, so
an unfrozen `library(fixest)` breaks deploys for everyone. `_freeze/` is gitignored, since
it is otherwise just local render output, so that one page's freeze has to be forced in:

```bash
git add -f _freeze/projects/<slug>
```

A plain `git add` skips it silently and CI then fails on the page it was meant to protect.

## Red flags

- About to commit having run only one of the two checks in step 5
- About to add a value to `CATEGORIES` or `TOOLS` so an entry passes
- Writing a "What worked and what did not" section the contributor never described
- Writing a subpage for something that already exists at a URL
- On `main`, or about to push to it
