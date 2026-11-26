"""Builds the skill's references from YASB's docs: the guides, one file per service and type page, and an index.

python tools/build_references.py path/to/yasb/docs
Then raise version in plugins/yasb/.claude-plugin/plugin.json, so Claude Code offers the update.
"""

import re
import shutil
import sys
from pathlib import Path

SKILL = Path(__file__).resolve().parents[1] / "plugins" / "yasb" / "skills" / "yasb"
OUTPUT = SKILL / "references" / "api"
INDEX = SKILL / "references" / "api.md"
REFERENCES = SKILL / "references"
# Docs pages copied as guides, by their file name in docs/
GUIDES = (
    "Installation",
    "Getting-Started",
    "Configuration",
    "Widgets",
    "Writing-Widgets",
    "Services",
    "Themes",
    "Layouts",
    "Addons",
    "Troubleshooting",
    "CLI",
)
# Sections about the docs site, not the API
DROPPED_SECTIONS = ("Used by",)


def file_name(kind: str, page: str) -> str:
    return f"{kind}-{page.lower()}.md"


def guide_name(page: str) -> str:
    return f"guide-{page.lower()}.md"


def rewrite_links(text: str, api: bool) -> str:
    def link(match: re.Match[str]) -> str:
        label, target = match[1], match[2]
        page, _, anchor = target.partition("#")
        anchor = f"#{anchor}" if anchor else ""
        folder = "" if api else "api/"
        if page.startswith("./(Service)-"):
            return f"[{label}]({folder}{file_name('service', page[len('./(Service)-') :])}{anchor})"
        if page.startswith("./(Type)-"):
            return f"[{label}]({folder}{file_name('type', page[len('./(Type)-') :])}{anchor})"
        if page[2:] in GUIDES:
            return f"[{label}]({'../' if api else ''}{guide_name(page[2:])}{anchor})"
        # A docs page the skill doesn't copy: its name stays, without a link
        return label

    # A link to a docs page, whose name may hold one pair of brackets, as ./(Service)-Cpu
    return re.sub(r"\[([^\]]+)\]\((\./(?:\([^)\s]*\))?[^)\s]*)\)", link, text)


def clean(text: str, api: bool = True) -> str:
    text = text.replace("\r\n", "\n")
    text = re.sub(r"^Guide: .*\n\n?", "", text, flags=re.MULTILINE)
    for section in DROPPED_SECTIONS:
        text = re.sub(rf"^## {re.escape(section)}\n.*?(?=^## |\Z)", "", text, flags=re.MULTILINE | re.DOTALL)
    text = text.replace("&lt;", "<").replace("&gt;", ">")
    return rewrite_links(text, api).rstrip() + "\n"


def summary(text: str) -> tuple[str, str, list[str]]:
    """The page's title, its first paragraph after the import line, and the QML types it documents."""
    title = re.search(r"^# (.+)$", text, re.MULTILINE)[1]
    paragraphs = [block.strip() for block in text.split("\n\n")]
    intro = next(block for block in paragraphs[1:] if block and not block.startswith(("`import", "#", "Guide:")))
    intro = " ".join(intro.split())
    types = [name for name in re.findall(r"^## (\w+)$", text, re.MULTILINE) if name not in ("Example",)]
    return title, intro, types


def main() -> None:
    docs = Path(sys.argv[1])
    shutil.rmtree(OUTPUT, ignore_errors=True)
    OUTPUT.mkdir(parents=True)
    for old in REFERENCES.glob("guide-*.md"):
        old.unlink()
    for guide in GUIDES:
        text = (docs / f"{guide}.md").read_text(encoding="utf-8")
        (REFERENCES / guide_name(guide)).write_text(clean(text, api=False), encoding="utf-8", newline="\n")
    rows: dict[str, list[str]] = {"service": [], "type": []}
    for kind, folder, prefix in (("service", "services", "(Service)-"), ("type", "types", "(Type)-")):
        for page in sorted((docs / folder).glob(f"{prefix}*.md")):
            text = page.read_text(encoding="utf-8")
            name = file_name(kind, page.stem[len(prefix) :])
            (OUTPUT / name).write_text(clean(text), encoding="utf-8", newline="\n")
            title, intro, types = summary(text)
            # The index sits beside the guides, one folder above the API files
            intro = rewrite_links(intro, api=False)
            rows[kind].append(f"| {', '.join(f'`{t}`' for t in types)} | {title} | [{name}](api/{name}) | {intro} |")
    index = [
        "# YASB QML API",
        "",
        "Generated from YASB's docs by `tools/build_references.py`. Read only the file for the type you use.",
        "",
        "## Services",
        "",
        "Data from Windows and other programs, from `import Yasb`. A widget creates one and reads it.",
        "",
        "| QML type | Page | File | What it gives |",
        "| --- | --- | --- | --- |",
        *rows["service"],
        "",
        "## Types",
        "",
        (
            "Building blocks for widgets, layouts and themes, from `import Yasb`, `import Yasb.Bar`, "
            "`import Yasb.Common` or `import Yasb.Themes`, as each file says."
        ),
        "",
        "| QML type | Page | File | What it is |",
        "| --- | --- | --- | --- |",
        *rows["type"],
        "",
    ]
    INDEX.write_text("\n".join(index), encoding="utf-8", newline="\n")
    print(f"{len(GUIDES)} guides, {len(rows['service'])} services, {len(rows['type'])} types -> {REFERENCES}")


if __name__ == "__main__":
    main()
