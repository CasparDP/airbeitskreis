#!/usr/bin/env python3
"""Validate project entries against the schema documented in contribute.qmd.

Run from anywhere:  python3 scripts/validate_projects.py [--root DIR]
Exits 0 if every entry is valid, 1 otherwise, printing one line per problem.
"""

import argparse
import pathlib
import sys

import yaml

CATEGORIES = {"teaching", "research", "writing", "data", "admin", "tools", "fun"}
TOOLS = {"claude", "claude-code", "chatgpt", "codex", "copilot", "ollama", "lm-studio"}
REQUIRED = ("title", "description", "author", "date", "categories")


def check_entry(entry, where, is_link, errors):
    """Validate one entry. is_link selects the path rule."""
    if not isinstance(entry, dict):
        errors.append(f"{where}: expected a mapping of fields, got {type(entry).__name__}")
        return

    for field in REQUIRED:
        if not entry.get(field):
            errors.append(f"{where}: missing required field '{field}'")

    categories = entry.get("categories") or []
    if isinstance(categories, str):
        categories = [categories]
    for category in categories:
        if category not in CATEGORIES:
            errors.append(
                f"{where}: unknown category '{category}'. "
                f"Allowed: {', '.join(sorted(CATEGORIES))}"
            )

    tools = entry.get("tools") or []
    if isinstance(tools, str):
        tools = [tools]
    for tool in tools:
        if tool not in TOOLS:
            errors.append(
                f"{where}: unknown tool '{tool}'. Allowed: {', '.join(sorted(TOOLS))}"
            )

    path = entry.get("path")
    if is_link:
        if not path:
            errors.append(f"{where}: link entries require a 'path' field")
        elif not str(path).startswith(("http://", "https://")):
            errors.append(f"{where}: 'path' must be an absolute http(s) URL, got '{path}'")
    elif path:
        errors.append(
            f"{where}: subpages must not set 'path'. "
            "Remove it, or move this entry into links.yml instead."
        )


def read_frontmatter(qmd_path, errors):
    """Return the parsed YAML frontmatter of a .qmd file, or None on failure."""
    text = qmd_path.read_text(encoding="utf-8")
    if not text.startswith("---"):
        errors.append(f"projects/{qmd_path.name}: missing YAML frontmatter")
        return None
    parts = text.split("---", 2)
    if len(parts) < 3:
        errors.append(f"projects/{qmd_path.name}: frontmatter is not closed with ---")
        return None
    try:
        return yaml.safe_load(parts[1]) or {}
    except yaml.YAMLError as exc:
        errors.append(f"projects/{qmd_path.name}: invalid YAML in frontmatter: {exc}")
        return None


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "--root",
        default=pathlib.Path(__file__).resolve().parent.parent,
        type=pathlib.Path,
        help="Repository root (defaults to the parent of scripts/)",
    )
    args = parser.parse_args()
    projects = args.root / "projects"
    errors = []

    links_file = projects / "links.yml"
    if links_file.exists():
        try:
            entries = yaml.safe_load(links_file.read_text(encoding="utf-8")) or []
        except yaml.YAMLError as exc:
            errors.append(f"projects/links.yml: invalid YAML: {exc}")
            entries = []
        if not isinstance(entries, list):
            errors.append("projects/links.yml: top level must be a list of entries")
            entries = []
        for index, entry in enumerate(entries):
            title = entry.get("title", "untitled") if isinstance(entry, dict) else "untitled"
            check_entry(entry, f"projects/links.yml[{index}] '{title}'", True, errors)

    for qmd in sorted(projects.glob("*.qmd")):
        if qmd.name.startswith("_") or qmd.name == "index.qmd":
            continue
        frontmatter = read_frontmatter(qmd, errors)
        if frontmatter is not None:
            check_entry(frontmatter, f"projects/{qmd.name}", False, errors)

    if errors:
        print("Project entry validation failed:\n")
        for error in errors:
            print(f"  - {error}")
        print(f"\n{len(errors)} problem(s). See contribute.qmd for the schema.")
        return 1

    print("All project entries valid.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
