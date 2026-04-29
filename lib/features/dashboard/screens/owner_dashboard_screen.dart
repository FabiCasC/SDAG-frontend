import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/services/trip_simulation_service.dart';
import '../../auth/screens/login_screen.dart';
import '../../pricing/screens/pricing_screen.dart';
import '../../staff/screens/staff_management_screen.dart';
import '../../../shared/widgets/custom_button.dart';
import '../../../shared/widgets/custom_snackbar.dart';
import '../../../shared/widgets/custom_text_field.dart';

class OwnerNavShell extends StatefulWidget {
  const OwnerNavShell({super.key});

  @override
  State<OwnerNavShell> createState() => _OwnerNavShellState();
}

class _OwnerNavShellState extends State<OwnerNavShell> {
  int _index = 0;
  late final List<GlobalKey<NavigatorState>> _navKeys;

  @override
  void initState() {
    super.initState();
    _navKeys = List.generate(5, (_) => GlobalKey<NavigatorState>());
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
          _buildTabNavigator(index: 0, child: const OwnerDashboardScreen()),
          _buildTabNavigator(index: 1, child: const OwnerFleetManagementScreen()),
          _buildTabNavigator(index: 2, child: const StaffManagementScreen()),
          _buildTabNavigator(index: 3, child: const PricingScreen()),
          _buildTabNavigator(index: 4, child: const OwnerAuditScreen()),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: [
          NavigationDestination(
            icon: const Icon(Icons.dashboard_rounded),
            label: AppTheme.t(es: 'Inicio', en: 'Home'),
          ),
          NavigationDestination(
            icon: const Icon(Icons.directions_bus_filled_rounded),
            label: AppTheme.t(es: 'Flota', en: 'Fleet'),
          ),
          NavigationDestination(
            icon: const Icon(Icons.groups_rounded),
            label: AppTheme.t(es: 'Staff', en: 'Staff'),
          ),
          NavigationDestination(
            icon: const Icon(Icons.attach_money_rounded),
            label: AppTheme.t(es: 'Tarifas', en: 'Pricing'),
          ),
          NavigationDestination(
            icon: const Icon(Icons.verified_user_rounded),
            label: AppTheme.t(es: 'Auditoría', en: 'Audit'),
          ),
        ],
      ),
    );
  }
}

class OwnerLanguageScreen extends StatelessWidget {
  const OwnerLanguageScreen({super.key});

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

class OwnerSupportFeedbackScreen extends StatefulWidget {
  const OwnerSupportFeedbackScreen({super.key});

  @override
  State<OwnerSupportFeedbackScreen> createState() => _OwnerSupportFeedbackScreenState();
}

class _OwnerSupportFeedbackScreenState extends State<OwnerSupportFeedbackScreen> {
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
    final dni = _trip.currentSessionDni.isEmpty ? '11111111' : _trip.currentSessionDni;
    final role = _trip.currentSessionRole.isEmpty ? 'Dueño' : _trip.currentSessionRole;
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
            final dni = _trip.currentSessionDni.isEmpty ? '11111111' : _trip.currentSessionDni;
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
                            const _InfoPill(icon: Icons.info_outline_rounded, text: 'Adjunta log (demo)'),
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

class OwnerCreditsScreen extends StatelessWidget {
  const OwnerCreditsScreen({super.key});

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

class OwnerSocialLinksScreen extends StatelessWidget {
  const OwnerSocialLinksScreen({super.key});

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

class OwnerDashboardScreen extends StatefulWidget {
  const OwnerDashboardScreen({Key? key}) : super(key: key);

  @override
  State<OwnerDashboardScreen> createState() => _OwnerDashboardScreenState();
}

class _OwnerDashboardScreenState extends State<OwnerDashboardScreen> {
  final List<Map<String, dynamic>> _kpis = const [
    {'title': 'Unidades', 'value': '12', 'icon': Icons.directions_bus_filled_rounded},
    {'title': 'En carga', 'value': '5', 'icon': Icons.timelapse_rounded},
    {'title': 'Ingresos', 'value': 'S/ 1,240', 'icon': Icons.payments_rounded},
    {'title': 'Ocupación', 'value': '78%', 'icon': Icons.stacked_bar_chart_rounded},
  ];

  void _logout() {
    Navigator.of(context, rootNavigator: true).pushAndRemoveUntil(
      MaterialPageRoute(builder: (context) => const LoginScreen()),
      (route) => false,
    );
  }

  void _openFleetManagement() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => const OwnerFleetManagementScreen()),
    );
  }

  void _openStaffManagement() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => const StaffManagementScreen()),
    );
  }

  void _openPricing() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => const PricingScreen()),
    );
  }

  void _openAudit() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => const OwnerAuditScreen()),
    );
  }

  void _openDriverSearch() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => const OwnerDriverSearchScreen()),
    );
  }

  void _openLostAndFound() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => const OwnerLostAndFoundScreen()),
    );
  }

  void _openMaintenance() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => const OwnerMaintenanceScreen()),
    );
  }

  void _openEarnings() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => const OwnerWeeklyEarningsScreen()),
    );
  }

  void _openSupport() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => const OwnerSupportFeedbackScreen()),
    );
  }

  void _openCredits() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => const OwnerCreditsScreen()),
    );
  }

  void _openSocialLinks() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => const OwnerSocialLinksScreen()),
    );
  }

  void _openExportReports() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => const OwnerExportReportsScreen()),
    );
  }

  void _openFleetMonitor() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => const OwnerFleetMonitoringScreen()),
    );
  }

  void _openTurns() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => const OwnerTurnsQueueScreen()),
    );
  }

  void _openStopsDashboard() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => const OwnerStopsDashboardScreen()),
    );
  }

  void _openDocAlerts() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => const OwnerDocumentAlertsScreen()),
    );
  }

  void _openIncidents() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => const OwnerIncidentsScreen()),
    );
  }

  void _openRouteNews() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => const OwnerRouteNewsScreen()),
    );
  }

  void _openPunctualityReport() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => const OwnerPunctualityReportScreen()),
    );
  }

  void _openRatingsReview() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => const OwnerRatingsReviewScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard Dueño'),
        actions: [
          IconButton(
            tooltip: 'Idioma',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => const OwnerLanguageScreen()),
              );
            },
            icon: const Icon(Icons.language_rounded),
          ),
          IconButton(
            tooltip: 'Salir',
            onPressed: _logout,
            icon: const Icon(Icons.logout_rounded),
          ),
        ],
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
                      child: const Icon(Icons.dashboard_rounded, color: AppColors.primaryBlue),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Control y métricas', style: Theme.of(context).textTheme.titleLarge),
                          const SizedBox(height: 4),
                          Text(
                            'Accede a KPIs y a los módulos de gestión.',
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
            Text('KPIs', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 10),
            LayoutBuilder(
              builder: (context, constraints) {
                final crossAxisCount = constraints.maxWidth >= 560 ? 4 : 2;
                return GridView.count(
                  crossAxisCount: crossAxisCount,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  children: _kpis.map((kpi) {
                    return Card(
                      child: Padding(
                        padding: const EdgeInsets.all(14),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                color: AppColors.primaryBlue.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: Icon(kpi['icon'] as IconData, color: AppColors.primaryBlue),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              kpi['value'] as String,
                              style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              kpi['title'] as String,
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                );
              },
            ),
            const SizedBox(height: 20),
            Text('Operación', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 10),
            _NavCard(
              icon: Icons.map_rounded,
              title: 'Monitoreo global de flota',
              subtitle: 'Ubicación y estado de unidades en tiempo real',
              onTap: _openFleetMonitor,
            ),
            _NavCard(
              icon: Icons.queue_rounded,
              title: 'Gestión de turnos',
              subtitle: 'Cola de despacho en cochera',
              onTap: _openTurns,
            ),
            _NavCard(
              icon: Icons.location_on_rounded,
              title: 'Dashboard de paraderos',
              subtitle: 'Demanda por punto y horas pico',
              onTap: _openStopsDashboard,
            ),
            _NavCard(
              icon: Icons.assignment_late_rounded,
              title: 'Documentos por vencer',
              subtitle: 'Alertas 48h antes (demo)',
              onTap: _openDocAlerts,
            ),
            _NavCard(
              icon: Icons.report_rounded,
              title: 'Historial de incidencias',
              subtitle: 'Registro cronológico de operación',
              onTap: _openIncidents,
            ),
            _NavCard(
              icon: Icons.campaign_rounded,
              title: 'Noticias de la ruta',
              subtitle: 'Enviar avisos y emergencias (demo)',
              onTap: _openRouteNews,
            ),
            _NavCard(
              icon: Icons.star_rounded,
              title: 'Revisión de calificaciones',
              subtitle: 'Casos de 1 estrella sin comentario',
              onTap: _openRatingsReview,
            ),
            _NavCard(
              icon: Icons.access_time_rounded,
              title: 'Puntualidad mensual',
              subtitle: 'Ranking por tiempos de salida',
              onTap: _openPunctualityReport,
            ),
            const SizedBox(height: 20),
            Text('Gestión', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 10),
            _NavCard(
              icon: Icons.directions_bus_filled_rounded,
              title: 'Gestionar vehículos',
              subtitle: 'Registro de placas y capacidades',
              onTap: _openFleetManagement,
            ),
            _NavCard(
              icon: Icons.groups_rounded,
              title: 'Gestionar staff',
              subtitle: 'Crear chofer y vincular a una placa',
              onTap: _openStaffManagement,
            ),
            _NavCard(
              icon: Icons.attach_money_rounded,
              title: 'Tarifario',
              subtitle: 'Definir precios por ruta',
              onTap: _openPricing,
            ),
            _NavCard(
              icon: Icons.verified_user_rounded,
              title: 'Auditoría',
              subtitle: 'Validar pagos de comisión en efectivo',
              onTap: _openAudit,
            ),
            const SizedBox(height: 12),
            Text('Reportes y soporte', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 10),
            _NavCard(
              icon: Icons.search_rounded,
              title: 'Buscar conductores',
              subtitle: 'Filtrar por nombre o DNI',
              onTap: _openDriverSearch,
            ),
            _NavCard(
              icon: Icons.inventory_2_rounded,
              title: 'Objetos perdidos',
              subtitle: 'Registrar y consultar reportes',
              onTap: _openLostAndFound,
            ),
            _NavCard(
              icon: Icons.build_circle_rounded,
              title: 'Mantenimiento preventivo',
              subtitle: 'Registrar fechas de mantenimiento por unidad',
              onTap: _openMaintenance,
            ),
            _NavCard(
              icon: Icons.show_chart_rounded,
              title: 'Ganancias semanales',
              subtitle: 'Ver tendencia y total',
              onTap: _openEarnings,
            ),
            _NavCard(
              icon: Icons.download_rounded,
              title: 'Exportar reportes',
              subtitle: 'Copiar tabla (PDF/Excel demo)',
              onTap: _openExportReports,
            ),
            _NavCard(
              icon: Icons.support_agent_rounded,
              title: 'Soporte técnico',
              subtitle: 'Enviar reportes y sugerencias',
              onTap: _openSupport,
            ),
            _NavCard(
              icon: Icons.public_rounded,
              title: 'Redes sociales',
              subtitle: 'Facebook / Instagram',
              onTap: _openSocialLinks,
            ),
            _NavCard(
              icon: Icons.info_outline_rounded,
              title: 'Créditos',
              subtitle: 'Equipo y versión',
              onTap: _openCredits,
            ),
          ],
        ),
      ),
    );
  }
}

