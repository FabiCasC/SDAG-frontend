#!/usr/bin/env python3
import re
from pathlib import Path
lines = Path("test/sdag_todos_los_rf_test.dart").read_text(encoding="utf-8").split("\n")
current_rf = ""
for i, line in enumerate(lines):
    m = re.match(r"// (RF-\d+):", line.strip())
    if m:
        current_rf = m.group(1)
    if "validateRequiredField('ok')" in line:
        print(current_rf)
