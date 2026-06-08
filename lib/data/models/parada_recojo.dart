class ParadaRecojo {
  const ParadaRecojo({
    required this.id,
    required this.direccion,
    required this.pasajeros,
  });

  final String id;
  final String direccion;
  final List<String> pasajeros; // IDs de pasajeros
}
