import re
from pathlib import Path

p = Path(__file__).resolve().parent.parent / "test" / "sdag_todos_los_rf_test.dart"
c = p.read_text(encoding="utf-8")

c = re.sub(
    r"      const entradaArg10 = ocupados: (\d+);\n"
    r"      const entradaArg11 = capacidad: (\d+);\n"
    r"      // Act — ejecutar la validación / regla de la app\n"
    r"      final resultado1 = vehiculoLlenoParaSalir\(entradaArg10, entradaArg11\);",
    r"      const ocupadosVehiculo = \1;\n"
    r"      const capacidadVehiculo = \2;\n"
    r"      // Act — ejecutar la validación / regla de la app\n"
    r"      final resultado1 = vehiculoLlenoParaSalir("
    r"ocupados: ocupadosVehiculo, capacidad: capacidadVehiculo);",
    c,
)

c = re.sub(
    r"      const entradaArg10 = ocupados: (\d+);\n"
    r"      const entradaArg11 = capacidad: (\d+);\n"
    r"      const entradaArg12 = salidaForzadaAceptada: true;\n"
    r"      // Act — ejecutar la validación / regla de la app\n"
    r"      final resultado1 = vehiculoLlenoParaSalir\(entradaArg10, entradaArg11, entradaArg12\);",
    r"      const ocupadosVehiculo = \1;\n"
    r"      const capacidadVehiculo = \2;\n"
    r"      const salidaForzadaAceptada = true;\n"
    r"      // Act — ejecutar la validación / regla de la app\n"
    r"      final resultado1 = vehiculoLlenoParaSalir("
    r"ocupados: ocupadosVehiculo, capacidad: capacidadVehiculo, "
    r"salidaForzadaAceptada: salidaForzadaAceptada);",
    c,
)

p.write_text(c, encoding="utf-8")
remaining = c.count("entradaArg10 = ocupados")
print(f"Restantes rotos: {remaining}")
