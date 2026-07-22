# A(I)rbeitskreis

A working group on AI in teaching and research.

**[caspardp.github.io/airbeitskreis](https://caspardp.github.io/airbeitskreis)**

A group of academics comparing notes on how AI actually lands in teaching and research.
Not the discourse about it, the actual practice. This repository is the site that collects
those workflows.

## Adding a project

Three ways, from least to most technical:

1. **[Open an issue](https://github.com/CasparDP/airbeitskreis/issues/new?template=add-project.yml)** and a maintainer opens the PR for you.
2. **Edit in the GitHub web UI.** Append to `projects/links.yml` to link something you
   published elsewhere, or copy `projects/_template.qmd` to write a full page here.
3. **Clone it.** `quarto preview` for live reload.

Full instructions, including the field reference, are on the
[Contribute](https://caspardp.github.io/airbeitskreis/contribute.html) page.

## Working on the site itself

```bash
quarto preview                      # live reload; Quarto prints the URL
quarto render                       # build to _site/

# The schema check CI runs. Needs pyyaml, so use a virtual environment:
python3 -m venv .venv && .venv/bin/pip install pyyaml
.venv/bin/python scripts/validate_projects.py
./tests/test_validate_projects.sh   # tests for that check
```

Requires [Quarto](https://quarto.org/docs/get-started/) 1.9 or later. The validator needs
`pyyaml`; nothing else.

## How it fits together

`projects/index.qmd` defines one listing whose `contents` pulls from two sources:
`projects/*.qmd` for full subpages and `projects/links.yml` for external links. Both render
into the same grid with the same fields and filters. Files prefixed with `_` are ignored by
Quarto, which is why `_template.qmd` can sit beside real entries.

The frontmatter schema is enforced in three places that must stay in sync:
`scripts/validate_projects.py` (the machine check and source of truth for the closed
category and tool vocabularies), `contribute.qmd` (the human-readable reference), and
`.github/ISSUE_TEMPLATE/add-project.yml` (the dropdowns for the no-git path).

Pushing to `main` triggers `.github/workflows/publish.yml`, which validates entries, renders
the site, and deploys to GitHub Pages. Pull requests get the validate-and-render half only.

## License

Code and site machinery: [MIT](LICENSE). Content: [CC BY 4.0](LICENSE-CONTENT).
Contributors retain copyright on the pages they write.
