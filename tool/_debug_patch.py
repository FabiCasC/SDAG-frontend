import re
from pathlib import Path

c = Path(__file__).resolve().parent.parent / "test" / "sdag_todos_los_rf_test.dart"
content = c.read_text(encoding="utf-8")
OLD_ACT = re.compile(
    r"\s*// Act — ejecutar la validación / regla de la app\n"
    r"\s*final resultado1 = PassengerAuthValidators\.validateRequiredField\('dato'\);\n"
    r"\s*final resultado2 = PassengerAuthValidators\.validateRequiredField\(null\) != null;\n"
    r"\s*// Assert — verificar el resultado esperado del CP\n"
    r"\s*expect\(resultado1, is(?:True|Null)\);\n"
    r"\s*expect\(resultado2, isTrue\);",
    re.MULTILINE,
)
print("OLD_ACT matches:", len(OLD_ACT.findall(content)))
BLOCK = re.compile(
    r"(test\('(?P<title>[^']+)',\s*\(\)\s*\{)(?P<body>.*?)(print\('  .*?'\);\s*\n\s*\}\);)",
    re.DOTALL,
)
ms = [m for m in BLOCK.finditer(content) if "validateRequiredField('dato')" in m.group("body")]
print("BLOCK matches with dato:", len(ms))
if ms:
    print("first:", ms[0].group("title"))
    print("OLD in body:", bool(OLD_ACT.search(ms[0].group("body"))))
