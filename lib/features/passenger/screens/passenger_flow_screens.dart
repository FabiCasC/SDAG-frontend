import 'dart:async';

import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/custom_button.dart';
import '../../../shared/widgets/custom_snackbar.dart';
import '../../../shared/widgets/custom_text_field.dart';

class PassengerRouteSearchScreen extends StatefulWidget {
  const PassengerRouteSearchScreen({super.key});

  @override
  State<PassengerRouteSearchScreen> createState() => _PassengerRouteSearchScreenState();
}

class _PassengerRouteSearchScreenState extends State<PassengerRouteSearchScreen> {
  final List<Map<String, dynamic>> _routes = [
    {'ruta': 'Lima - Chosica', 'destino': 'Chosica', 'salida': '06:30', 'capacidad': 15, 'estado': 'Carga'},
    {'ruta': 'Lima - Huancayo', 'destino': 'Huancayo', 'salida': '07:15', 'capacidad': 8, 'estado': 'Carga'},
    {'ruta': 'Chosica - Matucana', 'destino': 'Matucana', 'salida': '08:00', 'capacidad': 6, 'estado': 'En ruta'},
    {'ruta': 'Lima - Matucana', 'destino': 'Matucana', 'salida': '09:10', 'capacidad': 4, 'estado': 'Carga'},
    {'ruta': 'Lima - Chosica', 'destino': 'Chosica', 'salida': '10:45', 'capacidad': 6, 'estado': 'Carga'},
  ];

  String _selectedDestino = 'Todos';

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
    if (_selectedDestino == 'Todos') return inCarga.toList();
    return inCarga.where((r) => r['destino'] == _selectedDestino).toList();
  }

  void _openCabin(Map<String, dynamic> route) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => CabinMapScreen(
          ruta: route['ruta'] as String? ?? '-',
          destino: route['destino'] as String? ?? '-',
          salida: route['salida'] as String? ?? '-',
          capacidad: route['capacidad'] as int? ?? 4,
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
                            'Se muestran solo unidades en estado Carga.',
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
  });

  final String ruta;
  final String destino;
  final String salida;
  final int capacidad;

  @override
  State<CabinMapScreen> createState() => _CabinMapScreenState();
}

class _CabinMapScreenState extends State<CabinMapScreen> {
  int? _selectedSeat;
  final Set<int> _occupied = {2, 5, 9};
  Timer? _timer;
  int _secondsLeft = 0;

  @override
  void dispose() {
    _timer?.cancel();
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
          _selectedSeat = null;
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

  void _selectSeat(int seat) {
    if (_occupied.contains(seat)) return;
    setState(() {
      _selectedSeat = seat;
    });
    _startHoldTimer();
  }

  void _continueToPayment() {
    if (_selectedSeat == null) {
      CustomSnackbar.show(
        context,
        message: 'Selecciona un asiento para continuar',
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
          asiento: _selectedSeat!,
        ),
      ),
    );
  }

  ({int rows, int cols}) _gridForCapacity(int capacity) {
    if (capacity <= 4) return (rows: 2, cols: 2);
    if (capacity <= 6) return (rows: 2, cols: 3);
    if (capacity <= 8) return (rows: 2, cols: 4);
    return (rows: 3, cols: 5);
  }

  String _formatSeconds(int total) {
    final minutes = (total ~/ 60).toString().padLeft(2, '0');
    final seconds = (total % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    final grid = _gridForCapacity(widget.capacidad);
    final seats = List.generate(widget.capacidad, (i) => i + 1);

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
                        ],
                      ),
                      if (_secondsLeft > 0 && _selectedSeat != null) ...[
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
                                'Asiento $_selectedSeat reservado por ${_formatSeconds(_secondsLeft)}',
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
              Expanded(
                child: GridView.builder(
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: grid.cols,
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    childAspectRatio: 1,
                  ),
                  itemCount: seats.length,
                  itemBuilder: (context, index) {
                    final seat = seats[index];
                    final isOccupied = _occupied.contains(seat);
                    final isSelected = _selectedSeat == seat;

                    Color bg;
                    Color border;
                    Color text;

                    if (isOccupied) {
                      bg = Colors.grey.shade300;
                      border = Colors.grey.shade300;
                      text = AppColors.textSecondary;
                    } else if (isSelected) {
                      bg = AppColors.energeticOrange;
                      border = AppColors.energeticOrange;
                      text = AppColors.white;
                    } else {
                      bg = AppColors.white;
                      border = AppColors.primaryBlue;
                      text = AppColors.textPrimary;
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
                text: 'Continuar a pago',
                onPressed: _continueToPayment,
              ),
            ],
          ),
        ),
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
    required this.asiento,
  });

  final String ruta;
  final String destino;
  final String salida;
  final int asiento;

  @override
  State<PassengerPaymentScreen> createState() => _PassengerPaymentScreenState();
}

class _PassengerPaymentScreenState extends State<PassengerPaymentScreen> {
  bool _isProcessing = false;

  Future<void> _simulatePayment() async {
    setState(() {
      _isProcessing = true;
    });
    await Future.delayed(const Duration(seconds: 2));

    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (context) => PassengerTicketScreen(
          ruta: widget.ruta,
          destino: widget.destino,
          salida: widget.salida,
          asiento: widget.asiento,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
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
                          _InfoPill(icon: Icons.event_seat_outlined, text: 'Asiento ${widget.asiento}'),
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
                const Center(child: CircularProgressIndicator())
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

class PassengerTicketScreen extends StatelessWidget {
  const PassengerTicketScreen({
    super.key,
    required this.ruta,
    required this.destino,
    required this.salida,
    required this.asiento,
  });

  final String ruta;
  final String destino;
  final String salida;
  final int asiento;

  void _backToSearch(BuildContext context) {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (context) => const PassengerRouteSearchScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ticket'),
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
                          _InfoPill(icon: Icons.route_outlined, text: ruta),
                          _InfoPill(icon: Icons.place_outlined, text: destino),
                          _InfoPill(icon: Icons.schedule_outlined, text: salida),
                          _InfoPill(icon: Icons.event_seat_outlined, text: 'Asiento $asiento'),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const Spacer(),
              CustomButton(
                text: 'Volver a buscar',
                onPressed: () => _backToSearch(context),
              ),
            ],
          ),
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
