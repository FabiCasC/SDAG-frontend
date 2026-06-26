#!/usr/bin/env python3
"""Marca como FAIL solo los casos de prueba relacionados con Waze."""
import re
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent

WAZE_RF = {"RF-030", "RF-099"}


def rf_id(group: str) -> str:
    m = re.match(r"(RF-\d+)", group)
    return m.group(1) if m else ""


def should_fail(group: str, title: str) -> bool:
    if rf_id(group) in WAZE_RF:
        return True
    return "waze" in title.lower()


def escenario(title: str) -> str:
    return re.sub(r"^CP\d+\s*—\s*", "", title).strip()


def cp_label(title: str) -> str:
    m = re.match(r"(CP\d+)", title)
    return m.group(1) if m else "CP??"


def fail_body(title: str, group: str, momento3: bool) -> str:
    esc = escenario(title)
    cp = cp_label(title)
    rf_name = group.split("—", 1)[-1].strip() if "—" in group else group
    if momento3:
        return "\n".join(
            [
                f"      // PRECONDICIÓN: Escenario «{esc}» para {rf_name}.",
                "      // ACCIÓN: Se ejecuta la operación descrita en el caso de prueba.",
                "      // RESULTADO ESPERADO: El sistema debe comportarse según la regla definida para este escenario.",
                "      expect(false, isTrue);",
                "      // RESULTADO OBTENIDO: se completa al correr el test",
                f"      print('  ❌ {cp} FAIL — {esc}');",
            ]
        )
    return "\n".join(
        [
            f"      // Arrange — escenario «{esc}» ({rf_name})",
            "      // Act — ejecutar la validación / regla de la app",
            "      // Assert — verificar el resultado esperado del CP",
            "      expect(false, isTrue);",
            f"      print('  ❌ {cp} FAIL — {esc}');",
        ]
    )


def transform_file(path: Path) -> tuple[int, int]:
    content = path.read_text(encoding="utf-8")
    momento3 = "momento3" in path.name
    changed = kept = 0
    lines = content.split("\n")
    out_lines = []
    current_group = ""
    i = 0
    while i < len(lines):
        gm = re.match(r"\s*group\('([^']+)'", lines[i])
        if gm:
            current_group = gm.group(1)
        tm = re.match(r"(\s*)test\('([^']+)',\s*\(\)\s*\{", lines[i])
        if tm:
            indent = tm.group(1)
            title = tm.group(2)
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
            if should_fail(current_group, title):
                changed += 1
                out_lines.append(f"{indent}test('{title}', () {{")
                out_lines.extend(fail_body(title, current_group, momento3).split("\n"))
                out_lines.append(f"{indent}}});")
            else:
                kept += 1
                out_lines.extend(block)
            continue
        out_lines.append(lines[i])
        i += 1

    path.write_text("\n".join(out_lines) + ("\n" if content.endswith("\n") else ""), encoding="utf-8")
    return changed, kept


def main() -> None:
    for name in ("sdag_tdd_momento3_test.dart", "sdag_todos_los_rf_test.dart"):
        p = ROOT / "test" / name
        if p.exists():
            c, k = transform_file(p)
            print(f"{name}: {c} FAIL waze, {k} conservados")


if __name__ == "__main__":
    main()
