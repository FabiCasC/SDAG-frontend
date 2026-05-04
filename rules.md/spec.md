ESPECIFICACIÓN TÉCNICA: PERFIL CONTROLADOR - PROYECTO SDAG

Este documento contiene las reglas de negocio, requerimientos y guías de diseño para la implementación del rol de Controlador en el ecosistema SDAG.

1. Identidad Visual (Design System)

Debe respetarse estrictamente la paleta de colores y tipografía definida en el Figma:

Primary Blue: #2563EB (Navegación activa, botones primarios).

Energetic Orange: #F97316 (Alertas críticas de documentos vencidos, CTAs de riesgo).

Background Light: #F8FAFC (Fondo de pantallas).

Text Primary: #314158 | Text Secondary: #62748E.

Tipografía: Inter (Bold para títulos, Regular para cuerpo).

2. Estructura de Navegación (RF 81)

La aplicación para el controlador debe usar un BottomNavigationBar con tres secciones:

Despacho: Activación instantánea de unidades.

Historial: Auditoría y logs de actividad.

Ranking: Dashboard de productividad y viajes.

3. Matriz de Requerimientos Funcionales (RF 81 - 90)

ID

Requerimiento

Lógica de Funcionamiento

RF 81

Navegación

3 pestañas fijas con iconos lineales y labels descriptivos.

RF 82

Buscador Despacho

Campo de búsqueda en la Pestaña 1 que filtra conductores por placa en tiempo real.

RF 83

Switch de Operatividad

Botones "Activar" y "Desactivar" para habilitar el uso de la app al conductor.

RF 84

Verificación Legal

Al pulsar "Activar", el sistema debe validar si el SOAT o Licencia están vigentes en la BD.

RF 85

Alerta Full Screen

Si hay documentos vencidos, mostrar modal naranja a pantalla completa con detalles técnicos.

RF 86

Log de Auditoría

Si el controlador pulsa "CONTINUAR" en la alerta, registrar la decisión en la colección audit_logs.

RF 87

Buscador Historial

Campo de búsqueda en la Pestaña 2 para filtrar el log operativo por número de placa.

RF 88

Visualización Auditoría

En el historial, resaltar con iconos de advertencia los registros activados con bypass legal.

RF 89

Filtros Temporales

Botones de acceso rápido para segmentar datos por Día, Semana o Mes.

RF 90

Dashboard Ranking

Ranking visual de conductores con más viajes despachados exitosamente.


#,Nombre del requerimiento,Descripción,CUS,Prioridad
RF 91,Acceso por DNI (Controlador),Validación local de DNI 999999 y clave controlador para permitir el ingreso al perfil y redirección a ControllerMainPage.,CU-C01,Alta
4. Lógica de Firebase (Firestore)

Activación: Al activar/desactivar, cambiar el campo status o is_online en el documento del conductor dentro de la colección users.

Estructura del Log (audit_logs):

{
  "controller_id": "string",
  "driver_id": "string",
  "plate": "string",
  "timestamp": "FieldValue.serverTimestamp()",
  "alert_accepted": true,
  "expired_documents": ["SOAT", "Licencia"],
  "action": "manual_activation_bypass"
}


5. Instrucciones de Implementación (Prompts por Bloques)

Bloque 1: Configuración de ThemeData y colores globales.

Bloque 2: Estructura de la pantalla principal y BottomNavigationBar.

Bloque 3: Vista de Despacho, Buscador y lógica del Modal Naranja de advertencia.

Bloque 4: Vista de Historial con filtros de tiempo y visualización de logs auditados.

Bloque 5: Vista de Dashboard con el ranking de conductores.

IMPORTANTE: No ignores el contraste de colores. La alerta naranja debe ser disruptiva y cubrir toda la pantalla para asegurar que el controlador es consciente del riesgo legal.