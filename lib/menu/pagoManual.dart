import 'package:flutter/material.dart';

class PagoManualView extends StatefulWidget {
  const PagoManualView({super.key});

  @override
  State<PagoManualView> createState() => _PagoManualViewState();
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
    for (int i = 0; i < _denominacionesBilletes.length; i++) {
      total += _denominacionesBilletes[i] * _cantidadesBilletes[i];
    }
    for (int i = 0; i < _denominacionesMonedas.length; i++) {
      total += _denominacionesMonedas[i] * _cantidadesMonedas[i];
    }
    setState(() => _montoAPagar = total);
  }

  @override
  Widget build(BuildContext context) {
    // Para decidir si ponemos billetes y monedas lado a lado
    final isWideScreen = MediaQuery.of(context).size.width > 600;

    return Scaffold(
      appBar: AppBar(title: const Text('Pago Manual')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Concepto
            TextField(
              controller: _conceptoController,
              decoration: InputDecoration(
                labelText: 'Concepto',
                border: const OutlineInputBorder(),
                prefixIcon: const Icon(Icons.description, color: Colors.blue),
                filled: true,
                fillColor: Colors.grey.shade50,
              ),
              maxLines: 3,
              minLines: 1,
            ),
            const SizedBox(height: 24),

            // Billetes + Monedas (lado a lado o apilados)
            if (isWideScreen)
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: _buildBilletesCard()),
                  const SizedBox(width: 20),
                  Expanded(child: _buildMonedasCard()),
                ],
              )
            else
              Column(
                children: [
                  _buildBilletesCard(),
                  const SizedBox(height: 20),
                  _buildMonedasCard(),
                ],
              ),

            const SizedBox(height: 32),

            // Botón Pagar
            ElevatedButton.icon(
              onPressed: _montoAPagar > 0
                  ? () => onButtonPagarClicked(context)
                  : null,
              icon: const Icon(Icons.send),
              label: Text(
                'Pagar  \$${_montoAPagar.toStringAsFixed(2)}',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue.shade700,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  vertical: 16,
                  horizontal: 32,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 4,
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildBilletesCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Billetero',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            ...List.generate(_denominacionesBilletes.length, (i) {
              return _buildDenominacionRow(
                _denominacionesBilletes[i].toStringAsFixed(0),
                _cantidadesBilletes[i],
                (v) => setState(() {
                  _cantidadesBilletes[i] = v;
                  _calcularTotales();
                }),
                isBillete: true,
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildMonedasCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Monedas',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            ...List.generate(_denominacionesMonedas.length, (i) {
              return _buildDenominacionRow(
                _denominacionesMonedas[i].toStringAsFixed(0),
                _cantidadesMonedas[i],
                (v) => setState(() {
                  _cantidadesMonedas[i] = v;
                  _calcularTotales();
                }),
                isBillete: false,
              );
            }),
          ],
        ),
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
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(
            child: Text(
              '\$$denominacion',
              style: TextStyle(
                fontSize: 18,
                fontWeight: isBillete ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ),
          Container(
            width: 140,
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  iconSize: 20,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  icon: const Icon(Icons.remove_circle_outline),
                  onPressed: cantidad > 0
                      ? () => onChanged(cantidad - 1)
                      : null,
                ),
                Expanded(
                  child: Text(
                    '$cantidad',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                IconButton(
                  iconSize: 20,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  icon: const Icon(Icons.add_circle_outline),
                  onPressed: () => onChanged(cantidad + 1),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void onButtonPagarClicked(BuildContext context) async {
    // ... tu lógica original de pago (sin cambios)
    final concepto = _conceptoController.text.trim();
    if (_montoAPagar < 1) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('El monto a pagar debe ser mayor a 0')),
      );
      return;
    }

    // Resto de tu código de http.post y mostrar diálogo...
    // (lo omito aquí para no alargar, pero mantenlo igual)
  }

  @override
  void dispose() {
    _conceptoController.dispose();
    super.dispose();
  }
}
