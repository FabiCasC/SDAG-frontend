import 'dart:async';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/services/trip_simulation_service.dart';
import '../../../shared/widgets/custom_button.dart';
import '../../../shared/widgets/custom_snackbar.dart';
import '../../../shared/widgets/custom_text_field.dart';
import '../../auth/screens/login_screen.dart';

class PassengerTicketData {
  const PassengerTicketData({
    required this.transactionId,
    required this.ruta,
    required this.destino,
    required this.salida,
    required this.stopName,
    required this.asientos,
  });

  final String transactionId;
  final String ruta;
  final String destino;
  final String salida;
  final String stopName;
  final List<int> asientos;
}

final ValueNotifier<PassengerTicketData?> passengerTicketNotifier = ValueNotifier(null);

class PassengerNavShell extends StatefulWidget {
  const PassengerNavShell({super.key});

  @override
  State<PassengerNavShell> createState() => _PassengerNavShellState();
}

class _PassengerNavShellState extends State<PassengerNavShell> {
  final TripSimulationService _trip = TripSimulationService.instance;
  int _index = 0;
  late final List<GlobalKey<NavigatorState>> _navKeys;
  String? _lastNewsId;

  @override
  void initState() {
    super.initState();
    _navKeys = List.generate(3, (_) => GlobalKey<NavigatorState>());
    _lastNewsId = _trip.news.isEmpty ? null : _trip.news.last.id;
    _trip.addListener(_onTripChanged);
  }

  @override
  void dispose() {
    _trip.removeListener(_onTripChanged);
    super.dispose();
  }

  void _onTripChanged() {
    if (!mounted) return;
    if (_trip.news.isEmpty) return;
    final latest = _trip.news.last;
    if (latest.id == _lastNewsId) return;
    _lastNewsId = latest.id;
    if (!latest.isEmergency) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      showDialog<void>(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: Text(latest.title),
            content: Text(latest.body.isEmpty ? '-' : latest.body),
            actions: [
              TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cerrar')),
            ],
          );
        },
      );
    });
  }

  Widget _buildTabNavigator({required int index, required Widget child}) {
    return Navigator(
      key: _navKeys[index],
      onGenerateRoute: (_) => MaterialPageRoute(builder: (context) => child),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _index,
        children: [
          _buildTabNavigator(index: 0, child: const PassengerRouteSearchScreen()),
          _buildTabNavigator(index: 1, child: const PassengerTicketsScreen()),
          _buildTabNavigator(index: 2, child: const PassengerAccountScreen()),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: [
          NavigationDestination(
            icon: const Icon(Icons.search_rounded),
            label: AppTheme.t(es: 'Buscar', en: 'Search'),
          ),
          NavigationDestination(
            icon: const Icon(Icons.confirmation_number_rounded),
            label: AppTheme.t(es: 'Tickets', en: 'Tickets'),
          ),
          NavigationDestination(
            icon: const Icon(Icons.person_rounded),
            label: AppTheme.t(es: 'Cuenta', en: 'Account'),
          ),
        ],
      ),
    );
  }
}

class PassengerTicketsScreen extends StatelessWidget {
  const PassengerTicketsScreen({super.key});

  void _openTracking(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => const PassengerLiveTrackingScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mis tickets'),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: ValueListenableBuilder<PassengerTicketData?>(
            valueListenable: passengerTicketNotifier,
            builder: (context, ticket, _) {
              if (ticket == null) {
                return Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: AppColors.primaryBlue.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: const Icon(Icons.qr_code_2_rounded, color: AppColors.primaryBlue),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Aún no tienes tickets. Reserva un asiento para generar tu QR.',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }

              return Column(
                children: [
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 44,
                                height: 44,
                                decoration: BoxDecoration(
                                  color: AppColors.primaryBlue.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                child: const Icon(Icons.qr_code_2_rounded, color: AppColors.primaryBlue),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  'Ticket activo',
                                  style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              _InfoPill(icon: Icons.route_outlined, text: ticket.ruta),
                              _InfoPill(icon: Icons.place_outlined, text: ticket.destino),
                              _InfoPill(icon: Icons.schedule_outlined, text: ticket.salida),
                              _InfoPill(icon: Icons.place_outlined, text: ticket.stopName),
                              _InfoPill(icon: Icons.event_seat_outlined, text: 'Asientos ${ticket.asientos.join(', ')}'),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  CustomButton(
                    text: 'Seguimiento en vivo',
                    onPressed: () => _openTracking(context),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class PassengerAccountScreen extends StatelessWidget {
  const PassengerAccountScreen({super.key});

  void _open(BuildContext context, Widget screen) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => screen),
    );
  }

  void _toggleTheme() {
    AppTheme.themeMode.value =
        AppTheme.themeMode.value == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
  }

  void _logout(BuildContext context) {
    Navigator.of(context, rootNavigator: true).pushAndRemoveUntil(
      MaterialPageRoute(builder: (context) => const LoginScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: TripSimulationService.instance,
      builder: (context, _) {
        final trip = TripSimulationService.instance;
        final dni = trip.currentSessionDni.isEmpty ? '00000000' : trip.currentSessionDni;
        final profile = trip.profileOf(dni);
        return Scaffold(
          appBar: AppBar(
            title: const Text('Cuenta'),
          ),
          body: SafeArea(
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                Card(
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(16),
                    leading: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: AppColors.primaryBlue.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(Icons.person_rounded, color: AppColors.primaryBlue),
                    ),
                    title: Text(profile.displayName),
                    subtitle: Text(profile.phone.trim().isEmpty ? 'DNI $dni' : 'DNI $dni • ${profile.phone}'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => _open(context, PassengerProfileEditScreen(dni: dni)),
                  ),
                ),
                const SizedBox(height: 12),
                Text('Opciones', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 10),
                Card(
                  child: Column(
                    children: [
                  ListTile(
                    leading: const Icon(Icons.history_rounded),
                    title: const Text('Historial de viajes'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => _open(context, PassengerTripHistoryScreen(dni: dni)),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.favorite_rounded),
                    title: const Text('Paraderos favoritos'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => _open(context, PassengerFavoriteStopsScreen(dni: dni)),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.notifications_rounded),
                    title: const Text('Noticias de la ruta'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => _open(context, PassengerNotificationsScreen(dni: dni)),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.public_rounded),
                    title: const Text('Redes sociales'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => _open(context, const PassengerSocialLinksScreen()),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.schedule_rounded),
                    title: const Text('Horarios de salida'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => _open(context, const PassengerScheduleSearchScreen()),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.receipt_long_rounded),
                    title: const Text('Enviar comprobante'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => _open(context, const PassengerReceiptEmailScreen()),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.description_rounded),
                    title: const Text('Términos y condiciones'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => _open(context, const PassengerTermsScreen()),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.help_outline_rounded),
                    title: const Text('Preguntas frecuentes'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => _open(context, const PassengerFaqScreen()),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.auto_stories_rounded),
                    title: const Text('Tutorial de bienvenida'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => _open(context, const PassengerTutorialScreen()),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.nightlight_round),
                    title: const Text('Modo nocturno'),
                    subtitle: Text(AppTheme.themeMode.value == ThemeMode.dark ? 'Activado' : 'Desactivado'),
                    onTap: _toggleTheme,
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.person_off_rounded),
                    title: const Text('Modo invitado'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => _open(context, const PassengerGuestModeScreen()),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.language_rounded),
                    title: const Text('Idioma'),
                    subtitle: Text(AppTheme.languageCode.value == 'en' ? 'English' : 'Español'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => _open(context, const PassengerLanguageScreen()),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.support_agent_rounded),
                    title: const Text('Soporte técnico'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => _open(context, const SupportFeedbackScreen()),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.rate_review_rounded),
                    title: const Text('Encuesta de satisfacción'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => _open(context, const PassengerSatisfactionSurveyScreen()),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.info_outline_rounded),
                    title: const Text('Créditos'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => _open(context, const CreditsScreen()),
                  ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                CustomButton(
                  text: 'Cerrar sesión',
                  onPressed: () => _logout(context),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class PassengerProfileEditScreen extends StatefulWidget {
  const PassengerProfileEditScreen({super.key, required this.dni});

  final String dni;

  @override
  State<PassengerProfileEditScreen> createState() => _PassengerProfileEditScreenState();
}

class _PassengerProfileEditScreenState extends State<PassengerProfileEditScreen> {
  final TripSimulationService _trip = TripSimulationService.instance;
  late final TextEditingController _nameController;
  late final TextEditingController _phoneController;
  late int _photoSeed;
  late bool _doNotDisturb;

  @override
  void initState() {
    super.initState();
    final p = _trip.profileOf(widget.dni);
    _nameController = TextEditingController(text: p.displayName);
    _phoneController = TextEditingController(text: p.phone);
    _photoSeed = p.photoSeed;
    _doNotDisturb = p.doNotDisturb;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Color _seedColor(int seed) {
    final colors = [
      AppColors.primaryBlue,
      AppColors.energeticOrange,
      AppColors.success,
      AppColors.warning,
      AppColors.error,
    ];
    return colors[seed.abs() % colors.length];
  }

  void _randomizePhoto() {
    setState(() {
      _photoSeed = DateTime.now().millisecondsSinceEpoch;
    });
  }

  void _save() {
    final ok = _trip.updateProfile(
      dni: widget.dni,
      displayName: _nameController.text,
      phone: _phoneController.text,
      photoSeed: _photoSeed,
      doNotDisturb: _doNotDisturb,
    );
    if (!ok) {
      CustomSnackbar.show(
        context,
        message: 'Datos inválidos. Evita nombres ofensivos y usa teléfono 9XXXXXXXX.',
        isError: true,
      );
      return;
    }
    CustomSnackbar.show(context, message: 'Perfil actualizado', isSuccess: true);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mi perfil'),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 34,
                      backgroundColor: _seedColor(_photoSeed).withOpacity(0.15),
                      child: Icon(Icons.person_rounded, color: _seedColor(_photoSeed), size: 34),
                    ),
                    const SizedBox(height: 10),
                    TextButton(
                      onPressed: _randomizePhoto,
                      child: const Text('Cambiar foto (demo)'),
                    ),
                    const SizedBox(height: 10),
                    CustomTextField(
                      label: 'Nombre',
                      hint: 'Tu nombre',
                      controller: _nameController,
                      prefixIcon: const Icon(Icons.badge_outlined),
                    ),
                    const SizedBox(height: 12),
                    CustomTextField(
                      label: 'Teléfono',
                      hint: '9XXXXXXXX',
                      keyboardType: TextInputType.phone,
                      controller: _phoneController,
                      prefixIcon: const Icon(Icons.phone_rounded),
                    ),
                    const SizedBox(height: 12),
                    SwitchListTile(
                      value: _doNotDisturb,
                      onChanged: (v) => setState(() => _doNotDisturb = v),
                      title: const Text('No molestar'),
                      subtitle: const Text('Las alertas de emergencia se muestran igual'),
                      secondary: const Icon(Icons.do_not_disturb_on_rounded),
                    ),
                    const SizedBox(height: 12),
                    CustomButton(
                      text: 'Guardar cambios',
                      onPressed: _save,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class PassengerTripHistoryScreen extends StatefulWidget {
  const PassengerTripHistoryScreen({super.key, required this.dni});

  final String dni;

  @override
  State<PassengerTripHistoryScreen> createState() => _PassengerTripHistoryScreenState();
}

class _PassengerTripHistoryScreenState extends State<PassengerTripHistoryScreen> {
  final TripSimulationService _trip = TripSimulationService.instance;

  Future<void> _openTrip(PassengerTripRecord t) async {
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: EdgeInsets.only(left: 20, right: 20, top: 12, bottom: 20 + MediaQuery.of(context).viewInsets.bottom),
            child: AnimatedBuilder(
              animation: _trip,
              builder: (context, _) {
                final codes = _trip.ticketsForTransaction(t.id).map((e) => e.code).toList();
                final rated = t.ratingStars != null;
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text('Detalle de viaje', style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _InfoPill(icon: Icons.route_outlined, text: t.ruta),
                        _InfoPill(icon: Icons.place_outlined, text: t.destino),
                        _InfoPill(icon: Icons.schedule_outlined, text: t.salida),
                        _InfoPill(icon: Icons.place_rounded, text: t.stopName),
                        _InfoPill(icon: Icons.event_seat_outlined, text: 'Asientos ${t.seats.join(', ')}'),
                        _InfoPill(icon: Icons.directions_bus_filled_rounded, text: t.placa),
                        _InfoPill(icon: Icons.payments_outlined, text: 'S/ ${t.totalCost.toStringAsFixed(2)}'),
                        _InfoPill(icon: Icons.info_outline_rounded, text: t.status),
                      ],
                    ),
                    const SizedBox(height: 12),
                    if (codes.isNotEmpty)
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Text('Ticket(s) anteriores', style: Theme.of(context).textTheme.titleSmall),
                              const SizedBox(height: 10),
                              ...codes.map((c) {
                                return Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 6),
                                  child: SelectableText(c, style: Theme.of(context).textTheme.bodySmall),
                                );
                              }),
                            ],
                          ),
                        ),
                      ),
                    const SizedBox(height: 12),
                    if (t.status == 'Finalizado' && !rated)
                      CustomButton(
                        text: 'Calificar conductor',
                        onPressed: () async {
                          Navigator.of(context).pop();
                          await _openRating(trip: t);
                        },
                      )
                    else if (rated)
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            children: [
                              const Icon(Icons.star_rounded, color: AppColors.energeticOrange),
                              const SizedBox(width: 10),
                              Expanded(child: Text('Calificación: ${t.ratingStars}')),
                            ],
                          ),
                        ),
                      ),
                  ],
                );
              },
            ),
          ),
        );
      },
    );
  }

  Future<void> _openRating({required PassengerTripRecord trip}) async {
    var stars = 5;
    final TextEditingController controller = TextEditingController();
    await showDialog<void>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setLocal) {
            return AlertDialog(
              title: const Text('Calificar servicio'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(5, (i) {
                      final v = i + 1;
                      final selected = v <= stars;
                      return IconButton(
                        onPressed: () => setLocal(() => stars = v),
                        icon: Icon(selected ? Icons.star_rounded : Icons.star_border_rounded, color: AppColors.energeticOrange),
                      );
                    }),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: controller,
                    decoration: const InputDecoration(labelText: 'Comentario (opcional)', prefixIcon: Icon(Icons.chat_bubble_outline_rounded)),
                    maxLines: 2,
                  ),
                ],
              ),
              actions: [
                TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancelar')),
                TextButton(
                  onPressed: () {
                    final res = _trip.submitRating(
                      tripId: trip.id,
                      passengerDni: widget.dni,
                      stars: stars,
                      comment: controller.text,
                    );
                    Navigator.of(context).pop();
                    CustomSnackbar.show(context, message: res.message, isSuccess: res.ok, isError: !res.ok);
                    setState(() {});
                  },
                  child: const Text('Enviar'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final trips = _trip.tripHistoryOf(widget.dni);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Historial de viajes'),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            if (trips.isEmpty)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text('Aún no tienes viajes registrados.', style: Theme.of(context).textTheme.bodyMedium),
                ),
              )
            else
              ...trips.map((t) {
                final statusColor = t.status == 'Finalizado' ? AppColors.success : AppColors.energeticOrange;
                return Card(
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(16),
                    leading: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(color: statusColor.withOpacity(0.12), borderRadius: BorderRadius.circular(14)),
                      child: Icon(t.status == 'Finalizado' ? Icons.check_rounded : Icons.timelapse_rounded, color: statusColor),
                    ),
                    title: Text('${t.ruta} • ${t.destino}'),
                    subtitle: Text('${t.salida} • ${t.placa}\nS/ ${t.totalCost.toStringAsFixed(2)} • ${t.status}'),
                    isThreeLine: true,
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => _openTrip(t),
                  ),
                );
              }),
          ],
        ),
      ),
    );
  }
}