class OwnerFleetMonitoringScreen extends StatefulWidget {
  const OwnerFleetMonitoringScreen({super.key});

  @override
  State<OwnerFleetMonitoringScreen> createState() => _OwnerFleetMonitoringScreenState();
}

class _FleetUnit {
  _FleetUnit({
    required this.placa,
    required this.capacity,
    required this.positionMeters,
    required this.status,
    required this.online,
    required this.lastSeen,
    required this.filled,
  });

  final String placa;
  final int capacity;
  Offset positionMeters;
  String status;
  bool online;
  DateTime lastSeen;
  int filled;
}

class _OwnerFleetMonitoringScreenState extends State<OwnerFleetMonitoringScreen> {
  final TripSimulationService _trip = TripSimulationService.instance;
  final List<_FleetUnit> _units = [];
  Timer? _timer;
  final Random _rng = Random();

  @override
  void initState() {
    super.initState();
    _seedUnits();
    _trip.addListener(_onTripChanged);
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => _tick());
  }

  @override
  void dispose() {
    _timer?.cancel();
    _trip.removeListener(_onTripChanged);
    super.dispose();
  }

  void _seedUnits() {
    if (_units.isNotEmpty) return;

    for (var i = 0; i < 40; i += 1) {
      final placa = i == 0 ? 'BJK-102' : 'SDG-${(100 + i).toString()}';
      final capacity = [4, 6, 8, 15][_rng.nextInt(4)];
      final status = i == 0 ? 'En ruta' : (_rng.nextBool() ? 'Carga' : 'En ruta');
      final online = i == 0 ? true : _rng.nextInt(10) != 0;
      final lastSeen = DateTime.now().subtract(Duration(minutes: _rng.nextInt(25)));
      _units.add(
        _FleetUnit(
          placa: placa,
          capacity: capacity,
          positionMeters: Offset(_rng.nextDouble() * 6000, _rng.nextDouble() * 900),
          status: status,
          online: online,
          lastSeen: lastSeen,
          filled: _rng.nextInt(capacity + 1),
        ),
      );
    }
  }

  void _onTripChanged() {
    if (!mounted) return;
    setState(() {});
  }

  void _tick() {
    if (!mounted) return;

    final now = DateTime.now();
    for (final u in _units) {
      if (u.placa == 'BJK-102') {
        u.online = true;
        u.lastSeen = now;
        u.positionMeters = _trip.vehicleMeters;
        u.status = _trip.isRunning ? 'En ruta' : 'Detenido';
        continue;
      }

      if (_rng.nextInt(70) == 0) {
        u.online = false;
      }
      if (!u.online) continue;

      u.lastSeen = now;
      final dx = (_rng.nextDouble() - 0.5) * 220;
      final dy = (_rng.nextDouble() - 0.5) * 90;
      u.positionMeters = Offset(
        (u.positionMeters.dx + dx).clamp(0, 6000),
        (u.positionMeters.dy + dy).clamp(0, 900),
      );
      if (u.status == 'Carga') {
        u.filled = (u.filled + _rng.nextInt(2)).clamp(0, u.capacity);
        if (u.filled >= u.capacity && _rng.nextInt(4) == 0) {
          u.status = 'En ruta';
        }
      } else if (u.status == 'En ruta') {
        if (_rng.nextInt(50) == 0) {
          u.status = 'Carga';
          u.filled = _rng.nextInt(u.capacity + 1);
        }
      }
    }

    setState(() {});
  }

  Color _markerColor(_FleetUnit u) {
    final emergency = _trip.activeEmergency != null && u.placa == 'BJK-102';
    if (emergency) return AppColors.error;
    if (!u.online) return Colors.grey;
    final deviation = _trip.deviationMeters > 200 && !_trip.deviationJustified && u.placa == 'BJK-102';
    if (deviation) return AppColors.energeticOrange;
    if (u.placa == 'BJK-102' && _trip.lastSpeedKmh > 90) return const Color(0xFF7C3AED);
    if (u.status == 'En ruta') return AppColors.success;
    if (u.status == 'Carga') return AppColors.primaryBlue;
    if (u.status == 'Fuera de servicio') return AppColors.energeticOrange;
    return AppColors.textSecondary;
  }

  void _openUnitDetails(_FleetUnit unit) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        final emergency = _trip.activeEmergency != null && unit.placa == 'BJK-102';
        final deviation = _trip.deviationMeters > 200 && !_trip.deviationJustified && unit.placa == 'BJK-102';
        final offlineMinutes = DateTime.now().difference(unit.lastSeen).inMinutes;

        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: ListView(
              shrinkWrap: true,
              children: [
                Text(
                  'Unidad ${unit.placa}',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _InfoPill(icon: Icons.event_seat_rounded, text: '${unit.filled}/${unit.capacity}'),
                    _InfoPill(icon: Icons.wifi_rounded, text: unit.online ? 'En línea' : 'Fuera de línea ($offlineMinutes min)'),
                    _InfoPill(icon: Icons.flag_rounded, text: unit.status),
                    if (unit.placa == 'BJK-102') _InfoPill(icon: Icons.speed_rounded, text: '${_trip.lastSpeedKmh.toStringAsFixed(0)} km/h'),
                    _InfoPill(icon: Icons.route_rounded, text: 'Km hoy ${_trip.dailyKmForPlaca(unit.placa).toStringAsFixed(1)}'),
                  ],
                ),
                const SizedBox(height: 12),
                if (_trip.isEmergencyStopActive && unit.placa == _trip.assignedVehicle.placa)
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
                            child: const Icon(Icons.pause_circle_filled_rounded, color: AppColors.warning),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Parada técnica activa: ${_trip.emergencyStopElapsed.inMinutes} min',
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                if (emergency)
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
                              'Alerta SOS activa (prioridad alta).',
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                          ),
                          TextButton(
                            onPressed: () {
                              _trip.clearEmergency();
                              Navigator.of(context).pop();
                            },
                            child: const Text('Atender'),
                          ),
                        ],
                      ),
                    ),
                  ),
                if (deviation)
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: AppColors.energeticOrange.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: const Icon(Icons.alt_route_rounded, color: AppColors.energeticOrange),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Desvío detectado: ${_trip.deviationMeters.toStringAsFixed(0)} m',
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                          ),
                          TextButton(
                            onPressed: () {
                              _trip.setDeviationJustified(true);
                              Navigator.of(context).pop();
                            },
                            child: const Text('Justificar'),
                          ),
                        ],
                      ),
                    ),
                  ),
                if (unit.placa == 'BJK-102' && _trip.speedInfractions.isNotEmpty)
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: const Color(0xFF7C3AED).withOpacity(0.15),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: const Icon(Icons.speed_rounded, color: Color(0xFF7C3AED)),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Exceso de velocidad registrado: ${_trip.speedInfractions.last.kmh.toStringAsFixed(0)} km/h',
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                const SizedBox(height: 12),
                Text('Acciones', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 10),
                CustomButton(
                  text: 'Marcar como fuera de servicio',
                  onPressed: () {
                    setState(() {
                      unit.status = 'Fuera de servicio';
                      unit.online = false;
                    });
                    Navigator.of(context).pop();
                    CustomSnackbar.show(
                      this.context,
                      message: 'Unidad marcada fuera de servicio',
                      isSuccess: true,
                    );
                  },
                ),
                const SizedBox(height: 12),
                CustomButton(
                  text: 'Trasbordo por avería',
                  onPressed: () async {
                    final replacements = _units.where((u) => u.placa != unit.placa && u.status != 'En ruta' && u.status != 'Fuera de servicio').toList();
                    if (replacements.isEmpty) {
                      CustomSnackbar.show(
                        this.context,
                        message: 'No hay unidades libres para reemplazo',
                        isError: true,
                      );
                      return;
                    }

                    _FleetUnit? selected = replacements.first;
                    final ok = await showDialog<bool>(
                      context: this.context,
                      builder: (context) {
                        return AlertDialog(
                          title: const Text('Seleccionar reemplazo'),
                          content: DropdownButton<_FleetUnit>(
                            value: selected,
                            isExpanded: true,
                            items: replacements
                                .map((u) => DropdownMenuItem<_FleetUnit>(
                                      value: u,
                                      child: Text('${u.placa} • ${u.capacity} pax'),
                                    ))
                                .toList(),
                            onChanged: (v) => selected = v,
                          ),
                          actions: [
                            TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancelar')),
                            TextButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('Migrar')),
                          ],
                        );
                      },
                    );
                    if (ok != true || selected == null) return;

                    if (selected!.capacity < unit.filled) {
                      await showDialog<void>(
                        context: this.context,
                        builder: (context) {
                          return AlertDialog(
                            title: const Text('Capacidad insuficiente'),
                            content: const Text('La unidad de reemplazo tiene menor capacidad. Asigna un segundo vehículo.'),
                            actions: [
                              TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Entendido')),
                            ],
                          );
                        },
                      );
                    }

                    setState(() {
                      selected!.status = 'En ruta';
                      selected!.filled = unit.filled.clamp(0, selected!.capacity);
                      unit.status = 'Fuera de servicio';
                      unit.online = false;
                    });
                    Navigator.of(this.context).pop();
                    CustomSnackbar.show(
                      this.context,
                      message: 'Trasbordo ejecutado. Pasajeros notificados (demo).',
                      isSuccess: true,
                    );
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final online = _units.where((u) => u.online).length;
    final offline = _units.length - online;
    final enRuta = _units.where((u) => u.status == 'En ruta').length;
    final carga = _units.where((u) => u.status == 'Carga').length;
    final fuera = _units.where((u) => u.status == 'Fuera de servicio').length;
    final emergencyActive = _trip.activeEmergency != null;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Monitoreo de flota'),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            if (emergencyActive)
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
                          'Alerta SOS activa. Toca la unidad para atender.',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ),
                      TextButton(
                        onPressed: _trip.clearEmergency,
                        child: const Text('Limpiar'),
                      ),
                    ],
                  ),
                ),
              ),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text('Unidad asignada (pasajero)', style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      value: _trip.assignedVehicle.placa,
                      items: _trip.fleetVehicles
                          .map((v) => DropdownMenuItem<String>(
                                value: v.placa,
                                child: Text('${v.placa} • ${v.model} • ${v.colorName}'),
                              ))
                          .toList(),
                      onChanged: (value) {
                        final v = _trip.fleetVehicles.where((e) => e.placa == value).toList();
                        if (v.isEmpty) return;
                        _trip.setAssignedVehicle(v.first);
                        CustomSnackbar.show(context, message: 'Unidad actualizada', isSuccess: true);
                      },
                      decoration: const InputDecoration(
                        labelText: 'Seleccionar unidad',
                        prefixIcon: Icon(Icons.directions_bus_filled_rounded),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text('Mapa (demo)', style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 12),
                    SizedBox(
                      height: 280,
                      child: LayoutBuilder(
                        builder: (context, c) {
                          final w = c.maxWidth;
                          final h = c.maxHeight;

                          Offset toCanvas(Offset meters) {
                            final x = (meters.dx / 6000).clamp(0, 1) * w;
                            final y = (meters.dy / 900).clamp(0, 1) * h;
                            return Offset(x, y);
                          }

                          return Stack(
                            children: [
                              Container(
                                decoration: BoxDecoration(
                                  color: AppColors.surfaceGrey,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(color: Colors.grey.shade300),
                                ),
                              ),
                              ..._units.map((u) {
                                final p = toCanvas(u.positionMeters);
                                final color = _markerColor(u);
                                return Positioned(
                                  left: p.dx - 8,
                                  top: p.dy - 8,
                                  child: GestureDetector(
                                    onTap: () => _openUnitDetails(u),
                                    child: Container(
                                      width: 16,
                                      height: 16,
                                      decoration: BoxDecoration(
                                        color: color,
                                        shape: BoxShape.circle,
                                        border: Border.all(color: AppColors.white, width: 2),
                                      ),
                                    ),
                                  ),
                                );
                              }),
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
                        _InfoPill(icon: Icons.wifi_rounded, text: 'Online $online'),
                        _InfoPill(icon: Icons.wifi_off_rounded, text: 'Offline $offline'),
                        _InfoPill(icon: Icons.route_rounded, text: 'En ruta $enRuta'),
                        _InfoPill(icon: Icons.event_seat_rounded, text: 'Carga $carga'),
                        _InfoPill(icon: Icons.build_circle_rounded, text: 'Fuera $fuera'),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text('Unidades', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 10),
            ..._units.take(10).map((u) {
              final color = _markerColor(u);
              final offlineMinutes = DateTime.now().difference(u.lastSeen).inMinutes;
              final subtitle = u.online ? '${u.status} • ${u.filled}/${u.capacity}' : 'Fuera de línea • $offlineMinutes min';
              return Card(
                child: ListTile(
                  contentPadding: const EdgeInsets.all(16),
                  leading: Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(Icons.directions_bus_filled_rounded, color: color),
                  ),
                  title: Text(u.placa),
                  subtitle: Text(subtitle),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => _openUnitDetails(u),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}

class OwnerTurnsQueueScreen extends StatefulWidget {
  const OwnerTurnsQueueScreen({super.key});

  @override
  State<OwnerTurnsQueueScreen> createState() => _OwnerTurnsQueueScreenState();
}

class _OwnerTurnsQueueScreenState extends State<OwnerTurnsQueueScreen> {
  final TripSimulationService _trip = TripSimulationService.instance;

  @override
  void initState() {
    super.initState();
    _trip.addListener(_onChanged);
  }

  @override
  void dispose() {
    _trip.removeListener(_onChanged);
    super.dispose();
  }

  void _onChanged() {
    if (!mounted) return;
    setState(() {});
  }

  void _dispatchFirst() {
    if (_trip.baseQueueDriverDnis.isEmpty) return;
    final first = _trip.baseQueueDriverDnis.first;
    _trip.leaveBase(driverDni: first);
    CustomSnackbar.show(
      context,
      message: 'Despacho autorizado para $first (demo)',
      isSuccess: true,
    );
  }

  @override
  Widget build(BuildContext context) {
    final queue = _trip.baseQueueDriverDnis;
    final next = queue.isEmpty ? null : queue.first;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestión de turnos'),
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
                      child: const Icon(Icons.queue_rounded, color: AppColors.primaryBlue),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        next == null ? 'No hay conductores en cola.' : 'Siguiente turno: $next',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ),
                    Text(
                      '#${queue.length}',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            CustomButton(
              text: 'Despachar #1',
              onPressed: queue.isEmpty ? null : _dispatchFirst,
            ),
            const SizedBox(height: 12),
            Text('Cola', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 10),
            if (queue.isEmpty)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    'Sin registros.',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),
              )
            else
              ...queue.asMap().entries.map((e) {
                final idx = e.key;
                final dni = e.value;
                final isFirst = idx == 0;
                return Card(
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(16),
                    leading: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: (isFirst ? AppColors.success : AppColors.primaryBlue).withOpacity(0.12),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Icon(isFirst ? Icons.verified_rounded : Icons.person_rounded, color: isFirst ? AppColors.success : AppColors.primaryBlue),
                    ),
                    title: Text('Conductor DNI $dni'),
                    subtitle: Text('Turno #${idx + 1}'),
                  ),
                );
              }),
          ],
        ),
      ),
    );
  }
}

class OwnerStopsDashboardScreen extends StatefulWidget {
  const OwnerStopsDashboardScreen({super.key});

  @override
  State<OwnerStopsDashboardScreen> createState() => _OwnerStopsDashboardScreenState();
}

class _OwnerStopsDashboardScreenState extends State<OwnerStopsDashboardScreen> {
  final TripSimulationService _trip = TripSimulationService.instance;

  @override
  void initState() {
    super.initState();
    _trip.addListener(_onChanged);
  }

  @override
  void dispose() {
    _trip.removeListener(_onChanged);
    super.dispose();
  }

  void _onChanged() {
    if (!mounted) return;
    setState(() {});
  }

  int _peakHour(String stop) {
    final byHour = _trip.stopDemandByHour[stop];
    if (byHour == null || byHour.isEmpty) return -1;
    var bestHour = byHour.keys.first;
    var best = byHour[bestHour] ?? 0;
    for (final e in byHour.entries) {
      if (e.value > best) {
        best = e.value;
        bestHour = e.key;
      }
    }
    return bestHour;
  }

  @override
  Widget build(BuildContext context) {
    final counts = _trip.stopDemandCounts;
    final items = counts.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    final maxCount = items.isEmpty ? 0 : items.first.value;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard de paraderos'),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            if (items.isEmpty)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    'Datos insuficientes para generar estadísticas.',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),
              )
            else
              ...items.map((e) {
                final stop = e.key;
                final count = e.value;
                final ratio = maxCount == 0 ? 0.0 : count / maxCount;
                final peak = _peakHour(stop);
                final peakLabel = peak < 0 ? '-' : '${peak.toString().padLeft(2, '0')}:00';
                return Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(stop, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900)),
                            ),
                            Text('$count', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900)),
                          ],
                        ),
                        const SizedBox(height: 10),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(999),
                          child: LinearProgressIndicator(
                            value: ratio,
                            minHeight: 10,
                            backgroundColor: Colors.grey.shade200,
                            valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primaryBlue),
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text('Hora pico: $peakLabel', style: Theme.of(context).textTheme.bodySmall),
                      ],
                    ),
                  ),
                );
              }),
          ],
        ),
      ),
    );
  }
}

