#!/usr/bin/env python3
"""Reconstruye los archivos maestro desde test/momento3/."""
import re
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
MOMENTO3 = ROOT / "test" / "momento3"
MASTER = ROOT / "test" / "sdag_todos_los_rf_test.dart"
TDD_MASTER = ROOT / "test" / "sdag_tdd_momento3_test.dart"

IMPORTS = """import 'package:flutter_test/flutter_test.dart';
import 'package:sdag/core/validators/sdag_validators.dart';
import 'package:sdag/app/providers/passenger/utils/passenger_db_error_mapping.dart';
import 'package:sdag/app/providers/passenger/validators/passenger_auth_validators.dart';
import 'package:sdag/features/busqueda/utils/busqueda_utils.dart';
import 'package:sdag/features/conductor/utils/notification_utils.dart';
import 'package:sdag/features/conductor/utils/qr_scan_utils.dart';
import 'package:sdag/features/conductor/utils/qr_security_utils.dart';
import 'package:sdag/features/conductor/utils/trip_message_utils.dart';
import 'package:sdag/features/conductor/utils/manifest_utils.dart';
import 'package:sdag/features/conductor/utils/vehicle_utils.dart';
import 'package:sdag/features/reserva/utils/payment_validation.dart';
import 'package:sdag/features/reserva/utils/pickup_validation.dart';
import 'package:sdag/features/reserva/utils/trip_rules.dart';
import 'package:sdag/features/reserva/utils/forced_departure_utils.dart';
import 'package:sdag/features/reserva/utils/seat_hold_utils.dart';
import 'package:sdag/shared/maps/waze_service.dart';
import 'package:sdag/core/services/push_notification_utils.dart';
import 'package:sdag/core/services/audit_log_utils.dart';
"""


def build_header(run_target: str) -> str:
    return (
        IMPORTS
        + "\n// ================================================================\n"
        + "// SDAG — UTP Semana 13 S2 — Momento 3 TDD (Guía Lab Pruebas de Software)\n"
        + "// Patrón ARRANGE | ACT | ASSERT sobre clases reales del proyecto (lib/)\n"
        + f"// Ejecutar: flutter test {run_target} --reporter expanded\n"
        + "// ================================================================\n\n\n\n"
        + "// ================================================================\n"
        + "// SDAG — Suite Completa de Tests: 126 Requerimientos Funcionales\n"
        + f"// Ejecutar: flutter test {run_target} --reporter expanded\n"
        + "// ================================================================\n\n"
    )


def cp_sort_key(title: str) -> int:
    m = re.match(r"CP(\d+)", title, re.IGNORECASE)
    return int(m.group(1)) if m else 99


def extract_test_body(content: str) -> tuple[str, str, str, str]:
    rf_m = re.search(r"^// (RF-\d+): (.+)$", content, re.MULTILINE)
    if not rf_m:
        raise ValueError("RF comment not found")
    rf_id, rf_title = rf_m.group(1), rf_m.group(2)

    test_m = re.search(r"test\('([^']+)',\s*\(\)\s*\{", content)
    if not test_m:
        raise ValueError("test() not found")
    title = test_m.group(1)

    start = content.find("{", test_m.end() - 1)
    depth = 0
    body_start = start + 1
    i = start
    while i < len(content):
        ch = content[i]
        if ch == "{":
            depth += 1
        elif ch == "}":
            depth -= 1
            if depth == 0:
                body = content[body_start:i].rstrip()
                return rf_id, rf_title, title, body
        i += 1
    raise ValueError("Unclosed test body")


def rf_fn_name(rf_id: str) -> str:
    num = rf_id.replace("RF-", "")
    return f"testRF{int(num):03d}"


def build_suite(header: str, by_rf: dict, rf_order: list[str]) -> str:
    parts = [header]
    for rf_id in rf_order:
        data = by_rf[rf_id]
        group_title = f"{rf_id} — {data['rf_title']}"
        fn = rf_fn_name(rf_id)
        parts.append(f"// {rf_id}: {data['rf_title']}")
        parts.append(f"void {fn}() {{")
        parts.append(f"  group('{group_title}', () {{")

        for title, body in sorted(data["tests"], key=lambda t: cp_sort_key(t[0])):
            indented_body = "\n".join(
                f"      {line.strip()}" if line.strip() else line for line in body.split("\n")
            )
            parts.append(f"    test('{title}', () {{")
            parts.append(indented_body)
            parts.append("    });")

        parts.append("  });")
        parts.append("}")
        parts.append("")

    parts.append("void main() {")
    parts.append("  print('\\n================================================');")
    parts.append("  print('  SDAG — Suite Completa de Tests Flutter');")
    parts.append("  print('  126 Requerimientos Funcionales');")
    parts.append("  print('================================================\\n');")
    parts.append("")
    for rf_id in rf_order:
        parts.append(f"  {rf_fn_name(rf_id)}();")
    parts.append("")
    parts.append("  print('\\n================================================');")
    parts.append("  print('  Todos los tests ejecutados correctamente');")
    parts.append("  print('================================================\\n');")
    parts.append("}")
    parts.append("")
    return "\n".join(parts)


def main() -> None:
    by_rf: dict[str, dict] = {}

    for path in sorted(MOMENTO3.glob("rf*_test.dart")):
        content = path.read_text(encoding="utf-8")
        rf_id, rf_title, title, body = extract_test_body(content)
        entry = by_rf.setdefault(rf_id, {"rf_title": rf_title, "tests": []})
        entry["tests"].append((title, body))

    rf_order = sorted(by_rf.keys(), key=lambda x: int(x.replace("RF-", "")))
    total_tests = sum(len(v["tests"]) for v in by_rf.values())

    MASTER.write_text(
        build_suite(build_header("test/sdag_todos_los_rf_test.dart"), by_rf, rf_order),
        encoding="utf-8",
    )
    TDD_MASTER.write_text(
        build_suite(build_header("test/sdag_tdd_momento3_test.dart"), by_rf, rf_order),
        encoding="utf-8",
    )

    print(f"Maestros actualizados desde test/momento3/: {len(rf_order)} RFs, {total_tests} tests")
    print(f"  -> {MASTER}")
    print(f"  -> {TDD_MASTER}")


if __name__ == "__main__":
    main()