class PassengerFavoriteStopsScreen extends StatelessWidget {
  const PassengerFavoriteStopsScreen({super.key, required this.dni});

  final String dni;

  @override
  Widget build(BuildContext context) {
    final trip = TripSimulationService.instance;
    final stopNames = trip.driverStops.map((s) => s.stopName).toSet().toList()..sort();
    final favorites = trip.favoriteStopsOf(dni).toList()..sort();

    for (final f in favorites) {
      if (!stopNames.contains(f)) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          trip.toggleFavoriteStop(passengerDni: dni, stopName: f);
        });
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Paraderos favoritos'),
      ),
      body: SafeArea(
        child: AnimatedBuilder(
          animation: trip,
          builder: (context, _) {
            final favNow = trip.favoriteStopsOf(dni).toList()..sort();
            return ListView(
              padding: const EdgeInsets.all(20),
              children: [
                if (favNow.isEmpty)
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text('No tienes paraderos favoritos aún.', style: Theme.of(context).textTheme.bodyMedium),
                    ),
                  ),
                if (favNow.isNotEmpty) ...[
                  Text('Tus favoritos', style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 10),
                  ...favNow.map((f) {
                    return Card(
                      child: ListTile(
                        contentPadding: const EdgeInsets.all(16),
                        leading: Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(color: AppColors.error.withOpacity(0.12), borderRadius: BorderRadius.circular(14)),
                          child: const Icon(Icons.favorite_rounded, color: AppColors.error),
                        ),
                        title: Text(f),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete_outline_rounded),
                          onPressed: () {
                            final r = trip.toggleFavoriteStop(passengerDni: dni, stopName: f);
                            CustomSnackbar.show(context, message: r.message, isSuccess: r.ok, isError: !r.ok);
                          },
                        ),
                      ),
                    );
                  }),
                  const SizedBox(height: 12),
                ],
                Text('Paraderos disponibles', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 10),
                ...stopNames.map((s) {
                  final canFav = trip.canFavoriteStop(passengerDni: dni, stopName: s);
                  final isFav = trip.favoriteStopsOf(dni).contains(s);
                  return Card(
                    child: ListTile(
                      contentPadding: const EdgeInsets.all(16),
                      leading: Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(color: AppColors.primaryBlue.withOpacity(0.12), borderRadius: BorderRadius.circular(14)),
                        child: const Icon(Icons.place_rounded, color: AppColors.primaryBlue),
                      ),
                      title: Text(s),
                      subtitle: Text(canFav ? 'Disponible para favoritos' : 'Habilita favoritos reservando primero aquí'),
                      trailing: IconButton(
                        onPressed: canFav
                            ? () {
                                final r = trip.toggleFavoriteStop(passengerDni: dni, stopName: s);
                                CustomSnackbar.show(context, message: r.message, isSuccess: r.ok, isError: !r.ok);
                              }
                            : null,
                        icon: Icon(isFav ? Icons.favorite_rounded : Icons.favorite_border_rounded, color: isFav ? AppColors.error : AppColors.textSecondary),
                      ),
                    ),
                  );
                }),
              ],
            );
          },
        ),
      ),
    );
  }
}

class PassengerNotificationsScreen extends StatelessWidget {
  const PassengerNotificationsScreen({super.key, required this.dni});

  final String dni;

  Future<void> _open(BuildContext context, NewsNotification n) async {
    final trip = TripSimulationService.instance;
    trip.markNewsRead(dni: dni, newsId: n.id);
    await showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(n.title),
          content: Text(n.body.isEmpty ? '-' : n.body),
          actions: [
            TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cerrar')),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final trip = TripSimulationService.instance;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Noticias de la ruta'),
      ),
      body: SafeArea(
        child: AnimatedBuilder(
          animation: trip,
          builder: (context, _) {
            final items = trip.news.toList()..sort((a, b) => b.createdAt.compareTo(a.createdAt));
            return ListView(
              padding: const EdgeInsets.all(20),
              children: [
                if (items.isEmpty)
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text('No hay noticias por ahora.', style: Theme.of(context).textTheme.bodyMedium),
                    ),
                  )
                else
                  ...items.map((n) {
                    final read = trip.isNewsRead(dni: dni, newsId: n.id);
                    final color = n.isEmergency ? AppColors.error : AppColors.primaryBlue;
                    return Card(
                      child: ListTile(
                        contentPadding: const EdgeInsets.all(16),
                        leading: Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(14)),
                          child: Icon(n.isEmergency ? Icons.warning_amber_rounded : Icons.campaign_rounded, color: color),
                        ),
                        title: Text(n.title, style: TextStyle(fontWeight: read ? FontWeight.w600 : FontWeight.w900)),
                        subtitle: Text(n.isEmergency ? 'Emergencia • ${n.createdAt}' : 'Noticia • ${n.createdAt}'),
                        trailing: Icon(read ? Icons.mark_email_read_rounded : Icons.mark_email_unread_rounded, color: read ? AppColors.textSecondary : color),
                        onTap: () => _open(context, n),
                      ),
                    );
                  }),
              ],
            );
          },
        ),
      ),
    );
  }
}

class PassengerSocialLinksScreen extends StatelessWidget {
  const PassengerSocialLinksScreen({super.key});

