import re
from pathlib import Path

t = Path("test/sdag_tdd_momento3_test.dart").read_text(encoding="utf-8")
test_blocks = re.findall(r"test\('([^']+)',\s*\(\)\s*\{(.*?)\n    \}\);", t, re.DOTALL)
print("Total tests:", len(test_blocks))
print("validarCampoRequerido(campoOk):", t.count("validarCampoRequerido(campoOk"))
print("validarCampoRequerido(campoDato):", t.count("validarCampoRequerido(campoDato"))

real_patterns = [
    r"validarTelefono\(",
    r"validarDNI\(",
    r"flujoRegistro|flujoLogin|flujoPerfil|validacionFormatoEmail",
    r"flujoPago|resultadoPagoCulqi|calcularMonto|validacionFormatoPago",
    r"flujoQR|puedeEscanearQR|generarQR",
    r"reembolsoPosible|bajadaPermitida",
    r"validarPorcentajeComision",
    r"conductorElegible|asientoPuede|vehiculoLleno",
    r"mapRegistro|mapAuth|mapPlaca|mensajeCuenta",
    r"validarPuntoRecojo|flujoPuntoRecojo",
    r"resultadoSinConexion",
    r"lista\.isEmpty",
    r"accionSesionExpirada|pagoReservaCompletado|mensajeConductor",
    r"flujoTarifa",
]

real = fake = mixed = 0
for title, body in test_blocks:
    is_real = any(re.search(p, body) for p in real_patterns)
    is_fake = "validarCampoRequerido(campoOk" in body or (
        "validarCampoRequerido(campoDato" in body
        and "validacionCamposIncompletos" in body
        and not is_real
    )
    if is_real and not is_fake:
        real += 1
    elif is_fake and not is_real:
        fake += 1
    else:
        mixed += 1

print("Real (logica de dominio):", real)
print("Placeholder generico:", fake)
print("Mixto/otro:", mixed)
