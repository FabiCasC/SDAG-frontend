import re
from pathlib import Path

p = Path(__file__).resolve().parent.parent / "test" / "sdag_todos_los_rf_test.dart"
lines = p.read_text(encoding="utf-8").split("\n")
rf = ""
for i, line in enumerate(lines):
    m = re.match(r"// (RF-\d+):", line.strip())
    if m:
        rf = m.group(1)
    tm = re.search(r"test\('([^']+)'", line)
    if tm:
        block = "\n".join(lines[i : i + 20])
        if "validateRequiredField('dato')" in block:
            print(f"{rf} | {tm.group(1)}")