  Future<void> _open(BuildContext context, String url) async {
    final uri = Uri.tryParse(url);
    if (uri == null) {
      CustomSnackbar.show(context, message: 'Link roto. Perfil en mantenimiento.', isError: true);
      return;
    }
    final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!context.mounted) return;
    if (!ok) {
      CustomSnackbar.show(context, message: 'No se pudo abrir el enlace.', isError: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    const facebook = 'https://facebook.com/sdag.oficial';
    const instagram = 'https://instagram.com/sdag.oficial';
    return Scaffold(
      appBar: AppBar(
        title: const Text('Redes sociales'),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text('Canales oficiales', style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 12),
                    Card(
                      child: ListTile(
                        contentPadding: const EdgeInsets.all(16),
                        leading: Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(color: AppColors.primaryBlue.withOpacity(0.12), borderRadius: BorderRadius.circular(14)),
                          child: const Icon(Icons.public_rounded, color: AppColors.primaryBlue),
                        ),
                        title: const Text('Facebook'),
                        subtitle: const Text('Página oficial'),
                        trailing: const Icon(Icons.open_in_new_rounded),
                        onTap: () => _open(context, facebook),
                      ),
                    ),
                    Card(
                      child: ListTile(
                        contentPadding: const EdgeInsets.all(16),
                        leading: Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(color: AppColors.energeticOrange.withOpacity(0.12), borderRadius: BorderRadius.circular(14)),
                          child: const Icon(Icons.photo_camera_rounded, color: AppColors.energeticOrange),
                        ),
                        title: const Text('Instagram'),
                        subtitle: const Text('Perfil oficial'),
                        trailing: const Icon(Icons.open_in_new_rounded),
                        onTap: () => _open(context, instagram),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class PassengerLanguageScreen extends StatelessWidget {
  const PassengerLanguageScreen({super.key});

  void _set(BuildContext context, String code) {
    AppTheme.languageCode.value = code;
    CustomSnackbar.show(context, message: 'Idioma actualizado', isSuccess: true);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Idioma'),
      ),
      body: SafeArea(
        child: ValueListenableBuilder<String>(
          valueListenable: AppTheme.languageCode,
          builder: (context, lang, _) {
            return ListView(
              padding: const EdgeInsets.all(20),
              children: [
                Card(
                  child: Column(
                    children: [
                      ListTile(
                        contentPadding: const EdgeInsets.all(16),
                        leading: Icon(lang == 'es' ? Icons.radio_button_checked_rounded : Icons.radio_button_off_rounded),
                        title: const Text('Español'),
                        onTap: () => _set(context, 'es'),
                      ),
                      const Divider(height: 1),
                      ListTile(
                        contentPadding: const EdgeInsets.all(16),
                        leading: Icon(lang == 'en' ? Icons.radio_button_checked_rounded : Icons.radio_button_off_rounded),
                        title: const Text('English'),
                        onTap: () => _set(context, 'en'),
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class SupportFeedbackScreen extends StatefulWidget {
  const SupportFeedbackScreen({super.key});

  @override
  State<SupportFeedbackScreen> createState() => _SupportFeedbackScreenState();
}

class _SupportFeedbackScreenState extends State<SupportFeedbackScreen> {
  final TripSimulationService _trip = TripSimulationService.instance;
  final TextEditingController _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _send() {
    final msg = _controller.text.trim();
    if (msg.isEmpty) {
      CustomSnackbar.show(context, message: 'Escribe un mensaje', isError: true);
      return;
    }
    final dni = _trip.currentSessionDni.isEmpty ? '00000000' : _trip.currentSessionDni;
    final role = _trip.currentSessionRole.isEmpty ? 'Pasajero' : _trip.currentSessionRole;
    final entry = _trip.submitSupportFeedback(fromDni: dni, fromRole: role, message: msg, deviceModel: 'Web', appVersion: '1.0.0');
    _controller.clear();
    CustomSnackbar.show(
      context,
      message: entry.sent ? 'Enviado a soporte' : 'Guardado sin conexión. Se enviará al volver internet.',
      isSuccess: true,
    );
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Soporte técnico'),
      ),
      body: SafeArea(
        child: AnimatedBuilder(
          animation: _trip,
          builder: (context, _) {
            final dni = _trip.currentSessionDni.isEmpty ? '00000000' : _trip.currentSessionDni;
            final items = _trip.supportFeedback.where((e) => e.fromDni == dni).toList()..sort((a, b) => b.at.compareTo(a.at));
            return ListView(
              padding: const EdgeInsets.all(20),
              children: [
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text('Enviar reporte', style: Theme.of(context).textTheme.titleMedium),
                        const SizedBox(height: 12),
                        TextField(
                          controller: _controller,
                          decoration: const InputDecoration(
                            labelText: 'Describe el problema o sugerencia',
                            prefixIcon: Icon(Icons.support_agent_rounded),
                          ),
                          maxLines: 4,
                        ),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            _InfoPill(icon: Icons.wifi_rounded, text: _trip.isOnline ? 'Online' : 'Offline'),
                            _InfoPill(icon: Icons.info_outline_rounded, text: 'Adjunta log (demo)'),
                          ],
                        ),
                        const SizedBox(height: 12),
                        CustomButton(
                          text: 'Enviar',
                          onPressed: _send,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Text('Historial', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 10),
                if (items.isEmpty)
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text('Sin reportes.', style: Theme.of(context).textTheme.bodyMedium),
                    ),
                  )
                else
                  ...items.take(20).map((e) {
                    final color = e.sent ? AppColors.success : AppColors.warning;
                    return Card(
                      child: ListTile(
                        contentPadding: const EdgeInsets.all(16),
                        leading: Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(14)),
                          child: Icon(e.sent ? Icons.check_rounded : Icons.schedule_rounded, color: color),
                        ),
                        title: Text(e.message, maxLines: 1, overflow: TextOverflow.ellipsis),
                        subtitle: Text('${e.at} • ${e.sent ? 'Enviado' : 'Pendiente'}'),
                      ),
                    );
                  }),
              ],
            );
          },
        ),
      ),
    );
  }
}

class PassengerSatisfactionSurveyScreen extends StatefulWidget {
  const PassengerSatisfactionSurveyScreen({super.key});

  @override
  State<PassengerSatisfactionSurveyScreen> createState() => _PassengerSatisfactionSurveyScreenState();
}

class _PassengerSatisfactionSurveyScreenState extends State<PassengerSatisfactionSurveyScreen> {
  final TripSimulationService _trip = TripSimulationService.instance;
  int _q1 = 5;
  int _q2 = 5;
  int _q3 = 5;

  void _submit() {
    final dni = _trip.currentSessionDni.isEmpty ? '00000000' : _trip.currentSessionDni;
    final ok = _trip.submitSurvey(passengerDni: dni, q1: _q1, q2: _q2, q3: _q3);
    if (!ok) {
      CustomSnackbar.show(context, message: 'Ya respondiste este mes', isError: true);
      return;
    }
    CustomSnackbar.show(context, message: 'Gracias por tu respuesta', isSuccess: true);
    Navigator.of(context).pop();
  }

  Widget _scaleRow({required String title, required int value, required ValueChanged<int> onChanged}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(title, style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: List.generate(5, (i) {
            final v = i + 1;
            final selected = value == v;
            return ChoiceChip(
              label: Text('$v'),
              selected: selected,
              onSelected: (_) => onChanged(v),
              selectedColor: AppColors.primaryBlue.withOpacity(0.12),
              backgroundColor: AppColors.white,
              labelStyle: TextStyle(fontWeight: FontWeight.w800, color: selected ? AppColors.primaryBlue : AppColors.textPrimary),
              side: BorderSide(color: selected ? AppColors.primaryBlue : Colors.grey.shade300),
            );
          }),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final dni = _trip.currentSessionDni.isEmpty ? '00000000' : _trip.currentSessionDni;
    final can = _trip.shouldShowSurvey(dni);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Encuesta de satisfacción'),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            if (!can)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text('Ya respondiste la encuesta este mes.', style: Theme.of(context).textTheme.bodyMedium),
                ),
              ),
            if (can)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text('Responde 3 preguntas', style: Theme.of(context).textTheme.titleMedium),
                      const SizedBox(height: 12),
                      _scaleRow(
                        title: '1) ¿Qué tan fácil fue reservar?',
                        value: _q1,
                        onChanged: (v) => setState(() => _q1 = v),
                      ),
                      const SizedBox(height: 16),
                      _scaleRow(
                        title: '2) ¿Qué tan satisfecho con el viaje?',
                        value: _q2,
                        onChanged: (v) => setState(() => _q2 = v),
                      ),
                      const SizedBox(height: 16),
                      _scaleRow(
                        title: '3) ¿Recomendarías la app?',
                        value: _q3,
                        onChanged: (v) => setState(() => _q3 = v),
                      ),
                      const SizedBox(height: 16),
                      CustomButton(
                        text: 'Enviar encuesta',
                        onPressed: _submit,
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class CreditsScreen extends StatelessWidget {
  const CreditsScreen({super.key});

  void _openPerson(BuildContext context, String name, String role) {
    showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(name),
          content: Text(role),
          actions: [
            TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cerrar')),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    const team = [
      ('Fabiana', 'Producto / QA'),
      ('Pablo', 'Operación / Dueño demo'),
      ('Manuel', 'Finanzas / Legal'),
      ('Giancarlo', 'Operación / Analítica'),
      ('Carlos', 'Soporte / BI'),
      ('Miguel', 'UX'),
    ];
    return Scaffold(
      appBar: AppBar(
        title: const Text('Créditos'),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text('SDAG', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900)),
                    const SizedBox(height: 6),
                    Text('Versión 1.0.0', style: Theme.of(context).textTheme.bodySmall),
                    const SizedBox(height: 12),
                    Text('Equipo', style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 10),
                    ...team.map((p) {
                      return Card(
                        child: ListTile(
                          contentPadding: const EdgeInsets.all(16),
                          leading: Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(color: AppColors.primaryBlue.withOpacity(0.12), borderRadius: BorderRadius.circular(14)),
                            child: const Icon(Icons.person_rounded, color: AppColors.primaryBlue),
                          ),
                          title: Text(p.$1),
                          subtitle: Text(p.$2),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () => _openPerson(context, p.$1, p.$2),
                        ),
                      );
                    }),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class PassengerScheduleSearchScreen extends StatefulWidget {
  const PassengerScheduleSearchScreen({super.key});

  @override
  State<PassengerScheduleSearchScreen> createState() => _PassengerScheduleSearchScreenState();
}

class _PassengerScheduleSearchScreenState extends State<PassengerScheduleSearchScreen> {
  final TextEditingController _searchController = TextEditingController();

  final List<Map<String, String>> _horarios = const [
    {"terminal": "Terminal Lima", "hora": "08:00", "destino": "Chosica"},
    {"terminal": "Terminal Lima", "hora": "09:30", "destino": "Huancayo"},
    {"terminal": "Terminal Chosica", "hora": "10:00", "destino": "Matucana"},
    {"terminal": "Terminal Lima", "hora": "11:15", "destino": "Chosica"},
    {"terminal": "Terminal Huancayo", "hora": "12:00", "destino": "Lima"},
  ];

  List<Map<String, String>> _buscar(String query) {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return const [];
    return _horarios.where((h) {
      return (h["terminal"] ?? "").toLowerCase().contains(q) ||
          (h["hora"] ?? "").toLowerCase().contains(q) ||
          (h["destino"] ?? "").toLowerCase().contains(q);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final results = _buscar(_searchController.text);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Horarios de salida'),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: TextField(
                  controller: _searchController,
                  decoration: const InputDecoration(
                    labelText: 'Buscar por terminal, hora o destino',
                    prefixIcon: Icon(Icons.search),
                  ),
                  onChanged: (_) => setState(() {}),
                ),
              ),
            ),
            const SizedBox(height: 12),
            if (_searchController.text.trim().isEmpty)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    'Ingresa un terminal, hora o destino para buscar.',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),
              )
            else if (results.isEmpty)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    'Sin resultados.',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),
              )
            else
              ...results.map((h) {
                return Card(
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(16),
                    leading: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: AppColors.primaryBlue.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(Icons.schedule_rounded, color: AppColors.primaryBlue),
                    ),
                    title: Text('Terminal: ${h["terminal"]}'),
                    subtitle: Text('Hora: ${h["hora"]}\nDestino: ${h["destino"]}'),
                    isThreeLine: true,
                  ),
                );
              }),
          ],
        ),
      ),
    );
  }
}

class PassengerReceiptEmailScreen extends StatefulWidget {
  const PassengerReceiptEmailScreen({super.key});