class OwnerDocumentAlertsScreen extends StatefulWidget {
  const OwnerDocumentAlertsScreen({super.key});

  @override
  State<OwnerDocumentAlertsScreen> createState() => _OwnerDocumentAlertsScreenState();
}

class _OwnerDocumentAlertsScreenState extends State<OwnerDocumentAlertsScreen> {
  final TripSimulationService _trip = TripSimulationService.instance;

  @override
  void initState() {
    super.initState();
    _trip.addListener(_onChanged);
  }

  @override
  void dispose() {
    _trip.removeListener(_onChanged);
    super.dispose();
  }

  void _onChanged() {
    if (!mounted) return;
    setState(() {});
  }

  Future<void> _update(DocumentEntry d) async {
    final picked = await showDatePicker(
      context: context,
      firstDate: DateTime(2024, 1, 1),
      lastDate: DateTime(2030, 12, 31),
      initialDate: d.expiresAt,
    );
    if (picked == null) return;
    _trip.updateDocumentExpiry(placa: d.placa, docType: d.docType, expiresAt: picked);
    CustomSnackbar.show(
      context,
      message: 'Fecha actualizada',
      isSuccess: true,
    );
  }

  @override
  Widget build(BuildContext context) {
    final expiring = _trip.expiringDocuments(withinHours: 48);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Documentos por vencer'),
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
                        color: (expiring.isEmpty ? AppColors.success : AppColors.energeticOrange).withOpacity(0.15),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Icon(
                        expiring.isEmpty ? Icons.check_circle_rounded : Icons.warning_amber_rounded,
                        color: expiring.isEmpty ? AppColors.success : AppColors.energeticOrange,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        expiring.isEmpty ? 'Sin alertas (48h).' : 'Alertas: ${expiring.length}',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            if (expiring.isEmpty)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text('No hay documentos por vencer.', style: Theme.of(context).textTheme.bodyMedium),
                ),
              )
            else
              ...expiring.map((d) {
                final days = d.expiresAt.difference(DateTime.now()).inDays;
                return Card(
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(16),
                    leading: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: AppColors.energeticOrange.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(Icons.assignment_late_rounded, color: AppColors.energeticOrange),
                    ),
                    title: Text('${d.placa} • ${d.docType}'),
                    subtitle: Text('Vence: ${d.expiresAt.year}-${d.expiresAt.month.toString().padLeft(2, '0')}-${d.expiresAt.day.toString().padLeft(2, '0')} • ${days}d'),
                    trailing: TextButton(
                      onPressed: () => _update(d),
                      child: const Text('Actualizar'),
                    ),
                  ),
                );
              }),
          ],
        ),
      ),
    );
  }
}

