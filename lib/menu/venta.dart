// menu/venta.dart
import 'package:flutter/material.dart';
import 'package:maxi_movile/controller/api_rest.dart';
import '../global.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class VentaPage extends StatefulWidget {
  const VentaPage({super.key});

  @override
  State<VentaPage> createState() => _VentaPageState();
}

class _VentaPageState extends State<VentaPage> {
  final TextEditingController _conceptoController = TextEditingController();
  final TextEditingController _cantidadController = TextEditingController();
  String _mensaje = '';

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Registrar Venta',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.blue,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 30),

          // Campo Concepto
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

          // Campo Cantidad
          TextField(
            controller: _cantidadController,
            decoration: const InputDecoration(
              labelText: 'Cantidad (\$)',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.attach_money, color: Colors.blue),
            ),
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 20),

          // Mensaje de estado
          if (_mensaje.isNotEmpty)
            Container(
              padding: const EdgeInsets.all(12),
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                color: _mensaje.contains('éxito')
                    ? Colors.blue.shade100
                    : Colors.red.shade100,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: _mensaje.contains('éxito') ? Colors.blue : Colors.red,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    _mensaje.contains('éxito')
                        ? Icons.check_circle
                        : Icons.error,
                    color: _mensaje.contains('éxito')
                        ? Colors.blue
                        : Colors.red,
                  ),
                  const SizedBox(width: 10),
                  Expanded(child: Text(_mensaje)),
                ],
              ),
            ),

          // Botón Enviar
          ElevatedButton.icon(
            onPressed: () => _enviarVenta(context),
            icon: const Icon(Icons.send),
            label: const Text('Registrar Venta'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
          ),
          const SizedBox(height: 20),

          // Información de conexión
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Información de Conexión',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text('Servidor: ${GlobalVar().apiIp}'),
                  Text(
                    'Token: ${GlobalVar().userToken.isEmpty ? 'No disponible' : 'Disponible'}',
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ✅ MODIFICADO: Método que usa AsyncHttpService con Progress
  void _enviarVenta(BuildContext context) async {
    final concepto = _conceptoController.text.trim();
    final cantidadStr = _cantidadController.text.trim();

    if (cantidadStr.isEmpty) {
      setState(() {
        _mensaje = 'Por favor completa todos los campos';
      });
      return;
    }

    final cantidad = int.tryParse(cantidadStr);
    if (cantidad == null || cantidad <= 0) {
      setState(() {
        _mensaje = 'Ingresa una cantidad válida (número entero positivo)';
      });
      return;
    }

    // Verificar que tenemos IP y token
    if (GlobalVar().apiIp.isEmpty) {
      setState(() {
        _mensaje = 'No hay servidor configurado. Configura una IP primero.';
      });
      return;
    }

    if (GlobalVar().userToken.isEmpty) {
      setState(() {
        _mensaje = 'No hay token de sesión. Inicia sesión primero.';
      });
      return;
    }

    // Crear la petición
    final request = http.post(
      Uri.parse('${GlobalVar().apiUrl}accion/inicia_venta'),
      headers: AsyncHttpService.headers,
      body: json.encode({'concepto': concepto, 'value': cantidad}),
    );

    // ✅ USAR CONSUME_AND_DO CON PROGRESO
    AsyncHttpService.consumeAndDo<Map<String, dynamic>>(
      context: context, // ✅ Pasar contexto
      asyncRequest: request,
      onSuccess: (Map<String, dynamic> data) {
        setState(() {
          _mensaje = '✅ Venta registrada con éxito! ID: ${data['id'] ?? 'N/A'}';
        });

        // Limpiar campos
        _conceptoController.clear();
        _cantidadController.clear();

        // Mostrar detalles adicionales
        _mostrarDetallesVenta(context, data);
      },
      onError: (String error) {
        setState(() {
          _mensaje = '❌ Error: $error';
        });
      },
      onProgress: (double progress) {
        // El progreso se maneja automáticamente con snackbars
        // Puedes usar esto para animaciones personalizadas si necesitas
      },
    );
  }

  void _mostrarDetallesVenta(BuildContext context, Map<String, dynamic> data) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Venta Registrada'),
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

  @override
  void dispose() {
    _conceptoController.dispose();
    _cantidadController.dispose();
    super.dispose();
  }
}
