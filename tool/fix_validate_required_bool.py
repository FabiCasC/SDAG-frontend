#!/usr/bin/env python3
import re
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent / "test"

for name in ("sdag_tdd_momento3_test.dart", "sdag_todos_los_rf_test.dart"):
    p = ROOT / name
    c = p.read_text(encoding="utf-8")
    c = c.replace(
        "PassengerAuthValidators.validateRequiredField('dato') != null",
        "PassengerAuthValidators.validateRequiredField('dato')",
    )
    c = c.replace(
        "PassengerAuthValidators.validateRequiredField('ok') != null",
        "PassengerAuthValidators.validateRequiredField('ok')",
    )
    c = c.replace(
        "mensajeCuentaBloqueada(cuentaBloqueada)",
        "blockedAccountMessage(accountActive: !cuentaBloqueada)",
    )
    c = re.sub(
        r"// =+\n// SDAG — Semana 13 UTP — Momento 3.*?\n// =+\n\n",
        "",
        c,
        count=1,
        flags=re.DOTALL,
    )
    p.write_text(c, encoding="utf-8")
    print(f"fixed {name}")