class OwnerIncidentsScreen extends StatefulWidget {
  const OwnerIncidentsScreen({super.key});

  @override
  State<OwnerIncidentsScreen> createState() => _OwnerIncidentsScreenState();
}

class _OwnerIncidentsScreenState extends State<OwnerIncidentsScreen> {
  final TripSimulationService _trip = TripSimulationService.instance;

  @override
  void initState() {
    super.initState();
    _trip.addListener(_onChanged);
  }

  @override
  void dispose() {
    _trip.removeListener(_onChanged);
    super.dispose();
  }

  void _onChanged() {
    if (!mounted) return;
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final incidents = _trip.incidents.reversed.toList();
    return Scaffold(
      appBar: AppBar(
        title: const Text('Historial de incidencias'),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            if (incidents.isEmpty)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text('Sin incidencias.', style: Theme.of(context).textTheme.bodyMedium),
                ),
              )
            else
              ...incidents.map((i) {
                final time = '${i.at.hour.toString().padLeft(2, '0')}:${i.at.minute.toString().padLeft(2, '0')}';
                final count = i.count > 1 ? ' • x${i.count}' : '';
                return Card(
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
                                color: AppColors.energeticOrange.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: const Icon(Icons.report_rounded, color: AppColors.energeticOrange),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                '${i.kind}$count • ${i.placa}',
                                style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900),
                              ),
                            ),
                            Text(time, style: Theme.of(context).textTheme.bodySmall),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Text(
                          i.description.isEmpty ? 'Sin detalle' : i.description,
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                        const SizedBox(height: 10),
                        Text(
                          'Conductor: ${i.driverDni} • Pos: (${i.vehicleMeters.dx.toStringAsFixed(0)}, ${i.vehicleMeters.dy.toStringAsFixed(0)})',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                );
              }),
          ],
        ),
      ),
    );
  }
}

