import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:maxi_movile/controller/api_rest.dart';
import 'package:http/http.dart' as http;
import 'package:maxi_movile/global.dart';

class PagoManualView extends StatefulWidget {
  const PagoManualView({super.key});

  @override
  _PagoManualViewState createState() => _PagoManualViewState();
}

class _PagoManualViewState extends State<PagoManualView> {
  final TextEditingController _conceptoController = TextEditingController();
  final List<double> _denominacionesBilletes = [20, 50, 100, 200, 500, 1000];
  final List<double> _denominacionesMonedas = [1, 2, 5, 10];
  final List<int> _cantidadesBilletes = List.filled(6, 0);
  final List<int> _cantidadesMonedas = List.filled(4, 0);

  double _montoAPagar = 0;

  @override
  void initState() {
    super.initState();
    _calcularTotales();
  }

  void _calcularTotales() {
    double total = 0;

    // Calcular total de billetes
    for (int i = 0; i < _denominacionesBilletes.length; i++) {
      total += _denominacionesBilletes[i] * _cantidadesBilletes[i];
    }

    // Calcular total de monedas
    for (int i = 0; i < _denominacionesMonedas.length; i++) {
      total += _denominacionesMonedas[i] * _cantidadesMonedas[i];
    }

    setState(() {
      _montoAPagar = total;
    });
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          // Campo de concepto
          TextField(
            controller: _conceptoController,
            decoration: const InputDecoration(
              labelText: 'Concepto',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.description, color: Colors.blue),
            ),
            maxLines: 3,
            minLines: 1,
          ),

          const SizedBox(height: 20),

          // Sección de billetes y monedas
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Billetes
              Expanded(
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Billetero',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 20),
                        ...List.generate(_denominacionesBilletes.length, (
                          index,
                        ) {
                          return _buildDenominacionRow(
                            '${_denominacionesBilletes[index].toStringAsFixed(0)}',
                            _cantidadesBilletes[index],
                            (value) {
                              setState(() {
                                _cantidadesBilletes[index] = value;
                                _calcularTotales();
                              });
                            },
                            isBillete: true,
                          );
                        }),
                      ],
                    ),
                  ),
                ),
              ),

              const SizedBox(width: 20),

              // Monedas
              Expanded(
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Monedas',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 20),
                        ...List.generate(_denominacionesMonedas.length, (
                          index,
                        ) {
                          return _buildDenominacionRow(
                            _denominacionesMonedas[index].toStringAsFixed(0),
                            _cantidadesMonedas[index],
                            (value) {
                              setState(() {
                                _cantidadesMonedas[index] = value;
                                _calcularTotales();
                              });
                            },
                            isBillete: false,
                          );
                        }),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),

          // const SizedBox(height: 30),
          const SizedBox(height: 30),

          ElevatedButton.icon(
            onPressed: () => onButtonPagarClicked(context),
            icon: const Icon(Icons.send),

            label: Text(
              'Pagar \$${_montoAPagar.toStringAsFixed(2)}',
              style: const TextStyle(fontSize: 18),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 24),
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  void onButtonPagarClicked(BuildContext context) async {
    final concepto = _conceptoController.text.trim();

    if (_montoAPagar < 1) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('El monto a pagar debe ser mayor a 0')),
      );
      return;
    }

    String data = jsonEncode({
      'concepto': concepto,
      'total': _montoAPagar,
      'bill': _cantidadesBilletes,
      'coin': _cantidadesMonedas,
    });

    final request = http.post(
      Uri.parse('${GlobalVar().apiUrl}accion/inicia_pago_manual'),
      headers: AsyncHttpService.headers,
      body: data,
    );

    AsyncHttpService.consumeAndDo<Map<String, dynamic>>(
      asyncRequest: request,
      context: context,
      onSuccess: (data) {
        _mostrarDetallesPago(context, data);
        // Limpiar campos
        setState(() {
          _conceptoController.clear();
          for (int i = 0; i < _cantidadesBilletes.length; i++) {
            _cantidadesBilletes[i] = 0;
          }
          for (int i = 0; i < _cantidadesMonedas.length; i++) {
            _cantidadesMonedas[i] = 0;
          }
          _montoAPagar = 0;
        });
      },
      onError: (error) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al registrar pago: $error')),
        );
      },
      onProgress: (double p1) {},
    );
  }

  void _mostrarDetallesPago(BuildContext context, Map<String, dynamic> data) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Pago Registrada'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Detalles de la venta:'),
            const SizedBox(height: 10),
            Text('🆔 ID: ${data['id'] ?? 'N/A'}'),
            Text('📋 Estatus: ${data['estatus'] ?? 'N/A'}'),
            Text('💰 Total: \$${data['total'] ?? 'N/A'}'),
            Text('💰 Ingreso: \$${data['ingreso'] ?? 'N/A'}'),
            Text('💰 Cambio: \$${data['cambio'] ?? 'N/A'}'),
            Text('💸 Faltante: \$${data['faltante'] ?? 'N/A'}'),
            Text('📅 Fecha: ${data['fecha'] ?? 'N/A'}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  Widget _buildDenominacionRow(
    String denominacion,
    int cantidad,
    Function(int) onChanged, {
    required bool isBillete,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: Text(
              '\$$denominacion',
              style: const TextStyle(fontSize: 18),
            ),
          ),
          SizedBox(
            width: 120,
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.remove),
                  onPressed: cantidad > 0
                      ? () => onChanged(cantidad - 1)
                      : null,
                ),
                Expanded(
                  child: Text(
                    cantidad.toString(),
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 18),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.add),
                  onPressed: () => onChanged(cantidad + 1),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
