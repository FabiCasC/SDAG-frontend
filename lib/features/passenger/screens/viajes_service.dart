import 'package:supabase_flutter/supabase_flutter.dart';

/// Servicio que maneja todas las consultas de viajes a Supabase.
/// Separa la lógica de base de datos de la interfaz visual.
class ViajesService {
  /// Cliente de Supabase (singleton global)
  final _supabase = Supabase.instance.client;

  /// Busca viajes disponibles según la dirección seleccionada por el pasajero.
  /// 
  /// [direccion] puede ser:
  /// - 'san_isidro_chosica' → viajes de San Isidro hacia Chosica
  /// - 'chosica_san_isidro' → viajes de Chosica hacia San Isidro
  /// 
  /// Solo devuelve viajes en estado 'esperando' o 'en_ruta'.
  /// Ordenados por hora de salida más próxima.
  Future<List<Map<String, dynamic>>> buscarViajesDisponibles({
    required String direccion,
  }) async {
    final response = await _supabase
        .from('viajes')
        .select('''
          id,
          direccion,
          ruta,
          estado,
          asientos_ocupados,
          hora_salida,
          vehiculos (
            capacidad,
            tipo,
            placa
          ),
          conductores (
            nombre
          )
        ''')
        .inFilter('estado', ['esperando', 'en_ruta'])
        .eq('direccion', direccion)
        .order('hora_salida', ascending: true);

    return List<Map<String, dynamic>>.from(response);
  }
}