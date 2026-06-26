/// Validación del punto de recojo (formularios de reserva).
String? validatePickupPoint(String? value) {
  if (value == null || value.trim().isEmpty) return 'Campo vacío';
  if (value.trim().length < 3) return 'Texto demasiado corto';
  return null;
}
