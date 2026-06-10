import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../shared/design/app_colors.dart';
import '../../../shared/design/app_spacing.dart';
import '../../../shared/design/app_radius.dart';
import '../../passenger/screens/viajes_service.dart';
import '../../conductor/providers/conductor_auth_provider.dart';

/// Pantalla principal del chofer donde visualiza sus reservas asignadas.
class DriverDashboardScreen extends ConsumerStatefulWidget {
  const DriverDashboardScreen({super.key});

  @override
  ConsumerState<DriverDashboardScreen> createState() => _DriverDashboardScreenState();
}

class _DriverDashboardScreenState extends ConsumerState<DriverDashboardScreen> {
  final _viajesService = ViajesService();
  bool _isLoading = true;
  List<Map<String, dynamic>> _reservas = [];
  int _totalCapacity = 0;
  int _occupiedSeatsCount = 0;

  @override
  void initState() {
    super.initState();
    _fetchReservas();
  }

  /// Obtiene las reservas filtradas por el ID del chofer autenticado.
  Future<void> _fetchReservas() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) {
         setState(() => _isLoading = false);
         return;
      }

      // Obtenemos el driver_id asociado al perfil del usuario actual
      final driverData = await Supabase.instance.client
          .from('drivers')
          .select('id')
          .eq('profile_id', user.id)
          .maybeSingle();

      if (driverData != null) {
        final driverId = driverData['id'].toString();
        final data = await _viajesService.obtenerReservasPorConductor(driverId);
        if (mounted) {
          setState(() {
            _reservas = data;
            
            // Calculamos la capacidad total desde el viaje asignado en la DB
            if (data.isNotEmpty) {
              final tripData = data.first['trips'] as Map<String, dynamic>?;
              final driverInfo = tripData?['drivers'] as Map<String, dynamic>?;
              _totalCapacity = int.tryParse(driverInfo?['capacity']?.toString() ?? '14') ?? 14;
            } else {
              _totalCapacity = 14; 
            }

            // Calculamos asientos ocupados sumando los asientos de cada reserva real
            _occupiedSeatsCount = data.fold(0, (sum, res) {
              final seatsList = res['seats'] as List?;
              return sum + (seatsList?.length ?? 0);
            });

            _isLoading = false;
          });
        }
      } else {
        if (mounted) setState(() => _isLoading = false);
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        title: const Text('Mis Reservas', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: AppColors.primaryBlue,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: RefreshIndicator(
        onRefresh: _fetchReservas,
        color: AppColors.primaryBlue,
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.md),
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            if (_isLoading)
              SizedBox(
                height: MediaQuery.of(context).size.height * 0.7,
                child: const Center(child: CircularProgressIndicator(color: AppColors.primaryBlue)),
              )
            else ...[
              _buildStatusHeader(),
              const SizedBox(height: AppSpacing.lg),
              _buildSeatMonitor(),
              const SizedBox(height: AppSpacing.lg),
              const Text(
                'Lista de Pasajeros',
                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18, color: AppColors.textPrimary),
              ),
              const SizedBox(height: AppSpacing.md),
              if (_reservas.isEmpty) _buildEmptyState() else ..._buildReservasItems(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatusHeader() {
    final auth = ref.watch(conductorAuthProvider);
    final statusText = auth.estadoActual == ConductorEstadoActual.activo 
        ? 'Esperando pasajeros' 
        : 'En espera de despacho';
    
    return Column(
      children: [
        Text(
          statusText,
          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: AppColors.primaryBlue),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          '$_occupiedSeatsCount/$_totalCapacity asientos ocupados',
          style: const TextStyle(fontSize: 16, color: AppColors.textSecondary, fontWeight: FontWeight.w600),
        ),
      ],
    );
  }

  Widget _buildSeatMonitor() {
    // Identificamos visualmente qué números de asiento están tomados
    final occupiedSeats = <int>{};
    for (var res in _reservas) {
      final seats = res['seats'] as List?;
      if (seats != null) {
        for (var s in seats) {
          if (s is int) occupiedSeats.add(s);
        }
      }
    }

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppRadius.r16),
        border: Border.all(color: AppColors.border),
      ),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 4,
          mainAxisSpacing: AppSpacing.sm,
          crossAxisSpacing: AppSpacing.sm,
        ),
        itemCount: _totalCapacity > 0 ? _totalCapacity : 14,
        itemBuilder: (context, index) {
          final seatNumber = index + 1;
          final isOccupied = occupiedSeats.contains(seatNumber);
          
          return Container(
            decoration: BoxDecoration(
              color: isOccupied ? AppColors.primaryBlue : AppColors.backgroundLight,
              borderRadius: BorderRadius.circular(AppRadius.r8),
              border: Border.all(color: isOccupied ? AppColors.primaryBlue : AppColors.border),
            ),
            child: Center(
              child: Text(
                '$seatNumber',
                style: TextStyle(
                  color: isOccupied ? Colors.white : AppColors.textSecondary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Column(
      children: [
        SizedBox(height: MediaQuery.of(context).size.height * 0.3),
        Center(
          child: Column(
            children: [
              Icon(Icons.assignment_late_outlined, size: 80, color: AppColors.textSecondary.withOpacity(0.3)),
              const SizedBox(height: AppSpacing.md),
              Text(
                'No tienes reservas asignadas',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(color: AppColors.textSecondary),
              ),
            ],
          ),
        ),
      ],
    );
  }

  List<Widget> _buildReservasItems() {
    return List.generate(
      _reservas.length,
      (index) {
        final res = _reservas[index];
        final profile = res['profiles'] as Map<String, dynamic>?;
        final trip = res['trips'] as Map<String, dynamic>?;
        final route = trip?['routes'] as Map<String, dynamic>?;
        
        final passengerName = profile?['full_name'] ?? 'Pasajero';
        final status = res['status'] ?? 'pending';
        final timeStr = trip?['scheduled_departure_at'] ?? '';
        final seats = _parseSeats(res['seats']);

        return Card(
          margin: const EdgeInsets.only(bottom: AppSpacing.md),
          elevation: 2,
          shadowColor: AppColors.shadow,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.r16)),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      passengerName,
                      style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 17, color: AppColors.textPrimary),
                    ),
                    _StatusBadge(status: status),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),
                Row(
                  children: [
                    const Icon(Icons.location_on_outlined, size: 16, color: AppColors.primaryBlue),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        '${route?['from_label'] ?? '...'} → ${route?['to_label'] ?? '...'}',
                        style: const TextStyle(color: AppColors.textSecondary, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
                const Divider(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _InfoItem(icon: Icons.access_time_rounded, label: 'Salida', value: _formatTime(timeStr)),
                    _InfoItem(icon: Icons.airline_seat_recline_normal_rounded, label: 'Asientos', value: seats),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  String _formatTime(String isoDate) {
    if (isoDate.isEmpty) return '--:--';
    try {
      final dt = DateTime.parse(isoDate).toLocal();
      final hour = dt.hour > 12 ? dt.hour - 12 : (dt.hour == 0 ? 12 : dt.hour);
      final ampm = dt.hour >= 12 ? 'PM' : 'AM';
      return '${hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')} $ampm';
    } catch (_) {
      return isoDate;
    }
  }

  /// Parsea la información de los asientos de forma segura.
  /// Maneja casos donde los datos vienen como List<int>, List<dynamic> o null.
  String _parseSeats(dynamic seatsData) {
    if (seatsData == null) return 'N/A';
    
    if (seatsData is List) {
      if (seatsData.isEmpty) return 'Sin asignar';
      // Convertimos cada elemento a String y los unimos
      return seatsData.map((s) => s.toString()).join(', ');
    }
    
    // Si es un valor único (no lista), lo devolvemos como string
    final strValue = seatsData.toString();
    return strValue.isEmpty ? 'N/A' : strValue;
  }
}

/// Badge visual para mostrar el estado de la reserva.
class _StatusBadge extends StatelessWidget {
  final String status;
  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    final (color, label) = switch (status) {
      'pending' => (AppColors.warning, 'PENDIENTE'),
      'confirmed' => (AppColors.success, 'CONFIRMADO'),
      'boarded' => (AppColors.primaryBlue, 'ABORDADO'),
      'cancelled' => (AppColors.error, 'CANCELADO'),
      _ => (AppColors.textSecondary, status.toUpperCase()),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(AppRadius.pill),
        border: Border.all(color: color.withOpacity(0.5)),
      ),
      child: Text(
        label,
        style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold),
      ),
    );
  }
}

/// Componente auxiliar para mostrar pares de icono-etiqueta-valor.
class _InfoItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoItem({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 14, color: AppColors.textSecondary),
            const SizedBox(width: 4),
            Text(label, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
          ],
        ),
        const SizedBox(height: 2),
        Text(value, style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
      ],
    );
  }
}