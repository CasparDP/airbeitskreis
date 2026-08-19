---
project:
  name: "airbeitskreis"
  description: >
    A(I)rbeitskreis
  added_at: 2026-07-23
  github_url: "https://github.com/CasparDP/airbeitskreis"

current_focus: 1

milestones:
  - id: 1
    title: "Publish all pending personal project entries"
    description: >
      All projects you plan to contribute yourself are added to the site (as
      `.qmd` pages or `links.yml` entries), pass schema validation, and are
      visible in the live grid with accurate metadata.
    status: pending
    created_at: 2026-08-19
    next_task: |
      Run `quarto preview` locally, open `projects/links.yml`, and write the first pending entry following `_template.qmd` — then run `scripts/validate_projects.py` to confirm it passes.

  - id: 2
    title: "Improve existing entries: richer descriptions and display"
    description: >
      Each existing entry has a polished prose description (not just a title +
      tags) and any display issues (card layout, field rendering,
      category/tool labels) are fixed so the grid looks compelling to a new
      visitor.
    status: pending
    created_at: 2026-08-19
    next_task: |
      Pick the weakest existing entry, rewrite its `description` field, and check how it renders in `quarto preview` — note any layout or truncation problems to fix next.

  - id: 3
    title: "Extend the `add-project` skill with diagram support (manual path)"
    description: >
      The SKILL.md workflow guides contributors to create and embed an
      Excalidraw or tldraw diagram (exported as SVG/PNG) in their entry. The
      skill writes the correct image embed syntax and the schema accepts an
      optional `diagram` field. Done when a real entry uses a diagram and CI
      passes.
    status: pending
    created_at: 2026-08-19
    next_task: |
      Open `.claude/skills/add-project/SKILL.md` and draft the new step that asks the contributor for a diagram file path and inserts the Quarto image embed — then add the optional `diagram` field to `scripts/validate_projects.py`.

  - id: 4
    title: "Auto-generate workflow diagrams from project descriptions"
    description: >
      The skill calls an AI API (e.g. Claude) to produce a Mermaid or
      Excalidraw JSON diagram from a plain-language project description, saves
      it as a static file, and embeds it — removing the need for the
      contributor to draw anything. Done when at least one entry has an
      auto-generated diagram that renders correctly on the live site.
    status: pending
    created_at: 2026-08-19
    next_task: |
      Write a small standalone Python script (`scripts/gen_diagram.py`) that takes a description string, calls the API, and prints Mermaid syntax — verify the output on one existing project description before wiring it into the skill.

checkin:
  last_at: null
  last_commit_seen: null
  last_summary: null

integrations:
  github: "https://github.com/CasparDP/airbeitskreis"
---
