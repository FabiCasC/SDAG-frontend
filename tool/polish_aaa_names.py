"""Mejora nombres de variables AAA en tests RF."""
from pathlib import Path

p = Path(__file__).resolve().parent.parent / "test" / "sdag_todos_los_rf_test.dart"
c = p.read_text(encoding="utf-8")

replacements = [
    ("const telefono1234510 = '12345';", "const telefonoInvalido = '12345';"),
    ("validarTelefono(telefono1234510)", "validarTelefono(telefonoInvalido)"),
    ("const telefono98765432120 = '987654321';", "const telefonoValido = '987654321';"),
    ("validarTelefono(telefono98765432120)", "validarTelefono(telefonoValido)"),
    ("const campoVacio10 = null;", "const campoNulo = null;"),
    ("validacionCamposIncompletos(campoVacio10)", "validacionCamposIncompletos(campoNulo)"),
    ("validarDNI(campoVacio10)", "validarDNI(campoNulo)"),
    ("validarCampoRequerido(campoVacio10)", "validarCampoRequerido(campoNulo)"),
    ("validarPuntoRecojo(campoVacio10)", "validarPuntoRecojo(campoNulo)"),
    ("const campoValor2020 = '';", "const campoVacio = '';\n"),
    ("validacionCamposIncompletos(campoValor2020)", "validacionCamposIncompletos(campoVacio)"),
    ("validarDNI(campoValor2020)", "validarDNI(campoVacio)"),
    ("validarCampoRequerido(campoValor2020)", "validarCampoRequerido(campoVacio)"),
    ("validarPuntoRecojo(campoValor2020)", "validarPuntoRecojo(campoVacio)"),
    (
        "const mensajeDbEmailalreadyregister10 = 'email already registered';",
        "const mensajeEmailDuplicado = 'email already registered';",
    ),
    (
        "mapRegistroErrorDuplicado(mensajeDbEmailalreadyregister10)",
        "mapRegistroErrorDuplicado(mensajeEmailDuplicado)",
    ),
    ("const tipoErrorAuthexception10 = 'AuthException';", "const tipoAuthException = 'AuthException';"),
    ("mapAuthExceptionError(tipoErrorAuthexception10)", "mapAuthExceptionError(tipoAuthException)"),
    ("const cuentaBloqueadaFlag10 = true;", "const cuentaBloqueada = true;"),
    ("mensajeCuentaBloqueada(cuentaBloqueadaFlag10)", "mensajeCuentaBloqueada(cuentaBloqueada)"),
    ("const dni123410 = '1234';", "const dniInvalido = '1234';"),
    ("validarDNI(dni123410)", "validarDNI(dniInvalido)"),
    ("const dni1234567820 = '12345678';", "const dniValido = '12345678';"),
    ("validarDNI(dni1234567820)", "validarDNI(dniValido)"),
    ("const puntoRecojo10 = '';", "const puntoRecojoVacio = '';"),
    ("validarPuntoRecojo(puntoRecojo10)", "validarPuntoRecojo(puntoRecojoVacio)"),
    ("const codigoHttp10 = 400;", "const codigoHttpError = 400;"),
    ("const mensajePago10 = 'Tarjeta rechazada';", "const mensajeTarjetaRechazada = 'Tarjeta rechazada';"),
    (
        "resultadoPagoCulqi(codigoHttp10, mensajePago10)",
        "resultadoPagoCulqi(codigoHttpError, mensajeTarjetaRechazada)",
    ),
    ("const codigoHttp20 = 201;", "const codigoHttpOk = 201;"),
    ("const mensajePago20 = null;", "const mensajePagoOk = null;"),
    ("resultadoPagoCulqi(codigoHttp20, mensajePago20)", "resultadoPagoCulqi(codigoHttpOk, mensajePagoOk)"),
    ("const sesionActivaFlag10 = false;", "const sesionActiva = false;"),
    ("accionSesionExpirada(sesionActivaFlag10)", "accionSesionExpirada(sesionActiva)"),
    ("const conectadoFlag10 = false;", "const hayConexion = false;"),
    ("const conectadoFlag20 = true;", "const hayConexion = true;"),
    ("resultadoSinConexion(conectadoFlag10)", "resultadoSinConexion(hayConexion)"),
    ("const estadoViajeEnruta10 = 'en_ruta';", "const estadoViajeEnRuta = 'en_ruta';"),
    ("reembolsoPosible(estadoViajeEnruta10)", "reembolsoPosible(estadoViajeEnRuta)"),
    ("mensajeConductorNoDisponible(estadoViajeEnruta10)", "mensajeConductorNoDisponible(estadoViajeEnRuta)"),
    ("const estadoViajeEsperando20 = 'esperando';", "const estadoViajeEsperando = 'esperando';"),
    ("reembolsoPosible(estadoViajeEsperando20)", "reembolsoPosible(estadoViajeEsperando)"),
]

for old, new in replacements:
    c = c.replace(old, new)

p.write_text(c, encoding="utf-8")
print("Nombres mejorados")
