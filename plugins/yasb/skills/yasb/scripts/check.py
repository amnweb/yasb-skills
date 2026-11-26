"""Checks a YASB widget, theme, layout or addon folder before it is used or shared.

python check.py <folder or .qml file> [--yasb <path to the YASB repository>]

Always: manifest.json against yasb-addons' rules, the QML file's name, and files an addon can't hold.
With --yasb: compiles every QML file against YASB's QML types, as yasb-addons does; needs YASB's Python packages
(pip install -e <yasb repository>). Nothing is created, so no QML runs.
Exit code 0 when all is well, 1 when something is wrong.
"""

import argparse
import json
import os
import re
import sys
import tempfile
from datetime import date
from pathlib import Path

# yasb-addons' rules for manifest.json
MANIFEST_KEYS = ("id", "title", "description", "version", "released")
ID_RE = re.compile(r"([a-z0-9-]+)\.([a-z][a-z0-9]*)")
MAX_TITLE = 50
MAX_DESCRIPTION = 200
TYPES = ("widget", "theme", "layout", "config")


def check_manifest(folder: Path) -> list[str]:
    path = folder / "manifest.json"
    if not path.is_file():
        return []
    try:
        manifest = json.loads(path.read_text(encoding="utf-8-sig"))
    except ValueError as e:
        return [f"manifest.json is not valid JSON: {e}"]
    if not isinstance(manifest, dict):
        return ["manifest.json must be a JSON object"]
    problems = [f"manifest.json is missing `{key}`" for key in MANIFEST_KEYS if key not in manifest]
    problems += [f"manifest.json has an unknown key `{key}`" for key in manifest if key not in (*MANIFEST_KEYS, "type")]
    match = ID_RE.fullmatch(manifest.get("id", "")) if isinstance(manifest.get("id"), str) else None
    if match is None:
        problems.append("`id` must be <github login>.<name>, lower case, the name a letter then letters or digits")
    for key, limit in (("title", MAX_TITLE), ("description", MAX_DESCRIPTION)):
        value = manifest.get(key)
        if not isinstance(value, str) or not value or value != value.strip() or not value.isprintable():
            problems.append(f"`{key}` must be text on one line, with no spaces at its start or end")
        elif len(value) > limit:
            problems.append(f"`{key}` has {len(value)} characters, at most {limit}")
    version = manifest.get("version")
    if type(version) is not int or version < 1:
        problems.append("`version` must be a whole number, 1 or more")
    released = manifest.get("released")
    try:
        if date.fromisoformat(str(released)) > date.today():
            problems.append(f"`released` is in the future: {released}")
    except ValueError:
        problems.append("`released` must be a date written as YYYY-MM-DD")
    if "type" in manifest and manifest["type"] not in TYPES:
        problems.append(f"`type` must be one of {', '.join(TYPES)}")
    if match and manifest.get("type") != "config":
        main = f"{match[2]}.qml"
        if not any(file.name.casefold() == main for file in folder.glob("*.qml")):
            problems.append(f"the QML file must be named after the id: {main}, in any case, next to manifest.json")
    return problems


def check_files(folder: Path) -> list[str]:
    programs = [str(path.relative_to(folder)) for path in folder.rglob("*") if path.suffix.lower() in (".exe", ".dll")]
    return [f"an addon can't hold .exe or .dll files: {', '.join(programs)}"] if programs else []


def compile_errors(files: list[Path], yasb: Path) -> list[str]:
    source = yasb / "src"
    if not (source / "core" / "qml_types.py").is_file():
        return [f"--yasb must be the YASB repository, with src/core/qml_types.py: {yasb}"]
    # A config folder of its own, so the user's is never read or written
    os.environ["YASB_CONFIG_HOME"] = tempfile.mkdtemp(prefix="yasb-check-")
    os.environ.setdefault("QT_QPA_PLATFORM", "offscreen")
    sys.path.insert(0, str(source))
    from core.qml_types import register_qml_types  # type: ignore
    from PyQt6.QtCore import QUrl
    from PyQt6.QtGui import QGuiApplication
    from PyQt6.QtQml import QQmlComponent, QQmlEngine
    from settings import QML_IMPORT_PATH  # type: ignore

    app = QGuiApplication([])
    register_qml_types()
    engine = QQmlEngine()
    engine.addImportPath(QML_IMPORT_PATH)
    errors: list[str] = []
    for file in files:
        component = QQmlComponent(engine, QUrl.fromLocalFile(str(file.resolve())))
        errors += [error.toString() for error in component.errors()]
        if not component.errors() and component.status() != QQmlComponent.Status.Ready:
            errors.append(f"{file.name} did not load")
    del app
    return errors


def main() -> int:
    parser = argparse.ArgumentParser(description="Check a YASB widget, theme, layout or addon folder.")
    parser.add_argument("path", type=Path, help="the folder, or one .qml file")
    parser.add_argument("--yasb", type=Path, help="the YASB repository, to compile the QML against YASB's types")
    args = parser.parse_args()
    path: Path = args.path
    folder = path if path.is_dir() else path.parent
    files = sorted(folder.rglob("*.qml")) if path.is_dir() else [path]
    if not files:
        print(f"No QML file in {path}")
        return 1
    problems = check_manifest(folder) + check_files(folder) if path.is_dir() else []
    if args.yasb:
        problems += compile_errors(files, args.yasb)
    for problem in problems:
        print(f"- {problem}")
    if problems:
        return 1
    checked = "compiled against YASB" if args.yasb else "manifest and files checked, QML not compiled (no --yasb)"
    print(f"OK: {len(files)} QML file(s), {checked}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
