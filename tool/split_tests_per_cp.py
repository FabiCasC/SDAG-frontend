#!/usr/bin/env python3
"""Genera un archivo de test por cada CP desde sdag_tdd_momento3_test.dart."""
import re
import unicodedata
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
SRC = ROOT / "test" / "sdag_tdd_momento3_test.dart"
OUT = ROOT / "test" / "momento3"

HEADER = """import 'package:flutter_test/flutter_test.dart';
import 'package:sdag/app/providers/passenger/utils/passenger_db_error_mapping.dart';
import 'package:sdag/app/providers/passenger/validators/passenger_auth_validators.dart';
import 'package:sdag/features/busqueda/utils/busqueda_utils.dart';
import 'package:sdag/features/conductor/utils/notification_utils.dart';
import 'package:sdag/features/conductor/utils/qr_scan_utils.dart';
import 'package:sdag/features/reserva/utils/payment_validation.dart';
import 'package:sdag/features/reserva/utils/pickup_validation.dart';
import 'package:sdag/features/reserva/utils/trip_rules.dart';
"""


def slug(text: str, max_len: int = 48) -> str:
    text = unicodedata.normalize("NFKD", text)
    text = text.encode("ascii", "ignore").decode("ascii")
    text = re.sub(r"^CP\d+\s*—\s*", "", text, flags=re.IGNORECASE)
    text = re.sub(r"[^a-zA-Z0-9]+", "_", text.lower()).strip("_")
    return text[:max_len].strip("_") or "caso"


def rf_num(group: str) -> str:
    m = re.match(r"(RF-\d+)", group)
    return m.group(1).replace("-", "").lower() if m else "rf000"


def cp_num(title: str) -> str:
    m = re.match(r"(CP\d+)", title, re.IGNORECASE)
    return m.group(1).lower() if m else "cp00"


def extract_tests(content: str) -> list[tuple[str, str, str, str]]:
    """Returns list of (group, title, body, rf_comment)."""
    items: list[tuple[str, str, str, str]] = []
    current_group = ""
    rf_comment = ""
    lines = content.split("\n")
    i = 0
    while i < len(lines):
        line = lines[i]
        gm = re.match(r"^// (RF-\d+:.+)$", line.strip())
        if gm:
            rf_comment = gm.group(1)
        gm2 = re.match(r"\s*group\('([^']+)'", line)
        if gm2:
            current_group = gm2.group(1)
        tm = re.match(r"\s*test\('([^']+)',\s*\(\)\s*\{", line)
        if tm:
            title = tm.group(1)
            block = [lines[i]]
            i += 1
            depth = 1
            while i < len(lines) and depth > 0:
                block.append(lines[i])
                if re.search(r"\(\)\s*\{", lines[i]) and "test(" in lines[i]:
                    depth += 1
                if lines[i].strip() == "});":
                    depth -= 1
                i += 1
            body = "\n".join(block[1:-1])
            items.append((current_group, title, body, rf_comment))
            continue
        i += 1
    return items


def main() -> None:
    if not SRC.exists():
        raise SystemExit(f"No existe {SRC}")

    content = SRC.read_text(encoding="utf-8")
    tests = extract_tests(content)
    if not tests:
        raise SystemExit("No se encontraron tests")

    if OUT.exists():
        for old in OUT.glob("*.dart"):
            old.unlink()
    else:
        OUT.mkdir(parents=True)

    for group, title, body, rf_comment in tests:
        rf = rf_num(group)
        cp = cp_num(title)
        name_slug = slug(title)
        filename = f"{rf}_{cp}_{name_slug}_test.dart"
        file_content = (
            HEADER
            + f"\n// {rf_comment or group}\n"
            + f"// {title}\n\n"
            + "void main() {\n"
            + f"  test('{title}', () {{\n"
            + body
            + "\n  });\n"
            + "}\n"
        )
        (OUT / filename).write_text(file_content, encoding="utf-8")

    print(f"Generados {len(tests)} archivos en {OUT.relative_to(ROOT)}")


if __name__ == "__main__":
    main()