class OwnerRouteNewsScreen extends StatefulWidget {
  const OwnerRouteNewsScreen({super.key});

  @override
  State<OwnerRouteNewsScreen> createState() => _OwnerRouteNewsScreenState();
}

class _OwnerRouteNewsScreenState extends State<OwnerRouteNewsScreen> {
  final TripSimulationService _trip = TripSimulationService.instance;
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _bodyController = TextEditingController();
  bool _isEmergency = false;

  @override
  void dispose() {
    _titleController.dispose();
    _bodyController.dispose();
    super.dispose();
  }

  void _send() {
    final createdBy = _trip.currentSessionDni.isEmpty ? '11111111' : _trip.currentSessionDni;
    final body = _bodyController.text.trim();
    if (body.isEmpty) {
      CustomSnackbar.show(context, message: 'Escribe el contenido del aviso', isError: true);
      return;
    }
    _trip.createNews(
      createdByDni: createdBy,
      title: _titleController.text,
      body: body,
      isEmergency: _isEmergency,
    );
    _titleController.clear();
    _bodyController.clear();
    setState(() => _isEmergency = false);
    CustomSnackbar.show(context, message: 'Aviso enviado', isSuccess: true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Noticias de la ruta'),
      ),
      body: SafeArea(
        child: AnimatedBuilder(
          animation: _trip,
          builder: (context, _) {
            final items = _trip.news.toList()..sort((a, b) => b.createdAt.compareTo(a.createdAt));
            return ListView(
              padding: const EdgeInsets.all(20),
              children: [
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text('Crear aviso', style: Theme.of(context).textTheme.titleMedium),
                        const SizedBox(height: 12),
                        TextField(
                          controller: _titleController,
                          decoration: const InputDecoration(
                            labelText: 'Título',
                            prefixIcon: Icon(Icons.title_rounded),
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: _bodyController,
                          decoration: const InputDecoration(
                            labelText: 'Mensaje',
                            prefixIcon: Icon(Icons.campaign_rounded),
                          ),
                          maxLines: 3,
                        ),
                        const SizedBox(height: 12),
                        SwitchListTile(
                          value: _isEmergency,
                          onChanged: (v) => setState(() => _isEmergency = v),
                          title: const Text('Marcar como emergencia'),
                          subtitle: const Text('Ignora “No molestar” (demo)'),
                          secondary: const Icon(Icons.warning_amber_rounded),
                        ),
                        const SizedBox(height: 12),
                        CustomButton(
                          text: 'Enviar aviso',
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
                      child: Text('Sin avisos.', style: Theme.of(context).textTheme.bodyMedium),
                    ),
                  )
                else
                  ...items.take(20).map((n) {
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
                        title: Text(n.title),
                        subtitle: Text(n.body, maxLines: 2, overflow: TextOverflow.ellipsis),
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

class OwnerRatingsReviewScreen extends StatelessWidget {
  const OwnerRatingsReviewScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final trip = TripSimulationService.instance;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Revisión de calificaciones'),
      ),
      body: SafeArea(
        child: AnimatedBuilder(
          animation: trip,
          builder: (context, _) {
            final items = trip.flaggedRatings.toList()..sort((a, b) => b.at.compareTo(a.at));
            return ListView(
              padding: const EdgeInsets.all(20),
              children: [
                if (items.isEmpty)
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text('No hay calificaciones por revisar.', style: Theme.of(context).textTheme.bodyMedium),
                    ),
                  )
                else
                  ...items.map((r) {
                    return Card(
                      child: ListTile(
                        contentPadding: const EdgeInsets.all(16),
                        leading: Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(color: AppColors.warning.withOpacity(0.15), borderRadius: BorderRadius.circular(14)),
                          child: const Icon(Icons.star_half_rounded, color: AppColors.warning),
                        ),
                        title: Text('1 estrella • ${r.placa}'),
                        subtitle: Text('Chofer: ${r.driverDni} • Pasajero: ${r.passengerDni}\nSin comentario'),
                        isThreeLine: true,
                        trailing: TextButton(
                          onPressed: () {
                            trip.markFlaggedRatingReviewed(tripId: r.tripId);
                            CustomSnackbar.show(context, message: 'Marcado como revisado', isSuccess: true);
                          },
                          child: const Text('Revisado'),
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

class OwnerPunctualityReportScreen extends StatefulWidget {
  const OwnerPunctualityReportScreen({super.key});

  @override
  State<OwnerPunctualityReportScreen> createState() => _OwnerPunctualityReportScreenState();
}

class _OwnerPunctualityReportScreenState extends State<OwnerPunctualityReportScreen> {
  final TripSimulationService _trip = TripSimulationService.instance;
  DateTime _month = DateTime.now();

  Future<void> _pickMonth() async {
    final picked = await showDatePicker(
      context: context,
      firstDate: DateTime(2024, 1, 1),
      lastDate: DateTime(2030, 12, 31),
      initialDate: _month,
    );
    if (picked == null) return;
    setState(() {
      _month = DateTime(picked.year, picked.month);
    });
  }

  @override
  Widget build(BuildContext context) {
    final items = _trip.punctuality.where((p) => p.filledAt.year == _month.year && p.filledAt.month == _month.month).toList();
    final Map<String, List<int>> delaysByDriver = {};
    for (final p in items) {
      var delay = p.departedAt.difference(p.filledAt).inMinutes;
      if (p.trafficHeavy) {
        delay = max(0, delay - 5);
      }
      delaysByDriver.putIfAbsent(p.driverDni, () => []).add(delay);
    }

    final ranking = delaysByDriver.entries.map((e) {
      final avg = e.value.isEmpty ? 0.0 : e.value.reduce((a, b) => a + b) / e.value.length;
      return (driver: e.key, avg: avg, trips: e.value.length);
    }).toList()
      ..sort((a, b) => a.avg.compareTo(b.avg));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Puntualidad mensual'),
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
                  decoration: BoxDecoration(color: AppColors.primaryBlue.withOpacity(0.12), borderRadius: BorderRadius.circular(14)),
                  child: const Icon(Icons.calendar_month_rounded, color: AppColors.primaryBlue),
                ),
                title: Text('Mes: ${_month.year}-${_month.month.toString().padLeft(2, '0')}'),
                subtitle: Text('Registros: ${items.length}'),
                trailing: TextButton(
                  onPressed: _pickMonth,
                  child: const Text('Cambiar'),
                ),
              ),
            ),
            const SizedBox(height: 12),
            if (ranking.isEmpty)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text('Sin datos para el mes seleccionado.', style: Theme.of(context).textTheme.bodyMedium),
                ),
              )
            else
              ...ranking.asMap().entries.map((e) {
                final idx = e.key + 1;
                final r = e.value;
                final color = idx == 1 ? AppColors.success : AppColors.primaryBlue;
                return Card(
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(16),
                    leading: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(14)),
                      child: Center(
                        child: Text('#$idx', style: TextStyle(color: color, fontWeight: FontWeight.w900)),
                      ),
                    ),
                    title: Text('Conductor ${r.driver}'),
                    subtitle: Text('Promedio: ${r.avg.toStringAsFixed(1)} min • Viajes: ${r.trips}'),
                  ),
                );
              }),
          ],
        ),
      ),
    );
  }
}

class OwnerDriverSearchScreen extends StatefulWidget {
  const OwnerDriverSearchScreen({super.key});

  @override
  State<OwnerDriverSearchScreen> createState() => _OwnerDriverSearchScreenState();
}

class _OwnerDriverSearchScreenState extends State<OwnerDriverSearchScreen> {
  final TripSimulationService _trip = TripSimulationService.instance;
  final TextEditingController _searchController = TextEditingController();
  final List<Map<String, String>> _drivers = const [
    {"nombre": "Juan Pérez", "dni": "12345678", "vehiculo": "Toyota Hiace 2022"},
    {"nombre": "Ana Gómez", "dni": "23456789", "vehiculo": "Hyundai H1 2021"},
    {"nombre": "Luis Martínez", "dni": "34567890", "vehiculo": "Nissan NV350 2020"},
    {"nombre": "Carlos Sánchez", "dni": "45678901", "vehiculo": "Chevrolet Express 2021"},
    {"nombre": "Giancarlo (Demo)", "dni": "22222222", "vehiculo": "BJK-102"},
  ];

  List<Map<String, String>> _filtered(String query) {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return const [];
    return _drivers.where((d) {
      return (d["nombre"] ?? "").toLowerCase().contains(q) || (d["dni"] ?? "").contains(q);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final results = _filtered(_searchController.text);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Buscar conductores'),
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
                    labelText: 'Buscar por nombre o DNI',
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
                  child: Text('Ingresa un nombre o DNI para buscar', style: Theme.of(context).textTheme.bodyMedium),
                ),
              )
            else if (results.isEmpty)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text('Sin resultados', style: Theme.of(context).textTheme.bodyMedium),
                ),
              )
            else
              ...results.map((d) {
                final dni = d["dni"] ?? '';
                final blocked = _trip.blockedDriverDnis.contains(dni);
                return Card(
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(16),
                    title: Text(d["nombre"] ?? '-'),
                    subtitle: Text('DNI: $dni\nVehículo: ${d["vehiculo"]}${blocked ? '\nEstado: Suspendido' : ''}'),
                    isThreeLine: true,
                    trailing: TextButton(
                      onPressed: dni.isEmpty
                          ? null
                          : () {
                              _trip.setDriverBlocked(dni, !blocked);
                              CustomSnackbar.show(
                                context,
                                message: !blocked ? 'Conductor suspendido' : 'Conductor habilitado',
                                isSuccess: blocked,
                                isError: !blocked,
                              );
                              setState(() {});
                            },
                      child: Text(blocked ? 'Habilitar' : 'Suspender'),
                    ),
                  ),
                );
              }),
          ],
        ),
      ),
    );
  }
}

