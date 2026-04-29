import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/services/trip_simulation_service.dart';
import '../../auth/screens/login_screen.dart';
import 'driver_flow_screens.dart';
import '../../../shared/widgets/custom_button.dart';
import '../../../shared/widgets/custom_snackbar.dart';

class DriverNavShell extends StatefulWidget {
  const DriverNavShell({super.key});

  @override
  State<DriverNavShell> createState() => _DriverNavShellState();
}

class _DriverNavShellState extends State<DriverNavShell> {
  final TripSimulationService _trip = TripSimulationService.instance;
  int _index = 0;
  bool _isFull = false;
  bool _daySettled = false;
  int _completedRoutes = 0;
  final double _commissionPerRoute = 12.00;
  int _routeSession = 0;

  void _safeSetState(VoidCallback fn) {
    if (!mounted) return;
    if (SchedulerBinding.instance.schedulerPhase == SchedulerPhase.persistentCallbacks) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        setState(fn);
      });
      return;
    }
    setState(fn);
  }

  @override
  void initState() {
    super.initState();
    _trip.addListener(_onTripChanged);
  }

  @override
  void dispose() {
    _trip.removeListener(_onTripChanged);
    super.dispose();
  }

  void _onTripChanged() {
    if (!mounted) return;
    _safeSetState(() {});
  }

  void _handleFullChanged(bool isFull) {
    _safeSetState(() {
      _isFull = isFull;
      if (!isFull) {}
    });
  }

  void _handleDaySettledChanged(bool isSettled) {
    _safeSetState(() {
      _daySettled = isSettled;
    });
  }

  void _handleRouteCompleted() {
    _safeSetState(() {
      _completedRoutes += 1;
      _daySettled = false;
      _isFull = false;
      _routeSession += 1;
      _index = 1;
    });
    _trip.cancelExpressDeparture();
    CustomSnackbar.show(
      context,
      message: 'Ruta finalizada. Se agregó al cierre del día.',
      isSuccess: true,
    );
  }

  void _selectTab(int i) {
    final canOpenRoute = _isFull || _trip.expressAuthorized;
    if (i == 2 && !canOpenRoute) {
      CustomSnackbar.show(
        context,
        message: 'Completa la unidad o autoriza salida express para ver la hoja de ruta',
        isError: true,
      );
      _safeSetState(() => _index = 1);
      return;
    }
    _safeSetState(() => _index = i);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _index,
        children: [
          DriverValidationScreen(
            onContinue: () => _selectTab(1),
          ),
          DriverMonitorCargaScreen(
            onFullChanged: _handleFullChanged,
            onGoToCommission: () => _selectTab(2),
            routeSession: _routeSession,
          ),
          DriverManifestScreen(
            unlocked: _isFull || _trip.expressAuthorized,
            onRouteCompleted: _handleRouteCompleted,
          ),
          DriverCommissionScreen(
            completedRoutes: _completedRoutes,
            commissionPerRoute: _commissionPerRoute,
            daySettled: _daySettled,
            onDaySettledChanged: _handleDaySettledChanged,
          ),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: _selectTab,
        destinations: [
          NavigationDestination(
            icon: const Icon(Icons.verified_user_rounded),
            label: AppTheme.t(es: 'Pre-check', en: 'Pre-check'),
          ),
          NavigationDestination(
            icon: const Icon(Icons.event_seat_rounded),
            label: AppTheme.t(es: 'Carga', en: 'Load'),
          ),
          NavigationDestination(
            icon: const Icon(Icons.receipt_long_rounded),
            label: AppTheme.t(es: 'Ruta', en: 'Trip'),
          ),
          NavigationDestination(
            icon: const Icon(Icons.payments_rounded),
            label: AppTheme.t(es: 'Cierre', en: 'Close'),
          ),
        ],
      ),
    );
  }
}

class DriverValidationScreen extends StatefulWidget {
  const DriverValidationScreen({super.key, this.onContinue});

  final VoidCallback? onContinue;

  @override
  State<DriverValidationScreen> createState() => _DriverValidationScreenState();
}

class _DriverValidationScreenState extends State<DriverValidationScreen> {
  bool _isBlocked = false;

  void _toggleTheme() {
    AppTheme.themeMode.value =
        AppTheme.themeMode.value == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
  }

