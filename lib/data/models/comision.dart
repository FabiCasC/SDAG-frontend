class Comision {
  const Comision({
    required this.id,
    required this.fecha,
    required this.recaudado,
    required this.comision,
    required this.estado,
  });

  final String id;
  final DateTime fecha;
  final double recaudado;
  final double comision;
  final String estado;
}