class OwnerLostAndFoundScreen extends StatefulWidget {
  const OwnerLostAndFoundScreen({super.key});

  @override
  State<OwnerLostAndFoundScreen> createState() => _OwnerLostAndFoundScreenState();
}

class _OwnerLostAndFoundScreenState extends State<OwnerLostAndFoundScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _descController = TextEditingController();
  final TextEditingController _placeController = TextEditingController();
  final TextEditingController _searchController = TextEditingController();

  final List<Map<String, String>> _items = [];

  void _add() {
    if (_nameController.text.trim().isEmpty ||
        _descController.text.trim().isEmpty ||
        _placeController.text.trim().isEmpty) {
      CustomSnackbar.show(
        context,
        message: 'Completa todos los campos',
        isError: true,
      );
      return;
    }

    setState(() {
      _items.insert(0, {
        "nombre": _nameController.text.trim(),
        "descripcion": _descController.text.trim(),
        "ubicacion": _placeController.text.trim(),
      });
      _nameController.clear();
      _descController.clear();
      _placeController.clear();
    });

    CustomSnackbar.show(
      context,
      message: 'Objeto registrado',
      isSuccess: true,
    );
  }

  List<Map<String, String>> _filtered() {
    final q = _searchController.text.trim().toLowerCase();
    if (q.isEmpty) return _items;
    return _items.where((i) {
      return (i["nombre"] ?? "").toLowerCase().contains(q) ||
          (i["descripcion"] ?? "").toLowerCase().contains(q);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final items = _filtered();
    return Scaffold(
      appBar: AppBar(
        title: const Text('Objetos perdidos'),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Text('Registrar', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 10),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    CustomTextField(
                      label: 'Nombre',
                      hint: 'Ej: Billetera',
                      controller: _nameController,
                    ),
                    const SizedBox(height: 12),
                    CustomTextField(
                      label: 'Descripción',
                      hint: 'Ej: Color negro, con cierre',
                      controller: _descController,
                    ),
                    const SizedBox(height: 12),
                    CustomTextField(
                      label: 'Ubicación',
                      hint: 'Ej: Asiento 3',
                      controller: _placeController,
                    ),
                    const SizedBox(height: 12),
                    CustomButton(
                      text: 'Registrar objeto',
                      onPressed: _add,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text('Buscar', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 10),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: TextField(
                  controller: _searchController,
                  decoration: const InputDecoration(
                    labelText: 'Buscar por nombre o descripción',
                    prefixIcon: Icon(Icons.search),
                  ),
                  onChanged: (_) => setState(() {}),
                ),
              ),
            ),
            const SizedBox(height: 12),
            if (items.isEmpty)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text('Sin registros', style: Theme.of(context).textTheme.bodyMedium),
                ),
              )
            else
              ...items.map((i) {
                return Card(
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(16),
                    title: Text(i["nombre"] ?? '-'),
                    subtitle: Text('Descripción: ${i["descripcion"]}\nUbicación: ${i["ubicacion"]}'),
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

class OwnerMaintenanceScreen extends StatefulWidget {
  const OwnerMaintenanceScreen({super.key});

  @override
  State<OwnerMaintenanceScreen> createState() => _OwnerMaintenanceScreenState();
}

class _OwnerMaintenanceScreenState extends State<OwnerMaintenanceScreen> {
  final TextEditingController _unitController = TextEditingController();
  final TextEditingController _oilController = TextEditingController();
  final TextEditingController _revisionController = TextEditingController();

  final List<Map<String, String>> _items = [];

  void _add() {
    if (_unitController.text.trim().isEmpty ||
        _oilController.text.trim().isEmpty ||
        _revisionController.text.trim().isEmpty) {
      CustomSnackbar.show(
        context,
        message: 'Completa todos los campos',
        isError: true,
      );
      return;
    }

    setState(() {
      _items.insert(0, {
        "unidad": _unitController.text.trim(),
        "cambio_aceite": _oilController.text.trim(),
        "revision": _revisionController.text.trim(),
      });
      _unitController.clear();
      _oilController.clear();
      _revisionController.clear();
    });

    CustomSnackbar.show(
      context,
      message: 'Mantenimiento registrado',
      isSuccess: true,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mantenimiento preventivo'),
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
                      label: 'Unidad/Placa',
                      hint: 'Ej: BJK-102',
                      controller: _unitController,
                    ),
                    const SizedBox(height: 12),
                    CustomTextField(
                      label: 'Próximo cambio de aceite',
                      hint: 'Ej: 2026-06-15',
                      controller: _oilController,
                    ),
                    const SizedBox(height: 12),
                    CustomTextField(
                      label: 'Próxima revisión',
                      hint: 'Ej: 2026-07-01',
                      controller: _revisionController,
                    ),
                    const SizedBox(height: 12),
                    CustomButton(
                      text: 'Registrar',
                      onPressed: _add,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text('Registros', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 10),
            if (_items.isEmpty)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text('Sin registros', style: Theme.of(context).textTheme.bodyMedium),
                ),
              )
            else
              ..._items.map((m) {
                return Card(
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(16),
                    title: Text('Unidad: ${m["unidad"]}'),
                    subtitle: Text(
                      'Cambio de aceite: ${m["cambio_aceite"]}\nRevisión: ${m["revision"]}',
                    ),
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

class OwnerWeeklyEarningsScreen extends StatelessWidget {
  const OwnerWeeklyEarningsScreen({super.key});

  Future<void> _copy(BuildContext context) async {
    const text =
        'Reporte (demo)\nSemana 1: 1000\nSemana 2: 1200\nSemana 3: 1400\nSemana 4: 1100\nSemana 5: 1600\nTotal: 5700';
    await Clipboard.setData(const ClipboardData(text: text));
    if (!context.mounted) return;
    CustomSnackbar.show(
      context,
      message: 'Reporte copiado',
      isSuccess: true,
    );
  }

  @override
  Widget build(BuildContext context) {
    final weeks = const [1000, 1200, 1400, 1100, 1600];
    final maxV = weeks.reduce((a, b) => a > b ? a : b).toDouble();
    final total = weeks.fold<int>(0, (a, b) => a + b);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Ganancias semanales'),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Tendencia (demo)', style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 12),
                    SizedBox(
                      height: 160,
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: weeks.asMap().entries.map((e) {
                          final i = e.key;
                          final v = e.value.toDouble();
                          final h = (v / maxV) * 140;
                          return Expanded(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 6),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  Container(
                                    height: h,
                                    decoration: BoxDecoration(
                                      color: AppColors.primaryBlue,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text('S${i + 1}', style: Theme.of(context).textTheme.bodySmall),
                                ],
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text('Total 5 semanas: S/ $total', style: Theme.of(context).textTheme.titleSmall),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            CustomButton(
              text: 'Descargar reporte (copiar)',
              onPressed: () => _copy(context),
            ),
          ],
        ),
      ),
    );
  }
}

class OwnerExportReportsScreen extends StatelessWidget {
  const OwnerExportReportsScreen({super.key});

  static const List<Map<String, String>> _data = [
    {"Nombre": "Juan Pérez", "Puntualidad": "A tiempo", "Viajes": "20"},
    {"Nombre": "Ana Gómez", "Puntualidad": "Retrasado", "Viajes": "15"},
    {"Nombre": "Luis Martínez", "Puntualidad": "A tiempo", "Viajes": "25"},
  ];

  String _toCsv() {
    final buffer = StringBuffer();
    buffer.writeln('Nombre,Puntualidad,Viajes');
    for (final row in _data) {
      buffer.writeln('${row["Nombre"]},${row["Puntualidad"]},${row["Viajes"]}');
    }
    return buffer.toString();
  }

  String _toTable() {
    final buffer = StringBuffer();
    buffer.writeln('REPORTE (demo)');
    buffer.writeln('Nombre | Puntualidad | Viajes');
    for (final row in _data) {
      buffer.writeln('${row["Nombre"]} | ${row["Puntualidad"]} | ${row["Viajes"]}');
    }
    return buffer.toString();
  }

  Future<void> _copy(BuildContext context, String text, String ok) async {
    await Clipboard.setData(ClipboardData(text: text));
    if (!context.mounted) return;
    CustomSnackbar.show(
      context,
      message: ok,
      isSuccess: true,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Exportar reportes'),
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
                    Text('Vista previa', style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 10),
                    ..._data.map((r) => Padding(
                          padding: const EdgeInsets.symmetric(vertical: 6),
                          child: Text('${r["Nombre"]} • ${r["Puntualidad"]} • Viajes: ${r["Viajes"]}'),
                        )),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            CustomButton(
              text: 'Exportar a PDF (copiar)',
              onPressed: () => _copy(context, _toTable(), 'Reporte (PDF demo) copiado'),
            ),
            const SizedBox(height: 12),
            CustomButton(
              text: 'Exportar a Excel (copiar CSV)',
              onPressed: () => _copy(context, _toCsv(), 'CSV copiado'),
            ),
          ],
        ),
      ),
    );
  }
}

class _NavCard extends StatelessWidget {
  const _NavCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
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
          child: Icon(icon, color: AppColors.primaryBlue),
        ),
        title: Text(title, style: Theme.of(context).textTheme.titleMedium),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
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
                  fontWeight: FontWeight.w700,
                  color: AppColors.textSecondary,
                ),
          ),
        ],
      ),
    );
  }
}

