import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/custom_button.dart';
import '../../../shared/widgets/custom_snackbar.dart';

class PricingScreen extends StatefulWidget {
  const PricingScreen({Key? key}) : super(key: key);

  @override
  State<PricingScreen> createState() => _PricingScreenState();
}

class _PricingScreenState extends State<PricingScreen> {
  final List<Map<String, dynamic>> _routes = [
    {'route': 'Lima - Chosica', 'price': 8.50, 'isError': false},
    {'route': 'Lima - Huancayo', 'price': 40.00, 'isError': false},
    {'route': 'Chosica - Matucana', 'price': 5.00, 'isError': false},
  ];

  void _savePrices() {
    bool hasError = false;
    for (var i = 0; i < _routes.length; i++) {
      if (_routes[i]['price'] <= 0) {
        setState(() {
          _routes[i]['isError'] = true;
        });
        hasError = true;
      } else {
        setState(() {
          _routes[i]['isError'] = false;
        });
      }
    }

    if (hasError) {
      CustomSnackbar.show(
        context,
        message: 'Las tarifas no pueden ser 0. Corrija los campos en rojo.',
        isError: true,
      );
    } else {
      CustomSnackbar.show(
        context,
        message: 'Tarifario actualizado correctamente',
        isSuccess: true,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Configuración de Tarifario'),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(20),
              itemCount: _routes.length,
              itemBuilder: (context, index) {
                final route = _routes[index];
                return Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      children: [
                        Expanded(
                          flex: 2,
                          child: Text(
                            route['route'],
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                        ),
                        Expanded(
                          flex: 1,
                          child: TextField(
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            decoration: InputDecoration(
                              prefixText: 'S/ ',
                              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              // Overriding border if error
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: BorderSide(
                                  color: route['isError'] ? AppColors.error : Colors.transparent,
                                  width: route['isError'] ? 2 : 1,
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: BorderSide(
                                  color: route['isError'] ? AppColors.error : AppColors.primaryBlue,
                                  width: 2,
                                ),
                              ),
                            ),
                            controller: TextEditingController(text: route['price'].toString())
                              ..selection = TextSelection.collapsed(offset: route['price'].toString().length),
                            onChanged: (val) {
                              final price = double.tryParse(val) ?? 0;
                              _routes[index]['price'] = price;
                              if (price > 0 && route['isError']) {
                                setState(() {
                                  _routes[index]['isError'] = false;
                                });
                              }
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20.0),
            child: CustomButton(
              text: 'Guardar Tarifario',
              onPressed: _savePrices,
            ),
          ),
        ],
      ),
    );
  }
}
