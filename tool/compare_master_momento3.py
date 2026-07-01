#!/usr/bin/env python3
"""Compara cuerpos de test entre maestro y test/momento3/."""
import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
MOMENTO3 = ROOT / "test" / "momento3"
MASTER = ROOT / "test" / "sdag_todos_los_rf_test.dart"


def normalize(body: str) -> str:
    lines = [ln.strip() for ln in body.splitlines() if ln.strip()]
    return "\n".join(lines)


def extract_momento3(path: Path) -> tuple[str, str, str]:
    content = path.read_text(encoding="utf-8")
    rf_m = re.search(r"^// (RF-\d+):", content, re.MULTILINE)
    test_m = re.search(r"test\('([^']+)',\s*\(\)\s*\{", content)
    start = content.find("{", test_m.end() - 1)
    depth = 0
    i = start
    while i < len(content):
        if content[i] == "{":
            depth += 1
        elif content[i] == "}":
            depth -= 1
            if depth == 0:
                body = content[start + 1 : i]
                return rf_m.group(1), test_m.group(1), normalize(body)
        i += 1
    raise ValueError(path.name)


def extract_master(content: str) -> dict[tuple[str, str], str]:
    out: dict[tuple[str, str], str] = {}
    rf_id = ""
    lines = content.splitlines()
    i = 0
    while i < len(lines):
        m_rf = re.match(r"^// (RF-\d+):", lines[i].strip())
        if m_rf:
            rf_id = m_rf.group(1)
        m_test = re.match(r"\s*test\('([^']+)',\s*\(\)\s*\{", lines[i])
        if m_test and rf_id:
            title = m_test.group(1)
            i += 1
            depth = 1
            body_lines = []
            while i < len(lines) and depth > 0:
                ln = lines[i]
                depth += ln.count("{") - ln.count("}")
                if depth > 0:
                    body_lines.append(ln)
                i += 1
            body = normalize("\n".join(body_lines))
            out[(rf_id, title)] = body
            continue
        i += 1
    return out


def main() -> None:
    master = extract_master(MASTER.read_text(encoding="utf-8"))
    missing = []
    diffs = []
    for path in sorted(MOMENTO3.glob("rf*_test.dart")):
        rf_id, title, body = extract_momento3(path)
        key = (rf_id, title)
        if key not in master:
            missing.append(f"{path.name}: {rf_id} / {title}")
            continue
        if master[key] != body:
            diffs.append((path.name, rf_id, title))

    extra = set(master) - {
        (extract_momento3(p)[0], extract_momento3(p)[1])
        for p in MOMENTO3.glob("rf*_test.dart")
    }

    print(f"Master tests: {len(master)}")
    print(f"Momento3 files: {len(list(MOMENTO3.glob('rf*_test.dart')))}")
    print(f"Missing in master: {len(missing)}")
    print(f"Body diffs: {len(diffs)}")
    print(f"Extra in master: {len(extra)}")
    if missing:
        print("\n--- Missing (first 10) ---")
        for m in missing[:10]:
            print(m)
    if diffs:
        print("\n--- Diffs (first 15) ---")
        for d in diffs[:15]:
            print(d[0], d[1], d[2][:60])
    sys.exit(1 if missing or diffs else 0)


if __name__ == "__main__":
    main()
