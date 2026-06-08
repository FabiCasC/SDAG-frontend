class ManifiestoPasajero {
  const ManifiestoPasajero({
    required this.id,
    required this.nombres,
    required this.apellidos,
    required this.dni,
    required this.telefono,
    required this.asiento,
    required this.puntoRecojo,
    required this.abordo,
  });

  final String id;
  final String nombres;
  final String apellidos;
  final String dni;
  final String telefono;
  final int asiento;
  final String puntoRecojo;
  final bool abordo;

  ManifiestoPasajero copyWith({
    String? id,
    String? nombres,
    String? apellidos,
    String? dni,
    String? telefono,
    int? asiento,
    String? puntoRecojo,
    bool? abordo,
  }) {
    return ManifiestoPasajero(
      id: id ?? this.id,
      nombres: nombres ?? this.nombres,
      apellidos: apellidos ?? this.apellidos,
      dni: dni ?? this.dni,
      telefono: telefono ?? this.telefono,
      asiento: asiento ?? this.asiento,
      puntoRecojo: puntoRecojo ?? this.puntoRecojo,
      abordo: abordo ?? this.abordo,
    );
  }
}