  @override
  State<PassengerReceiptEmailScreen> createState() => _PassengerReceiptEmailScreenState();
}

class _PassengerReceiptEmailScreenState extends State<PassengerReceiptEmailScreen> {
  final TextEditingController _emailController = TextEditingController();
  final String _comprobante = 'Comprobante de Pago\n\nMonto: S/ 100.00\nFecha: 05/06/2026\nTicket: 123456';

  Future<void> _copy() async {
    await Clipboard.setData(ClipboardData(text: _comprobante));
    if (!mounted) return;
    CustomSnackbar.show(
      context,
      message: 'Comprobante copiado',
      isSuccess: true,
    );
  }

  void _send() {
    if (_emailController.text.trim().isEmpty) {
      CustomSnackbar.show(
        context,
        message: 'Ingrese un correo válido',
        isError: true,
      );
      return;
    }
    CustomSnackbar.show(
      context,
      message: 'Envío simulado a ${_emailController.text.trim()}',
      isSuccess: true,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Enviar comprobante'),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text(_comprobante, style: Theme.of(context).textTheme.bodyMedium),
              ),
            ),
            const SizedBox(height: 12),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    CustomTextField(
                      label: 'Correo electrónico',
                      hint: 'Ej: usuario@correo.com',
                      controller: _emailController,
                      prefixIcon: const Icon(Icons.email_rounded),
                    ),
                    const SizedBox(height: 12),
                    CustomButton(
                      text: 'Enviar comprobante',
                      onPressed: _send,
                    ),
                    const SizedBox(height: 10),
                    ElevatedButton(
                      onPressed: _copy,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryBlue.withOpacity(0.12),
                        foregroundColor: AppColors.textPrimary,
                        minimumSize: const Size.fromHeight(50),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text('Copiar comprobante'),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class PassengerTermsScreen extends StatefulWidget {
  const PassengerTermsScreen({super.key});

  @override
  State<PassengerTermsScreen> createState() => _PassengerTermsScreenState();
}

class _PassengerTermsScreenState extends State<PassengerTermsScreen> {
  bool _accepted = false;

  void _confirm() {
    CustomSnackbar.show(
      context,
      message: _accepted
          ? 'Gracias por aceptar los términos y condiciones.'
          : 'Acepta los términos y condiciones para continuar.',
      isSuccess: _accepted,
      isError: !_accepted,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Términos y condiciones'),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              Expanded(
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: SingleChildScrollView(
                      child: Text(
                        'Términos y Condiciones de Uso\n\n'
                        '1. Introducción.\n'
                        '2. Aceptación de los términos.\n'
                        '3. Uso del servicio.\n'
                        '4. Restricciones de uso.\n'
                        '5. Política de privacidad.\n'
                        '6. Responsabilidad del usuario.\n'
                        '7. Modificaciones a los términos.\n\n'
                        'Este texto es un ejemplo para la demo.',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Checkbox(
                        value: _accepted,
                        onChanged: (v) => setState(() => _accepted = v ?? false),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Acepto los términos y condiciones',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              CustomButton(
                text: 'Confirmar aceptación',
                onPressed: _confirm,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class PassengerGuestModeScreen extends StatelessWidget {
  const PassengerGuestModeScreen({super.key});

  void _goLogin(BuildContext context) {
    Navigator.of(context, rootNavigator: true).pushAndRemoveUntil(
      MaterialPageRoute(builder: (context) => const LoginScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final units = const [
      {"unidad": "Toyota Hiace 2022", "disponibilidad": "Disponible"},
      {"unidad": "Hyundai H1 2021", "disponibilidad": "Disponible"},
      {"unidad": "Nissan NV350 2020", "disponibilidad": "No disponible"},
      {"unidad": "Chevrolet Express 2021", "disponibilidad": "Disponible"},
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Modo invitado'),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  'Como invitado puedes consultar disponibilidad de unidades.',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
            ),
            const SizedBox(height: 12),
            ...units.map((u) {
              final isOk = u["disponibilidad"] == "Disponible";
              final color = isOk ? AppColors.success : AppColors.error;
              return Card(
                child: ListTile(
                  contentPadding: const EdgeInsets.all(16),
                  title: Text(u["unidad"] ?? '-'),
                  subtitle: Text('Disponibilidad: ${u["disponibilidad"]}'),
                  trailing: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      u["disponibilidad"] ?? '-',
                      style: TextStyle(color: color, fontWeight: FontWeight.w700, fontSize: 12),
                    ),
                  ),
                ),
              );
            }),
            const SizedBox(height: 12),
            CustomButton(
              text: 'Iniciar sesión',
              onPressed: () => _goLogin(context),
            ),
          ],
        ),
      ),
    );
  }
}

class PassengerTutorialScreen extends StatefulWidget {
  const PassengerTutorialScreen({super.key});

  @override
  State<PassengerTutorialScreen> createState() => _PassengerTutorialScreenState();
}

class _PassengerTutorialScreenState extends State<PassengerTutorialScreen> {
  final PageController _controller = PageController();
  int _index = 0;

  void _goNext() {
    if (_index >= 2) {
      Navigator.of(context).pop();
      return;
    }
    _controller.nextPage(duration: const Duration(milliseconds: 250), curve: Curves.easeOut);
  }

  void _skip() {
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final pages = const [
      _TutorialPageData(
        title: 'Bienvenido a SDAG',
        body: 'Busca rutas y reserva asientos fácilmente.',
        icon: Icons.directions_bus_filled_rounded,
      ),
      _TutorialPageData(
        title: 'Selecciona tu asiento',
        body: 'El mapa de cabina se adapta a la capacidad de la unidad.',
        icon: Icons.event_seat_rounded,
      ),
      _TutorialPageData(
        title: 'Paga y recibe tu ticket',
        body: 'Confirma tu pago y genera tu ticket QR.',
        icon: Icons.qr_code_2_rounded,
      ),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Tutorial'),
        actions: [
          TextButton(
            onPressed: _skip,
            child: const Text('Saltar'),
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              Expanded(
                child: PageView.builder(
                  controller: _controller,
                  itemCount: pages.length,
                  onPageChanged: (i) => setState(() => _index = i),
                  itemBuilder: (context, i) => _TutorialPageView(data: pages[i]),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(pages.length, (i) {
                  final selected = i == _index;
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: selected ? 22 : 8,
                    height: 8,
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    decoration: BoxDecoration(
                      color: selected ? AppColors.primaryBlue : Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(999),
                    ),
                  );
                }),
              ),
              const SizedBox(height: 12),
              CustomButton(
                text: _index >= 2 ? 'Comenzar' : 'Siguiente',
                onPressed: _goNext,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TutorialPageData {
  const _TutorialPageData({required this.title, required this.body, required this.icon});

  final String title;
  final String body;
  final IconData icon;
}

class _TutorialPageView extends StatelessWidget {
  const _TutorialPageView({required this.data});

  final _TutorialPageData data;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 84,
              height: 84,
              decoration: BoxDecoration(
                color: AppColors.primaryBlue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(24),
              ),
              child: Icon(data.icon, color: AppColors.primaryBlue, size: 44),
            ),
            const SizedBox(height: 20),
            Text(
              data.title,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            Text(
              data.body,
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class PassengerFaqScreen extends StatefulWidget {
  const PassengerFaqScreen({super.key});

  @override
  State<PassengerFaqScreen> createState() => _PassengerFaqScreenState();
}

class _PassengerFaqScreenState extends State<PassengerFaqScreen> {
  final List<Map<String, String>> _faq = const [
    {
      "pregunta": "¿Cómo registro una unidad en el sistema?",
      "respuesta": "Desde el perfil Dueño, entra a Flota y registra la placa y capacidad."
    },
    {
      "pregunta": "¿Cómo puedo ver los horarios de salida?",
      "respuesta": "En Cuenta → Horarios de salida puedes buscar por terminal, hora o destino."
    },
    {
      "pregunta": "¿Qué hacer si no puedo encontrar un conductor?",
      "respuesta": "En el módulo Staff puedes buscar y vincular choferes a una placa."
    },
    {
      "pregunta": "¿Cómo activar el modo nocturno?",
      "respuesta": "En Cuenta → Modo nocturno puedes alternar el tema."
    },
    {
      "pregunta": "¿Dónde puedo ver mis pagos y tickets?",
      "respuesta": "En Tickets encontrarás tus QR generados (demo)."
    },
  ];

  late final List<bool> _expanded = List.generate(_faq.length, (_) => false);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Preguntas frecuentes'),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Text('Consulta nuestras preguntas frecuentes', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            ..._faq.asMap().entries.map((e) {
              final index = e.key;
              final item = e.value;
              return Card(
                child: ExpansionTile(
                  initiallyExpanded: _expanded[index],
                  onExpansionChanged: (v) => setState(() => _expanded[index] = v),
                  title: Text(item["pregunta"] ?? '-', style: Theme.of(context).textTheme.titleSmall),
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                      child: Text(item["respuesta"] ?? '-', style: Theme.of(context).textTheme.bodyMedium),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}

class PassengerRouteSearchScreen extends StatefulWidget {
  const PassengerRouteSearchScreen({super.key});

  @override
  State<PassengerRouteSearchScreen> createState() => _PassengerRouteSearchScreenState();
}

class _PassengerRouteSearchScreenState extends State<PassengerRouteSearchScreen> {
  final TripSimulationService _trip = TripSimulationService.instance;
  final List<Map<String, dynamic>> _routes = [
    {'ruta': 'Lima - Chosica', 'destino': 'Chosica', 'salida': '06:30', 'capacidad': 15, 'estado': 'Carga'},
    {'ruta': 'Lima - Huancayo', 'destino': 'Huancayo', 'salida': '07:15', 'capacidad': 8, 'estado': 'Carga'},
    {'ruta': 'Chosica - Matucana', 'destino': 'Matucana', 'salida': '08:00', 'capacidad': 6, 'estado': 'En ruta'},
    {'ruta': 'Lima - Matucana', 'destino': 'Matucana', 'salida': '09:10', 'capacidad': 4, 'estado': 'Carga'},
    {'ruta': 'Lima - Chosica', 'destino': 'Chosica', 'salida': '10:45', 'capacidad': 6, 'estado': 'Carga'},
  ];

  String _selectedDestino = 'Todos';
  String _selectedStopName = 'Paradero Plaza';

  @override
  void initState() {
    super.initState();
    if (_trip.driverStops.isNotEmpty) {
      _selectedStopName = _trip.driverStops.first.stopName;
    }
  }

  List<String> get _stopNames {
    final stops = _trip.driverStops.map((s) => s.stopName).toSet().toList()..sort();
    final fav = _trip.favoriteStopsOf(_trip.currentSessionDni).toList()..sort();
    final ordered = <String>[];
    for (final f in fav) {
      if (stops.contains(f)) ordered.add(f);
    }
    for (final s in stops) {
      if (!ordered.contains(s)) ordered.add(s);
    }
    return ordered;
  }

  Future<void> _pickStop() async {
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        return SafeArea(
          child: AnimatedBuilder(
            animation: _trip,
            builder: (context, _) {
              final dni = _trip.currentSessionDni;
              final favorites = _trip.favoriteStopsOf(dni);
              final stops = _stopNames;
              return ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  Text('Seleccionar paradero', style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 12),
                  ...stops.map((name) {
                    final selected = name == _selectedStopName;
                    final canFav = _trip.canFavoriteStop(passengerDni: dni, stopName: name);
                    final isFav = favorites.contains(name);
                    return Card(
                      child: ListTile(
                        contentPadding: const EdgeInsets.all(16),
                        leading: Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: (selected ? AppColors.primaryBlue : Colors.grey.shade500).withOpacity(0.12),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Icon(selected ? Icons.place_rounded : Icons.place_outlined, color: selected ? AppColors.primaryBlue : Colors.grey.shade700),
                        ),
                        title: Text(name),
                        trailing: IconButton(
                          onPressed: canFav
                              ? () {
                                  final r = _trip.toggleFavoriteStop(passengerDni: dni, stopName: name);
                                  if (!r.ok) {
                                    CustomSnackbar.show(context, message: r.message, isError: true);
                                  } else {
                                    CustomSnackbar.show(context, message: r.message, isSuccess: true);
                                  }
                                }
                              : null,
                          icon: Icon(isFav ? Icons.favorite_rounded : Icons.favorite_border_rounded, color: isFav ? AppColors.error : AppColors.textSecondary),
                        ),
                        onTap: () {
                          setState(() {
                            _selectedStopName = name;
                          });
                          Navigator.of(context).pop();
                        },
                      ),
                    );
                  }),
                ],
              );
            },
          ),
        );
      },
    );
  }

  List<String> get _destinos {
    final unique = <String>{};
    for (final r in _routes) {
      final destino = r['destino'] as String?;
      if (destino != null && destino.trim().isNotEmpty) {
        unique.add(destino);
      }
    }
    final list = unique.toList()..sort();
    return ['Todos', ...list];
  }

  List<Map<String, dynamic>> get _filteredRoutes {
    final inCarga = _routes.where((r) => r['estado'] == 'Carga');
    final inRuta = _routes.where((r) => r['estado'] == 'En ruta');
    final includeInRuta = _trip.releasedSeats.isNotEmpty;
    Iterable<Map<String, dynamic>> combined = inCarga;
    if (includeInRuta) {
      combined = [...combined, ...inRuta];
    }
    if (_selectedDestino == 'Todos') return combined.toList();
    return combined.where((r) => r['destino'] == _selectedDestino).toList();
  }

  void _openCabin(Map<String, dynamic> route) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => CabinMapScreen(
          ruta: route['ruta'] as String? ?? '-',
          destino: route['destino'] as String? ?? '-',
          salida: route['salida'] as String? ?? '-',
          capacidad: route['capacidad'] as int? ?? 4,
          stopName: _selectedStopName,
          inRouteSale: (route['estado'] as String?) == 'En ruta',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Búsqueda de viajes'),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: AppColors.primaryBlue.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(Icons.search_rounded, color: AppColors.primaryBlue),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Elige tu destino', style: Theme.of(context).textTheme.titleLarge),
                          const SizedBox(height: 4),
                          Text(
                            _trip.releasedSeats.isNotEmpty
                                ? 'Carga y venta en ruta (No-show).'
                                : 'Se muestran solo unidades en estado Carga.',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text('Destinos', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 10),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: _destinos.map((d) {
                final isSelected = _selectedDestino == d;
                return ChoiceChip(
                  label: Text(d),
                  selected: isSelected,
                  onSelected: (_) {
                    setState(() {
                      _selectedDestino = d;
                    });
                  },
                  selectedColor: AppColors.primaryBlue.withOpacity(0.12),
                  backgroundColor: AppColors.white,
                  labelStyle: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: isSelected ? AppColors.primaryBlue : AppColors.textPrimary,
                  ),
                  side: BorderSide(
                    color: isSelected ? AppColors.primaryBlue : Colors.grey.shade300,
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 20),
            Text('Paradero de abordaje', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 10),
            Card(
              child: ListTile(
                contentPadding: const EdgeInsets.all(16),
                leading: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: AppColors.primaryBlue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(Icons.place_rounded, color: AppColors.primaryBlue),
                ),
                title: Text(_selectedStopName),
                subtitle: Text(
                  _trip.canFavoriteStop(passengerDni: _trip.currentSessionDni, stopName: _selectedStopName)
                      ? 'Puedes marcar este paradero como favorito'
                      : 'Los favoritos se habilitan luego de tu primera reserva en el paradero',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                trailing: const Icon(Icons.expand_more_rounded),
                onTap: _pickStop,
              ),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Rutas disponibles', style: Theme.of(context).textTheme.titleMedium),
                Text(
                  '${_filteredRoutes.length}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: AppColors.textSecondary,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            if (_filteredRoutes.isEmpty)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: AppColors.warning.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Icon(Icons.info_outline, color: AppColors.warning),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'No hay rutas para el destino seleccionado.',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else
              ..._filteredRoutes.asMap().entries.expand((e) {
                final index = e.key;
                final r = e.value;
                final ruta = r['ruta'] as String? ?? '-';
                final destino = r['destino'] as String? ?? '-';
                final salida = r['salida'] as String? ?? '-';
                final capacidad = r['capacidad'] as int? ?? 4;

                return [
                  if (index > 0) const SizedBox(height: 12),
                  Card(
                    child: InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: () => _openCabin(r),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                color: AppColors.primaryBlue.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: const Icon(Icons.route_rounded, color: AppColors.primaryBlue),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(ruta, style: Theme.of(context).textTheme.titleMedium),
                                  const SizedBox(height: 6),
                                  Wrap(
                                    spacing: 8,
                                    runSpacing: 8,
                                    children: [
                                      _InfoPill(icon: Icons.place_outlined, text: destino),
                                      _InfoPill(icon: Icons.schedule_outlined, text: salida),
                                      _InfoPill(icon: Icons.event_seat_outlined, text: '$capacidad asientos'),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            const Icon(Icons.chevron_right, color: AppColors.textSecondary),
                          ],
                        ),
                      ),
                    ),
                  ),
                ];
              }).toList(),
          ],
        ),
      ),
    );
  }
}

class CabinMapScreen extends StatefulWidget {
  const CabinMapScreen({
    super.key,
    required this.ruta,
    required this.destino,
    required this.salida,
    required this.capacidad,
    required this.stopName,
    this.inRouteSale = false,
  });

  final String ruta;
  final String destino;
  final String salida;
  final int capacidad;
  final String stopName;
  final bool inRouteSale;

  @override
  State<CabinMapScreen> createState() => _CabinMapScreenState();
}

class _CabinMapScreenState extends State<CabinMapScreen> {
  final TripSimulationService _trip = TripSimulationService.instance;
  final Set<int> _selectedSeats = {};
  int _desiredCount = 1;
  Timer? _timer;
  int _secondsLeft = 0;

  @override
  void initState() {
    super.initState();
    _trip.addListener(_onTripChanged);
  }

  void _onTripChanged() {
    if (!mounted) return;
    setState(() {});
  }

  Set<int> _occupiedSeats() {
    if (!widget.inRouteSale) {
      return Set<int>.from(_trip.occupiedSeats);
    }
    final all = Set<int>.from(List.generate(widget.capacidad, (i) => i + 1));
    all.removeAll(_trip.releasedSeats);
    return all;
  }

  @override
  void dispose() {
    _timer?.cancel();
    _trip.removeListener(_onTripChanged);
    super.dispose();
  }

  void _startHoldTimer() {
    _timer?.cancel();
    _secondsLeft = 5 * 60;
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) return;
      setState(() {
        _secondsLeft -= 1;
      });
      if (_secondsLeft <= 0) {
        t.cancel();
        setState(() {
          _selectedSeats.clear();
          _secondsLeft = 0;
        });
        CustomSnackbar.show(
          context,
          message: 'Reserva expirada. Selecciona un asiento nuevamente.',
          isError: true,
        );
      }
    });
  }

  int _freeSeatsCount() {
    final total = widget.capacidad;
    final occupied = _occupiedSeats().length;
    return max(0, total - occupied);
  }

  void _setDesiredCount(int value) {
    final next = value.clamp(1, 4);
    final free = _freeSeatsCount();
    if (next > free) {
      showDialog<void>(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: const Text('Asientos disponibles'),
            content: Text('Solo quedan $free asientos libres.'),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  setState(() {
                    _desiredCount = 1;
                    _selectedSeats.clear();
                    _secondsLeft = 0;
                  });
                },
                child: const Text('Esperar otra unidad'),
              ),
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  setState(() {
                    _desiredCount = max(1, free);
                    while (_selectedSeats.length > _desiredCount) {
                      _selectedSeats.remove(_selectedSeats.last);
                    }
                  });
                },
                child: Text('Comprar $free'),
              ),
            ],
          );
        },
      );
      return;
    }
    setState(() {
      _desiredCount = next;
      while (_selectedSeats.length > _desiredCount) {
        _selectedSeats.remove(_selectedSeats.last);
      }
    });
  }

  void _selectSeat(int seat) {
    if (_occupiedSeats().contains(seat)) return;
    setState(() {
      if (_selectedSeats.contains(seat)) {
        _selectedSeats.remove(seat);
        if (_selectedSeats.isEmpty) {
          _timer?.cancel();
          _secondsLeft = 0;
        }
        return;
      }
      if (_selectedSeats.length >= _desiredCount) return;
      _selectedSeats.add(seat);
    });
    if (_selectedSeats.isNotEmpty && _secondsLeft == 0) {
      _startHoldTimer();
    }
  }

  void _continueToPayment() {
    if (_selectedSeats.isEmpty) {
      CustomSnackbar.show(
        context,
        message: 'Selecciona un asiento para continuar',
        isError: true,
      );
      return;
    }
    if (_selectedSeats.length != _desiredCount) {
      CustomSnackbar.show(
        context,
        message: 'Selecciona $_desiredCount asientos para continuar',
        isError: true,
      );
      return;
    }
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => PassengerPaymentScreen(
          ruta: widget.ruta,
          destino: widget.destino,
          salida: widget.salida,
          stopName: widget.stopName,
          asientos: _selectedSeats.toList()..sort(),
        ),
      ),
    );
  }

  ({int rows, int cols, String template, bool isFallback}) _templateForCapacity(int capacity) {
    switch (capacity) {
      case 4:
        return (rows: 2, cols: 2, template: '2x2', isFallback: false);
      case 6:
        return (rows: 2, cols: 3, template: '2x3', isFallback: false);
      case 8:
        return (rows: 2, cols: 4, template: '2x4', isFallback: false);
      case 15:
        return (rows: 3, cols: 5, template: '3x5', isFallback: false);
      default:
        return (rows: 4, cols: 4, template: 'Genérica', isFallback: true);
    }
  }

  String _formatSeconds(int total) {
    final minutes = (total ~/ 60).toString().padLeft(2, '0');
    final seconds = (total % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    final template = _templateForCapacity(widget.capacidad);
    final seats = List.generate(widget.capacidad, (i) => i + 1);
    final occupied = _occupiedSeats();
    final free = _freeSeatsCount();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mapa de cabina'),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(widget.ruta, style: Theme.of(context).textTheme.titleMedium),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          _InfoPill(icon: Icons.place_outlined, text: widget.destino),
                          _InfoPill(icon: Icons.schedule_outlined, text: widget.salida),
                          _InfoPill(icon: Icons.event_seat_outlined, text: '${widget.capacidad} asientos'),
                          _InfoPill(icon: Icons.place_rounded, text: widget.stopName),
                          _InfoPill(icon: Icons.grid_view_rounded, text: 'Plantilla ${template.template}'),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: [1, 2, 3, 4].map((n) {
                          final selected = _desiredCount == n;
                          return ChoiceChip(
                            label: Text('$n'),
                            selected: selected,
                            onSelected: (_) => _setDesiredCount(n),
                            selectedColor: AppColors.primaryBlue.withOpacity(0.12),
                            backgroundColor: AppColors.white,
                            labelStyle: TextStyle(
                              fontWeight: FontWeight.w700,
                              color: selected ? AppColors.primaryBlue : AppColors.textPrimary,
                            ),
                            side: BorderSide(color: selected ? AppColors.primaryBlue : Colors.grey.shade300),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'Selecciona $_desiredCount asiento(s) • Libres: $free',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      if (widget.inRouteSale) ...[
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                color: AppColors.primaryBlue.withOpacity(0.12),
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: const Icon(Icons.route_rounded, color: AppColors.primaryBlue),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'Venta en ruta: solo asientos liberados por No-show.',
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ),
                          ],
                        ),
                      ],
                      if (template.isFallback) ...[
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                color: AppColors.warning.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: const Icon(Icons.warning_amber_rounded, color: AppColors.warning),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'No se pudo cargar la plantilla. Se usa una cuadrícula genérica.',
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ),
                          ],
                        ),
                      ],
                      if (_secondsLeft > 0 && _selectedSeats.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                color: AppColors.energeticOrange.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: const Icon(Icons.timer_outlined, color: AppColors.energeticOrange),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'Reserva activa por ${_formatSeconds(_secondsLeft)}',
                                style: Theme.of(context).textTheme.bodyMedium,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: const [
                  _SeatLegend(color: AppColors.success, text: 'Libre'),
                  _SeatLegend(color: AppColors.error, text: 'Ocupado'),
                  _SeatLegend(color: AppColors.energeticOrange, text: 'Seleccionado'),
                ],
              ),
              const SizedBox(height: 12),
              Expanded(
                child: GridView.builder(
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: template.cols,
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    childAspectRatio: 1,
                  ),
                  itemCount: seats.length,
                  itemBuilder: (context, index) {
                    final seat = seats[index];
                    final isOccupied = occupied.contains(seat);
                    final isSelected = _selectedSeats.contains(seat);

                    Color bg;
                    Color border;
                    Color text;

                    if (isOccupied) {
                      bg = AppColors.error;
                      border = AppColors.error;
                      text = AppColors.white;
                    } else if (isSelected) {
                      bg = AppColors.energeticOrange;
                      border = AppColors.energeticOrange;
                      text = AppColors.white;
                    } else {
                      bg = AppColors.success;
                      border = AppColors.success;
                      text = AppColors.white;
                    }

                    return InkWell(
                      onTap: isOccupied ? null : () => _selectSeat(seat),
                      borderRadius: BorderRadius.circular(14),
                      child: Container(
                        decoration: BoxDecoration(
                          color: bg,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: border, width: 2),
                        ),
                        child: Center(
                          child: Text(
                            '$seat',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  color: text,
                                  fontWeight: FontWeight.w800,
                                ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 12),
              CustomButton(
                text: 'Continuar a pago (${_selectedSeats.length}/$_desiredCount)',
                onPressed: _continueToPayment,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SeatLegend extends StatelessWidget {
  const _SeatLegend({required this.color, required this.text});

  final Color color;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            text,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: AppColors.textSecondary,
                ),
          ),
        ],
      ),
    );
  }
}

