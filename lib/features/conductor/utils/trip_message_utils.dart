/// Reglas de mensajes de chat del viaje (RF-016, RF-032, RF-107).

bool mensajeChatValido(String texto) {
  final t = texto.trim();
  return t.isNotEmpty && t.length >= 2;
}

bool mensajeArchivadoEsHistorico(String messageStatus) {
  return messageStatus.trim().toLowerCase() == 'archivado';
}

bool mensajeActivoEnChat(String messageStatus) {
  final s = messageStatus.trim().toLowerCase();
  return s.isEmpty || s == 'activo';
}
