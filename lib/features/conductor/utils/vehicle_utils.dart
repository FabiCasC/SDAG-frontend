/// Validación de vehículos vinculados al conductor (RF-043, RF-089, RF-090).

bool vehiculoRegistroValido({
  required String plate,
  required int totalSeats,
  String label = '',
}) {
  if (plate.trim().isEmpty) return false;
  if (totalSeats <= 0 || totalSeats > 99) return false;
  return true;
}

String etiquetaModeloVehiculo({required String label, required String vehicleType}) {
  if (label.trim().isNotEmpty) return label.trim();
  if (vehicleType.trim().isNotEmpty) return vehicleType.trim();
  return '—';
}

bool vehiculoActivoEnHistorico({required bool active}) => active;