class PassengerPaymentScreen extends StatefulWidget {
  const PassengerPaymentScreen({
    super.key,
    required this.ruta,
    required this.destino,
    required this.salida,
    required this.stopName,
    required this.asientos,
  });

  final String ruta;
  final String destino;
  final String salida;
  final String stopName;
  final List<int> asientos;

  @override
  State<PassengerPaymentScreen> createState() => _PassengerPaymentScreenState();
}

class _PassengerPaymentScreenState extends State<PassengerPaymentScreen> {
  final TripSimulationService _trip = TripSimulationService.instance;
  bool _isProcessing = false;
  final double _farePerSeat = 10.0;

Future<void> _simulatePayment() async {
    setState(() {
      _isProcessing = true;
    });
    await Future.delayed(const Duration(seconds: 2));

    if (!mounted) return;
    SystemSound.play(SystemSoundType.click);
    HapticFeedback.heavyImpact();
    final dni = _trip.currentSessionDni.isEmpty ? '00000000' : _trip.currentSessionDni;
    final booking = _trip.confirmPassengerBooking(
      passengerDni: dni,
      stopName: widget.stopName,
      ruta: widget.ruta,
      destino: widget.destino,
      salida: widget.salida,
      seats: widget.asientos,
      farePerSeat: _farePerSeat,
      driverDni: '22222222',
    );

    // ── Insertar en Supabase tabla Reservas ──
    try {
      final supabase = Supabase.instance.client;
      for (final asiento in widget.asientos) {
        await supabase.from('Reservas').insert({
          'transaction_id': booking.transactionId,
          'pasajero_dni':   dni,
          'ruta':           widget.ruta,
          'destino':        widget.destino,
          'salida':         widget.salida,
          'stop_name':      widget.stopName,
          'asiento':        asiento,
          'total':          _farePerSeat * widget.asientos.length,
          'conductor_dni':  '22222222',
          'created_at':     DateTime.now().toIso8601String(),
        });
      }
    } catch (e) {
      debugPrint('Error al guardar en Supabase: $e');
    }

    if (!mounted) return;
    passengerTicketNotifier.value = PassengerTicketData(
      transactionId: booking.transactionId,
      ruta: widget.ruta,
      destino: widget.destino,
      salida: widget.salida,
      stopName: widget.stopName,
      asientos: widget.asientos,
    );
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (context) => PassengerTicketScreen(
          transactionId: booking.transactionId,
          ruta: widget.ruta,
          destino: widget.destino,
          salida: widget.salida,
          stopName: widget.stopName,
          asientos: widget.asientos,
          codes: booking.tickets.map((t) => t.code).toList(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final total = _farePerSeat * widget.asientos.length;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pago'),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Detalle', style: Theme.of(context).textTheme.titleMedium),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          _InfoPill(icon: Icons.route_outlined, text: widget.ruta),
                          _InfoPill(icon: Icons.place_outlined, text: widget.destino),
                          _InfoPill(icon: Icons.schedule_outlined, text: widget.salida),
                          _InfoPill(icon: Icons.place_rounded, text: widget.stopName),
                          _InfoPill(icon: Icons.event_seat_outlined, text: 'Asientos ${widget.asientos.join(', ')}'),
                          _InfoPill(icon: Icons.payments_outlined, text: 'Total S/ ${total.toStringAsFixed(2)}'),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Container(
                        width: double.infinity,
                        height: 220,
                        decoration: BoxDecoration(
                          color: AppColors.surfaceGrey,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child: const Center(
                          child: Icon(Icons.qr_code_2_rounded, size: 110, color: AppColors.primaryBlue),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Escanea el QR en Yape/Plin para confirmar tu pago.',
                        style: Theme.of(context).textTheme.bodySmall,
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              if (_isProcessing)
                const Center(child: BrandLoadingPanel(message: 'Procesando pago...'))
              else
                CustomButton(
                  text: 'Simular confirmación',
                  onPressed: _simulatePayment,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class PassengerTicketScreen extends StatefulWidget {
  const PassengerTicketScreen({
    super.key,
    required this.transactionId,
    required this.ruta,
    required this.destino,
    required this.salida,
    required this.stopName,
    required this.asientos,
    required this.codes,
  });

  final String transactionId;
  final String ruta;
  final String destino;
  final String salida;
  final String stopName;
  final List<int> asientos;
  final List<String> codes;

  @override
  State<PassengerTicketScreen> createState() => _PassengerTicketScreenState();
}

class _PassengerTicketScreenState extends State<PassengerTicketScreen> {
  final TripSimulationService _trip = TripSimulationService.instance;
  late final List<String> _codes;

  @override
  void initState() {
    super.initState();
    _codes = widget.codes;
  }

  void _backToSearch() {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (context) => const PassengerRouteSearchScreen()),
      (route) => false,
    );
  }

  void _openTracking() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => const PassengerLiveTrackingScreen()),
    );
  }

  Future<void> _copyAllCodes() async {
    if (_codes.isEmpty) return;
    await Clipboard.setData(ClipboardData(text: _codes.join('\n')));
    if (!mounted) return;
    CustomSnackbar.show(
      context,
      message: 'Códigos copiados',
      isSuccess: true,
    );
  }

  Future<void> _copyCode(String code) async {
    await Clipboard.setData(ClipboardData(text: code));
    if (!mounted) return;
    CustomSnackbar.show(
      context,
      message: 'Código copiado',
      isSuccess: true,
    );
  }

  Future<void> _openQuickChat() async {
    final dni = _trip.currentSessionDni.isEmpty ? '00000000' : _trip.currentSessionDni;
    final conversationId = 'chat|$dni|22222222';
    _trip.markChatRead(conversationId: conversationId, readerDni: dni);

    const phrases = [
      'Ya llegué',
      'Esperando',
      'Estoy en el paradero',
      '¿Dónde estás?',
    ];

    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        return SafeArea(
          child: AnimatedBuilder(
            animation: _trip,
            builder: (context, _) {
              final messages = _trip.chatFor(conversationId);
              return Padding(
                padding: EdgeInsets.only(
                  left: 20,
                  right: 20,
                  top: 12,
                  bottom: 20 + MediaQuery.of(context).viewInsets.bottom,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text('Chat rápido • Conductor', style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 12),
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxHeight: 280),
                      child: ListView(
                        shrinkWrap: true,
                        children: messages.map((m) {
                          final mine = m.fromDni == dni;
                          final bg = mine ? AppColors.primaryBlue.withOpacity(0.12) : Colors.grey.shade200;
                          final align = mine ? CrossAxisAlignment.end : CrossAxisAlignment.start;
                          final status = mine ? (m.readAt == null ? 'Enviado' : 'Leído') : '';
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 6),
                            child: Column(
                              crossAxisAlignment: align,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                  decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(12)),
                                  child: Text(m.text),
                                ),
                                if (status.isNotEmpty) ...[
                                  const SizedBox(height: 4),
                                  Text(status, style: Theme.of(context).textTheme.bodySmall),
                                ],
                              ],
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: phrases.map((p) {
                        return ActionChip(
                          label: Text(p),
                          onPressed: () {
                            final r = _trip.sendQuickChat(
                              conversationId: conversationId,
                              fromRole: 'Pasajero',
                              fromDni: dni,
                              toDni: '22222222',
                              text: p,
                            );
                            if (!r.ok) {
                              CustomSnackbar.show(context, message: r.message, isError: true);
                            } else {
                              CustomSnackbar.show(context, message: r.message, isSuccess: true);
                            }
                          },
                        );
                      }).toList(),
                    ),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ticket'),
      ),
      body: SafeArea(
        child: AnimatedBuilder(
          animation: _trip,
          builder: (context, _) {
            final vehicle = _trip.assignedVehicle;
            return Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                      Container(
                        width: double.infinity,
                        height: 220,
                        decoration: BoxDecoration(
                          color: AppColors.surfaceGrey,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child: const Center(
                          child: Icon(Icons.qr_code_2_rounded, size: 120, color: AppColors.primaryBlue),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Ticket QR Digital',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        alignment: WrapAlignment.center,
                        children: [
                          _InfoPill(icon: Icons.route_outlined, text: widget.ruta),
                          _InfoPill(icon: Icons.place_outlined, text: widget.destino),
                          _InfoPill(icon: Icons.schedule_outlined, text: widget.salida),
                          _InfoPill(icon: Icons.place_rounded, text: widget.stopName),
                          _InfoPill(icon: Icons.event_seat_outlined, text: 'Asientos ${widget.asientos.join(', ')}'),
                          _InfoPill(icon: Icons.directions_bus_filled_rounded, text: '${vehicle.placa} • ${vehicle.model} • ${vehicle.colorName}'),
                        ],
                      ),
                      const SizedBox(height: 12),
                      if (_codes.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppColors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.grey.shade300),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Row(
                                children: [
                                  const Icon(Icons.confirmation_number_rounded, color: AppColors.primaryBlue),
                                  const SizedBox(width: 10),
                                  Expanded(child: Text('Códigos QR (demo)', style: Theme.of(context).textTheme.titleSmall)),
                                  IconButton(
                                    onPressed: _copyAllCodes,
                                    icon: const Icon(Icons.copy_rounded),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              ..._codes.map((c) {
                                return Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 6),
                                  child: Row(
                                    children: [
                                      const Icon(Icons.qr_code_2_rounded, color: AppColors.primaryBlue, size: 18),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: SelectableText(
                                          c,
                                          style: Theme.of(context).textTheme.bodySmall,
                                        ),
                                      ),
                                      IconButton(
                                        onPressed: () => _copyCode(c),
                                        icon: const Icon(Icons.copy_rounded),
                                      ),
                                    ],
                                  ),
                                );
                              }),
                            ],
                          ),
                        ),
                      ],
                    ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  CustomButton(
                    text: 'Seguimiento en vivo',
                    onPressed: _openTracking,
                  ),
                  const SizedBox(height: 12),
                  CustomButton(
                    text: 'Chat rápido',
                    onPressed: _openQuickChat,
                  ),
                  const Spacer(),
                  CustomButton(
                    text: 'Volver a buscar',
                    onPressed: _backToSearch,
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class PassengerLiveTrackingScreen extends StatefulWidget {
  const PassengerLiveTrackingScreen({super.key});

  @override
  State<PassengerLiveTrackingScreen> createState() => _PassengerLiveTrackingScreenState();
}

class _PassengerLiveTrackingScreenState extends State<PassengerLiveTrackingScreen> {
  final TripSimulationService _trip = TripSimulationService.instance;
  bool _geofenceShown = false;
  bool _ratingPromptShown = false;
  bool _surveyPromptShown = false;
  bool _panicHolding = false;
  double _panicProgress = 0;
  Timer? _panicTimer;

  @override
  void initState() {
    super.initState();
    _trip.addListener(_onTripChanged);
  }

  @override
  void dispose() {
    _panicTimer?.cancel();
    _trip.removeListener(_onTripChanged);
    super.dispose();
  }

  void _onTripChanged() {
    if (!mounted) return;
    if (_trip.passengerGeofenceFired && !_geofenceShown) {
      _geofenceShown = true;
      HapticFeedback.mediumImpact();
      CustomSnackbar.show(
        context,
        message: 'Tu transporte está llegando',
        isSuccess: true,
      );
    }
    final dni = _trip.currentSessionDni.isEmpty ? '00000000' : _trip.currentSessionDni;
    final pendingRating = _trip.latestFinalizedUnratedTrip(dni);
    if (pendingRating != null && !_ratingPromptShown) {
      _ratingPromptShown = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _openRating(trip: pendingRating, passengerDni: dni);
      });
    }
    final hasFinalized = _trip.tripHistoryOf(dni).any((t) => t.status == 'Finalizado');
    if (pendingRating == null && hasFinalized && _trip.shouldShowSurvey(dni) && !_surveyPromptShown) {
      _surveyPromptShown = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _openSurveyDialog(passengerDni: dni);
      });
    }
    setState(() {});
  }

  Future<void> _openSurveyDialog({required String passengerDni}) async {
    var q1 = 5;
    var q2 = 5;
    var q3 = 5;
    await showDialog<void>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setLocal) {
            Widget row(String title, int value, void Function(int) setValue) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(title, style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: List.generate(5, (i) {
                      final v = i + 1;
                      final selected = value == v;
                      return ChoiceChip(
                        label: Text('$v'),
                        selected: selected,
                        onSelected: (_) => setLocal(() => setValue(v)),
                        selectedColor: AppColors.primaryBlue.withOpacity(0.12),
                        backgroundColor: AppColors.white,
                        labelStyle: TextStyle(fontWeight: FontWeight.w800, color: selected ? AppColors.primaryBlue : AppColors.textPrimary),
                        side: BorderSide(color: selected ? AppColors.primaryBlue : Colors.grey.shade300),
                      );
                    }),
                  ),
                ],
              );
            }

            return AlertDialog(
              title: const Text('Encuesta de satisfacción'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    row('1) ¿Qué tan fácil fue reservar?', q1, (v) => q1 = v),
                    const SizedBox(height: 12),
                    row('2) ¿Qué tan satisfecho con el viaje?', q2, (v) => q2 = v),
                    const SizedBox(height: 12),
                    row('3) ¿Recomendarías la app?', q3, (v) => q3 = v),
                  ],
                ),
              ),
              actions: [
                TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Luego')),
                TextButton(
                  onPressed: () {
                    final ok = _trip.submitSurvey(passengerDni: passengerDni, q1: q1, q2: q2, q3: q3);
                    Navigator.of(context).pop();
                    CustomSnackbar.show(
                      this.context,
                      message: ok ? 'Gracias por tu respuesta' : 'Ya respondiste este mes',
                      isSuccess: ok,
                      isError: !ok,
                    );
                  },
                  child: const Text('Enviar'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _openRating({required PassengerTripRecord trip, required String passengerDni}) async {
    var stars = 5;
    final TextEditingController controller = TextEditingController();

    await showDialog<void>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setLocal) {
            return AlertDialog(
              title: const Text('Calificar servicio'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text('${trip.placa} • ${trip.vehicleModel}', style: Theme.of(context).textTheme.bodySmall),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(5, (i) {
                      final v = i + 1;
                      final selected = v <= stars;
                      return IconButton(
                        onPressed: () => setLocal(() => stars = v),
                        icon: Icon(selected ? Icons.star_rounded : Icons.star_border_rounded, color: AppColors.energeticOrange),
                      );
                    }),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: controller,
                    decoration: const InputDecoration(
                      labelText: 'Comentario (opcional)',
                      prefixIcon: Icon(Icons.chat_bubble_outline_rounded),
                    ),
                    maxLines: 2,
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Luego'),
                ),
                TextButton(
                  onPressed: () {
                    final res = _trip.submitRating(
                      tripId: trip.id,
                      passengerDni: passengerDni,
                      stars: stars,
                      comment: controller.text,
                    );
                    Navigator.of(context).pop();
                    CustomSnackbar.show(
                      this.context,
                      message: res.message,
                      isSuccess: res.ok,
                      isError: !res.ok,
                    );
                  },
                  child: const Text('Enviar'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  String _formatEta(Duration d) {
    final m = d.inMinutes;
    final s = d.inSeconds % 60;
    if (m <= 0) return '${s}s';
    return '${m}m ${s}s';
  }

  void _startPanicHold() {
    if (_panicHolding) return;
    setState(() {
      _panicHolding = true;
      _panicProgress = 0;
    });
    _panicTimer?.cancel();
    _panicTimer = Timer.periodic(const Duration(milliseconds: 50), (t) async {
      if (!mounted) return;
      final next = _panicProgress + (50 / 3000);
      if (next >= 1) {
        t.cancel();
        _panicTimer = null;
        setState(() {
          _panicProgress = 1;
          _panicHolding = false;
        });
        await _triggerPanic();
        return;
      }
      setState(() {
        _panicProgress = next;
      });
    });
  }

  void _cancelPanicHold() {
    _panicTimer?.cancel();
    _panicTimer = null;
    if (!_panicHolding && _panicProgress == 0) return;
    setState(() {
      _panicHolding = false;
      _panicProgress = 0;
    });
  }

  Future<void> _shareLocation() async {
    final dni = _trip.currentSessionDni.isEmpty ? '00000000' : _trip.currentSessionDni;
    if (!_trip.isRunning) {
      CustomSnackbar.show(context, message: 'Disponible al iniciar el viaje', isError: true);
      return;
    }
    final url = _trip.createShareLink(passengerDni: dni, validFor: const Duration(hours: 1));
    await Clipboard.setData(ClipboardData(text: url));
    if (!mounted) return;
    CustomSnackbar.show(context, message: 'Enlace copiado. Pégalo en WhatsApp.', isSuccess: true);
  }

  Future<void> _triggerPanic() async {
    _trip.activateEmergency(role: 'Pasajero', sourceDni: '00000000');
    SystemSound.play(SystemSoundType.alert);

    final TextEditingController codeController = TextEditingController();
    var secondsLeft = 5;
    Timer? timer;

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setLocalState) {
            timer ??= Timer.periodic(const Duration(seconds: 1), (t) {
              if (secondsLeft <= 1) {
                t.cancel();
                Navigator.of(context).pop();
                return;
              }
              setLocalState(() {
                secondsLeft -= 1;
              });
            });

            return AlertDialog(
              title: const Text('SOS activado'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text('Puedes cancelar en $secondsLeft s con el código de seguridad.'),
                  const SizedBox(height: 12),
                  TextField(
                    controller: codeController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Código',
                      hintText: 'Ej: 1234',
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    if (codeController.text.trim() == '1234') {
                      _trip.clearEmergency();
                      timer?.cancel();
                      Navigator.of(context).pop();
                      return;
                    }
                    CustomSnackbar.show(
                      this.context,
                      message: 'Código incorrecto',
                      isError: true,
                    );
                  },
                  child: const Text('Cancelar SOS'),
                ),
                TextButton(
                  onPressed: () {
                    timer?.cancel();
                    Navigator.of(context).pop();
                  },
                  child: const Text('Continuar'),
                ),
              ],
            );
          },
        );
      },
    );

    timer?.cancel();
  }

  @override
  Widget build(BuildContext context) {
    final vehicle = _trip.vehicleMeters;
    final stop = _trip.passengerStopMeters;
    final dist = _trip.distanceMeters(vehicle, stop);
    final eta = _trip.etaTo(stop);
    final stuck = DateTime.now().difference(_trip.lastMovedAt) > const Duration(minutes: 3);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Seguimiento en vivo'),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            if (_trip.activeEmergency != null)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: AppColors.error.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Icon(Icons.sos_rounded, color: AppColors.error),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'SOS activo. Ubicación enviada a la central (demo).',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ),
                      IconButton(
                        onPressed: _trip.clearEmergency,
                        icon: const Icon(Icons.close_rounded),
                      ),
                    ],
                  ),
                ),
              ),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: AppColors.primaryBlue.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(Icons.directions_bus_filled_rounded, color: AppColors.primaryBlue),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _trip.isRunning ? 'Unidad en movimiento' : 'Última ubicación',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            stuck ? 'Tráfico denso detectado' : 'ETA se actualiza (demo)',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: stuck ? AppColors.energeticOrange : AppColors.textSecondary,
                                  fontWeight: FontWeight.w700,
                                ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: (_trip.isRunning ? AppColors.success : AppColors.warning).withOpacity(0.15),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        _trip.isRunning ? 'En ruta' : 'Sin señal',
                        style: TextStyle(
                          color: _trip.isRunning ? AppColors.success : AppColors.warning,
                          fontWeight: FontWeight.w700,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text('Mapa (demo)', style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 12),
                    SizedBox(
                      height: 220,
                      child: LayoutBuilder(
                        builder: (context, c) {
                          final w = c.maxWidth;
                          final h = c.maxHeight;

                          Offset toCanvas(Offset meters) {
                            final speed = _trip.lastSpeedKmh;
                            final zoomOut = speed > 40;
                            final visibleW = zoomOut ? 6000.0 : 1800.0;
                            final visibleH = zoomOut ? 900.0 : 300.0;
                            final center = vehicle;
                            final nx = (((meters.dx - center.dx) / visibleW) + 0.5).clamp(0.0, 1.0);
                            final ny = (((meters.dy - center.dy) / visibleH) + 0.5).clamp(0.0, 1.0);
                            return Offset(nx * w, ny * h);
                          }

                          final v = toCanvas(vehicle);
                          final s = toCanvas(stop);

                          return Stack(
                            children: [
                              Container(
                                decoration: BoxDecoration(
                                  color: AppColors.surfaceGrey,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(color: Colors.grey.shade300),
                                ),
                              ),
                              Positioned(
                                left: s.dx - 10,
                                top: s.dy - 10,
                                child: Container(
                                  width: 20,
                                  height: 20,
                                  decoration: BoxDecoration(
                                    color: AppColors.energeticOrange.withOpacity(0.25),
                                    borderRadius: BorderRadius.circular(999),
                                    border: Border.all(color: AppColors.energeticOrange, width: 2),
                                  ),
                                ),
                              ),
                              Positioned(
                                left: v.dx - 10,
                                top: v.dy - 10,
                                child: Container(
                                  width: 20,
                                  height: 20,
                                  decoration: BoxDecoration(
                                    color: AppColors.primaryBlue,
                                    borderRadius: BorderRadius.circular(999),
                                  ),
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _InfoPill(icon: Icons.social_distance_rounded, text: '${dist.round()} m'),
                        _InfoPill(icon: Icons.timer_outlined, text: 'ETA ${_formatEta(eta)}'),
                        _InfoPill(icon: Icons.my_location_rounded, text: '${_trip.gpsLogMeters.length} pts'),
                        _InfoPill(icon: Icons.cloud_rounded, text: '${_trip.weather.condition} ${_trip.weather.temperatureC}°C'),
                        _InfoPill(
                          icon: Icons.zoom_out_map_rounded,
                          text: _trip.lastSpeedKmh > 40 ? 'Zoom out' : 'Zoom in',
                        ),
                        if (_trip.isEmergencyStopActive) const _InfoPill(icon: Icons.pause_circle_filled_rounded, text: 'Detención'),
                      ],
                    ),
                    const SizedBox(height: 12),
                    CustomButton(
                      text: 'Compartir ubicación',
                      onPressed: _shareLocation,
                    ),
                    const SizedBox(height: 12),
                    if (!_trip.isRunning)
                      CustomButton(
                        text: 'Simular inicio de ruta',
                        onPressed: () {
                          _trip.resetTrip();
                          _trip.start();
                        },
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text('Emergencia', style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 10),
                    GestureDetector(
                      onTapDown: (_) => _startPanicHold(),
                      onTapUp: (_) => _cancelPanicHold(),
                      onTapCancel: _cancelPanicHold,
                      child: Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: AppColors.error.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: AppColors.error.withOpacity(0.25)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.sos_rounded, color: AppColors.error),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    _panicHolding ? 'Mantén presionado...' : 'Mantén 3s para activar SOS',
                                    style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w900),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(999),
                              child: LinearProgressIndicator(
                                value: _panicHolding ? _panicProgress : 0,
                                minHeight: 8,
                                backgroundColor: AppColors.white,
                                valueColor: const AlwaysStoppedAnimation(AppColors.error),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class PassengerSignUpScreen extends StatefulWidget {
  const PassengerSignUpScreen({super.key});

  @override
  State<PassengerSignUpScreen> createState() => _PassengerSignUpScreenState();
}

class _PassengerSignUpScreenState extends State<PassengerSignUpScreen> {
  final TextEditingController _dniController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();

  void _createUser() {
    if (_dniController.text.trim().length != 8 || _nameController.text.trim().isEmpty) {
      CustomSnackbar.show(
        context,
        message: 'Completa correctamente los campos',
        isError: true,
      );
      return;
    }
    CustomSnackbar.show(
      context,
      message: 'Usuario creado (demo)',
      isSuccess: true,
    );
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Crear usuario'),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    CustomTextField(
                      label: 'DNI',
                      hint: 'Ej: 12345678',
                      keyboardType: TextInputType.number,
                      controller: _dniController,
                    ),
                    const SizedBox(height: 16),
                    CustomTextField(
                      label: 'Nombre completo',
                      hint: 'Ej: Juan Pérez',
                      controller: _nameController,
                    ),
                    const SizedBox(height: 16),
                    CustomTextField(
                      label: 'Teléfono',
                      hint: 'Ej: 999888777',
                      keyboardType: TextInputType.phone,
                      controller: _phoneController,
                    ),
                    const SizedBox(height: 20),
                    CustomButton(
                      text: 'Crear usuario',
                      onPressed: _createUser,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoPill extends StatelessWidget {
  const _InfoPill({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.surfaceGrey,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: AppColors.textSecondary),
          const SizedBox(width: 6),
          Text(
            text,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary,
                ),
          ),
        ],
      ),
    );
  }
}