class OwnerFleetManagementScreen extends StatefulWidget {
  const OwnerFleetManagementScreen({super.key});

  @override
  State<OwnerFleetManagementScreen> createState() => _OwnerFleetManagementScreenState();
}

class _OwnerFleetManagementScreenState extends State<OwnerFleetManagementScreen> {
  final List<Map<String, dynamic>> _fleet = [
    {'placa': 'BJK-102', 'capacidad': 4, 'estado': 'Activo'},
    {'placa': 'XTR-990', 'capacidad': 15, 'estado': 'Mantenimiento'},
  ];

  void _showAddUnitBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: const _AddUnitForm(),
      ),
    ).then((result) {
      if (result != null && result is Map<String, dynamic>) {
        setState(() {
          _fleet.add(result);
        });
        CustomSnackbar.show(
          context,
          message: 'Unidad registrada',
          isSuccess: true,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestión de activos'),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(20),
        itemCount: _fleet.length,
        itemBuilder: (context, index) {
          final unit = _fleet[index];
          final status = unit['estado'] as String? ?? '-';
          final badgeColor = status == 'Activo' ? AppColors.success : AppColors.warning;

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
                child: const Icon(Icons.directions_bus_filled_rounded, color: AppColors.primaryBlue),
              ),
              title: Text(
                'Placa: ${unit['placa']}',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              subtitle: Text('Capacidad: ${unit['capacidad']} pax'),
              trailing: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: badgeColor.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  status,
                  style: TextStyle(
                    color: badgeColor,
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                ),
              ),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'owner_fleet_management_fab',
        onPressed: _showAddUnitBottomSheet,
        child: const Icon(Icons.add),
      ),
    );
  }
}

class _AddUnitForm extends StatefulWidget {
  const _AddUnitForm();

  @override
  State<_AddUnitForm> createState() => _AddUnitFormState();
}

class _AddUnitFormState extends State<_AddUnitForm> {
  final TextEditingController _placaController = TextEditingController();
  int _selectedCapacity = 4;
  final List<int> _capacities = [4, 6, 8, 15];

  void _saveUnit() {
    final placa = _placaController.text.trim().toUpperCase();
    final regex = RegExp(r'^[A-Z]{3}-\d{3}$');
    if (placa.isEmpty || !regex.hasMatch(placa)) {
      CustomSnackbar.show(
        context,
        message: 'Formato inválido. Usa ABC-123',
        isError: true,
      );
      return;
    }
    Navigator.pop(context, {
      'placa': placa,
      'capacidad': _selectedCapacity,
      'estado': 'Activo',
    });
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Añadir unidad',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 24),
          CustomTextField(
            label: 'Placa',
            hint: 'Ej: ABC-123',
            controller: _placaController,
          ),
          const SizedBox(height: 24),
          Text(
            'Capacidad (Pasajeros)',
            style: Theme.of(context).textTheme.titleSmall,
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: _capacities.map((cap) {
              final isSelected = _selectedCapacity == cap;
              return ChoiceChip(
                label: Text('$cap'),
                selected: isSelected,
                onSelected: (_) {
                  setState(() {
                    _selectedCapacity = cap;
                  });
                },
                selectedColor: AppColors.primaryBlue.withOpacity(0.12),
                backgroundColor: AppColors.white,
                labelStyle: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: isSelected ? AppColors.primaryBlue : AppColors.textPrimary,
                ),
                side: BorderSide(
                  color: isSelected ? AppColors.primaryBlue : Colors.grey.shade300,
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 24),
          CustomButton(
            text: 'Guardar',
            onPressed: _saveUnit,
          ),
        ],
      ),
    );
  }
}

class OwnerAuditScreen extends StatefulWidget {
  const OwnerAuditScreen({super.key});

  @override
  State<OwnerAuditScreen> createState() => _OwnerAuditScreenState();
}

class _OwnerAuditScreenState extends State<OwnerAuditScreen> {
  final TripSimulationService _trip = TripSimulationService.instance;
  final List<Map<String, dynamic>> _pending = [
    {'chofer': 'Juan Pérez', 'placa': 'BJK-102', 'monto': 12.0, 'metodo': 'Efectivo'},
    {'chofer': 'Carlos Ruiz', 'placa': 'XTR-990', 'monto': 15.0, 'metodo': 'Efectivo'},
  ];
  final TextEditingController _expensesController = TextEditingController(text: '0');
  final TextEditingController _justificationController = TextEditingController();
  DateTime _reportDate = DateTime.now();
  bool _corruptData = false;