  void _pickLanguage() {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        return SafeArea(
          child: ValueListenableBuilder<String>(
            valueListenable: AppTheme.languageCode,
            builder: (context, lang, _) {
              return ListView(
                padding: const EdgeInsets.all(20),
                shrinkWrap: true,
                children: [
                  Text('Idioma', style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 12),
                  Card(
                    child: Column(
                      children: [
                        ListTile(
                          contentPadding: const EdgeInsets.all(16),
                          leading: Icon(lang == 'es' ? Icons.radio_button_checked_rounded : Icons.radio_button_off_rounded),
                          title: const Text('Español'),
                          onTap: () {
                            AppTheme.languageCode.value = 'es';
                            Navigator.of(context).pop();
                          },
                        ),
                        const Divider(height: 1),
                        ListTile(
                          contentPadding: const EdgeInsets.all(16),
                          leading: Icon(lang == 'en' ? Icons.radio_button_checked_rounded : Icons.radio_button_off_rounded),
                          title: const Text('English'),
                          onTap: () {
                            AppTheme.languageCode.value = 'en';
                            Navigator.of(context).pop();
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
        );
      },
    );
  }

  void _openBatteryAlert() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => const DriverLowBatteryAlertScreen()),
    );
  }

  void _openCredits() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => const DriverCreditsScreen()),
    );
  }

  void _openSocialLinks() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => const DriverSocialLinksScreen()),
    );
  }

  void _logout() {
    Navigator.of(context, rootNavigator: true).pushAndRemoveUntil(
      MaterialPageRoute(builder: (context) => const LoginScreen()),
      (route) => false,
    );
  }

  void _continue() {
    if (widget.onContinue != null) {
      widget.onContinue!();
      return;
    }
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (context) => const DriverMonitorCargaScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isBlocked) {
      return _buildBlockedScreen();
    }
    return _buildAlertScreen();
  }

  Widget _buildBlockedScreen() {
    return Scaffold(
      backgroundColor: AppColors.surfaceGrey,
      appBar: AppBar(
        title: const Text('Pre-check normativo'),
        actions: [
          IconButton(
            icon: const Icon(Icons.battery_alert_rounded),
            tooltip: 'Batería baja',
            onPressed: _openBatteryAlert,
          ),
          IconButton(
            icon: const Icon(Icons.language_rounded),
            tooltip: 'Idioma',
            onPressed: _pickLanguage,
          ),
          IconButton(
            icon: const Icon(Icons.public_rounded),
            tooltip: 'Redes',
            onPressed: _openSocialLinks,
          ),
          IconButton(
            icon: const Icon(Icons.info_outline_rounded),
            tooltip: 'Créditos',
            onPressed: _openCredits,
          ),
          IconButton(
            icon: const Icon(Icons.nightlight_round),
            tooltip: 'Modo nocturno',
            onPressed: _toggleTheme,
          ),
          IconButton(
            icon: const Icon(Icons.swap_horiz),
            tooltip: 'Cambiar a modo Alerta',
            onPressed: () {
              setState(() {
                _isBlocked = false;
              });
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout_rounded),
            tooltip: 'Salir',
            onPressed: _logout,
          ),
        ],
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.error.withOpacity(0.1),
                ),
                child: const Icon(
                  Icons.lock,
                  size: 80,
                  color: AppColors.error,
                ),
              ),
              const SizedBox(height: 32),
              Text(
                'Acceso Bloqueado',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      color: AppColors.error,
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Text(
                'SOAT o Revisión Técnica vencidos.\nContacte al Dueño.',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: AppColors.textPrimary,
                    ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAlertScreen() {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pre-check normativo'),
        actions: [
          IconButton(
            icon: const Icon(Icons.battery_alert_rounded),
            tooltip: 'Batería baja',
            onPressed: _openBatteryAlert,
          ),
          IconButton(
            icon: const Icon(Icons.language_rounded),
            tooltip: 'Idioma',
            onPressed: _pickLanguage,
          ),
          IconButton(
            icon: const Icon(Icons.public_rounded),
            tooltip: 'Redes',
            onPressed: _openSocialLinks,
          ),
          IconButton(
            icon: const Icon(Icons.info_outline_rounded),
            tooltip: 'Créditos',
            onPressed: _openCredits,
          ),
          IconButton(
            icon: const Icon(Icons.nightlight_round),
            tooltip: 'Modo nocturno',
            onPressed: _toggleTheme,
          ),
          IconButton(
            icon: const Icon(Icons.swap_horiz),
            tooltip: 'Cambiar a modo Bloqueado',
            onPressed: () {
              setState(() {
                _isBlocked = true;
              });
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout_rounded),
            tooltip: 'Salir',
            onPressed: _logout,
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            color: AppColors.energeticOrange,
            child: Row(
              children: [
                const Icon(Icons.warning_amber_rounded, color: AppColors.white),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Aviso: Su SOAT vence hoy. Regularice su situación.',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppColors.white,
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
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
                            child: const Icon(Icons.check_circle_rounded, color: AppColors.primaryBlue),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Documentos válidos. Puedes iniciar la operación.',
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const Spacer(),
                  CustomButton(
                    text: 'Continuar',
                    onPressed: _continue,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class DriverCreditsScreen extends StatelessWidget {
  const DriverCreditsScreen({super.key});

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

class DriverSocialLinksScreen extends StatelessWidget {
  const DriverSocialLinksScreen({super.key});

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