  void _approve(int index) {
    final item = _pending[index];
    setState(() {
      _pending.removeAt(index);
    });
    CustomSnackbar.show(
      context,
      message: 'Pago validado (${item['chofer']})',
      isSuccess: true,
    );
  }

  void _reject(int index) {
    final item = _pending[index];
    setState(() {
      _pending.removeAt(index);
    });
    CustomSnackbar.show(
      context,
      message: 'Pago observado (${item['chofer']})',
      isError: true,
    );
  }

  double _parseExpenses() {
    final raw = _expensesController.text.trim().replaceAll(',', '.');
    return double.tryParse(raw) ?? 0;
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      firstDate: DateTime(2024, 1, 1),
      lastDate: DateTime.now(),
      initialDate: _reportDate,
    );
    if (picked == null) return;
    setState(() {
      _reportDate = picked;
    });
  }

  Future<void> _copyLiquidationReport(String text) async {
    await Clipboard.setData(ClipboardData(text: text));
    if (!mounted) return;
    CustomSnackbar.show(
      context,
      message: 'Reporte copiado',
      isSuccess: true,
    );
  }

  Future<void> _askJustification(double balance) async {
    _justificationController.clear();
    await showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Diferencia negativa'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Balance: S/ ${balance.toStringAsFixed(2)}'),
              const SizedBox(height: 12),
              TextField(
                controller: _justificationController,
                decoration: const InputDecoration(
                  labelText: 'Justificación de gasto',
                  hintText: 'Ej: Peaje, mantenimiento, imprevistos',
                ),
                maxLines: 3,
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cerrar')),
            TextButton(
              onPressed: () {
                if (_justificationController.text.trim().isEmpty) return;
                Navigator.of(context).pop();
                CustomSnackbar.show(
                  this.context,
                  message: 'Justificación registrada (demo)',
                  isSuccess: true,
                );
              },
              child: const Text('Guardar'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildComisiones() {
    if (_pending.isEmpty) {
      return ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                'No hay pagos pendientes.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
          ),
        ],
      );
    }

    return ListView(
      padding: const EdgeInsets.all(20),
      children: _pending.asMap().entries.expand((e) {
        final index = e.key;
        final item = e.value;
        return [
          if (index > 0) const SizedBox(height: 12),
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
                          color: AppColors.energeticOrange.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Icon(Icons.receipt_long_rounded, color: AppColors.energeticOrange),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${item['chofer']} • ${item['placa']}',
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Comisión: S/ ${item['monto']} • ${item['metodo']}',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () => _reject(index),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.energeticOrange,
                            foregroundColor: AppColors.white,
                            minimumSize: const Size.fromHeight(48),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text('Observar'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () => _approve(index),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primaryBlue,
                            foregroundColor: AppColors.white,
                            minimumSize: const Size.fromHeight(48),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text('Validar'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ];
      }).toList(),
    );
  }

  Widget _buildFinanzas() {
    final soldSeats = 120;
    final avgFare = 10.00;
    final sales = soldSeats * avgFare;
    final commissions = 240.00;
    final driverExpenses = _trip.expenses.fold<double>(0, (a, b) => a + b.amount);
    final expenses = _parseExpenses() + driverExpenses;
    final balance = sales - commissions - expenses;
    final negative = balance < 0;

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text('Cruce de ingresos (demo)', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _InfoPill(icon: Icons.confirmation_number_rounded, text: '$soldSeats pasajes'),
                    _InfoPill(icon: Icons.payments_rounded, text: 'Ventas S/ ${sales.toStringAsFixed(2)}'),
                    _InfoPill(icon: Icons.receipt_long_rounded, text: 'Comisiones S/ ${commissions.toStringAsFixed(2)}'),
                    _InfoPill(icon: Icons.warning_amber_rounded, text: 'No-show ${_trip.releasedSeats.length}'),
                    _InfoPill(icon: Icons.local_gas_station_rounded, text: 'Gastos S/ ${driverExpenses.toStringAsFixed(2)}'),
                  ],
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _expensesController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Gastos reportados',
                    prefixText: 'S/ ',
                  ),
                  onChanged: (_) => setState(() {}),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: (negative ? AppColors.error : AppColors.success).withOpacity(0.12),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: (negative ? AppColors.error : AppColors.success).withOpacity(0.25)),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        negative ? Icons.error_rounded : Icons.check_circle_rounded,
                        color: negative ? AppColors.error : AppColors.success,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Saldo real: S/ ${balance.toStringAsFixed(2)}',
                          style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w900),
                        ),
                      ),
                      if (negative)
                        TextButton(
                          onPressed: () => _askJustification(balance),
                          child: const Text('Justificar'),
                        ),
                    ],
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
                Text('Control de velocidad (demo)', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _InfoPill(icon: Icons.speed_rounded, text: 'Actual ${_trip.lastSpeedKmh.toStringAsFixed(0)} km/h'),
                    _InfoPill(icon: Icons.report_rounded, text: 'Infracciones ${_trip.speedInfractions.length}'),
                    _InfoPill(icon: Icons.alt_route_rounded, text: 'Desvíos ${_trip.deviationInfractions}'),
                  ],
                ),
                const SizedBox(height: 12),
                if (_trip.speedInfractions.isEmpty)
                  Text('Sin infracciones registradas.', style: Theme.of(context).textTheme.bodyMedium)
                else
                  Text(
                    'Última: ${_trip.speedInfractions.last.kmh.toStringAsFixed(0)} km/h',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLiquidacion() {
    final dateText = '${_reportDate.year}-${_reportDate.month.toString().padLeft(2, '0')}-${_reportDate.day.toString().padLeft(2, '0')}';
    final soldSeats = 120;
    final sales = 1200.00;
    final commissions = 240.00;
    final driverExpenses = _trip.expenses.fold<double>(0, (a, b) => a + b.amount);
    final expenses = _parseExpenses() + driverExpenses;
    final balance = sales - commissions - expenses;

    final report = StringBuffer()
      ..writeln('LIQUIDACIÓN DIARIA (demo)')
      ..writeln('Fecha: $dateText')
      ..writeln('Pasajes vendidos: $soldSeats')
      ..writeln('Ventas: S/ ${sales.toStringAsFixed(2)}')
      ..writeln('Comisiones: S/ ${commissions.toStringAsFixed(2)}')
      ..writeln('Gastos: S/ ${expenses.toStringAsFixed(2)}')
      ..writeln('Utilidad neta: S/ ${balance.toStringAsFixed(2)}');

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text('Reporte de liquidación diaria', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(child: Text('Fecha: $dateText', style: Theme.of(context).textTheme.bodyMedium)),
                    TextButton(
                      onPressed: _pickDate,
                      child: const Text('Cambiar'),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                if (_corruptData)
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.warning.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.warning.withOpacity(0.25)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.warning_amber_rounded, color: AppColors.warning),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Datos corruptos detectados (demo). Recalcula desde pasarela.',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ),
                        TextButton(
                          onPressed: () {
                            setState(() => _corruptData = false);
                            CustomSnackbar.show(
                              context,
                              message: 'Recalculado (demo)',
                              isSuccess: true,
                            );
                          },
                          child: const Text('Recalcular'),
                        ),
                      ],
                    ),
                  )
                else
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.primaryBlue.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.primaryBlue.withOpacity(0.2)),
                    ),
                    child: Text(
                      report.toString(),
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ),
                const SizedBox(height: 12),
                CustomButton(
                  text: 'Exportar (copiar)',
                  onPressed: () => _copyLiquidationReport(report.toString()),
                ),
                const SizedBox(height: 12),
                ElevatedButton(
                  onPressed: () => setState(() => _corruptData = true),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.energeticOrange,
                    foregroundColor: AppColors.white,
                    minimumSize: const Size.fromHeight(50),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text('Simular datos corruptos'),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Auditoría'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Comisiones'),
              Tab(text: 'Finanzas'),
              Tab(text: 'Liquidación'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildComisiones(),
            _buildFinanzas(),
            _buildLiquidacion(),
          ],
        ),
      ),
    );
  }
}
