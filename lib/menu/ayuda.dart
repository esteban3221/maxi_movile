import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class HelpScreen extends StatelessWidget {
  const HelpScreen({super.key});

  bool get _isDesktop {
    if (kIsWeb) return false; // web no lo consideramos desktop real
    return defaultTargetPlatform == TargetPlatform.windows ||
        defaultTargetPlatform == TargetPlatform.macOS ||
        defaultTargetPlatform == TargetPlatform.linux;
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Banner de bienvenida / advertencia
          Card(
            color: Colors.amber.shade50,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.info_outline, size: 32, color: Colors.amber),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _isDesktop
                              ? '¡Estás en la versión de escritorio!'
                              : 'Estás usando la versión móvil / web',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _isDesktop
                              ? 'Tienes acceso completo a todas las funcionalidades.'
                              : 'Algunas funciones avanzadas solo están disponibles en la versión de escritorio (Windows, macOS o Linux).',
                          style: const TextStyle(fontSize: 15),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 32),

          const Text(
            'Funcionalidades disponibles solo en escritorio',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),

          _buildFeatureItem(
            icon: Icons.payment,
            title: 'Pago Manual (conteo de billetes y monedas)',
            description:
                'Requiere interacción física con el cajero y una interfaz optimizada para pantallas grandes.',
          ),

          _buildFeatureItem(
            icon: Icons.history,
            title: 'Registro de Movimientos detallado',
            description:
                'La vista completa con filtros avanzados y tabla detallada está optimizada solo para escritorio.',
          ),

          // Agrega aquí más items si hay otras funciones exclusivas
          // _buildFeatureItem(...),
          const SizedBox(height: 32),

          const Text(
            '¿Por qué algunas funciones son solo para escritorio?',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          const Text(
            '• Mejor experiencia con pantallas grandes y mouse/teclado\n'
            '• Integración con hardware de cajero (impresoras, lectores, dispensadores)\n'
            '• Seguridad y precisión en operaciones sensibles\n'
            '• Interfaz más compleja que no se adapta bien a pantallas pequeñas',
          ),

          const SizedBox(height: 40),

          Center(
            child: Text(
              'Versión ${_isDesktop ? 'Escritorio' : 'Móvil/Web'} • ${DateTime.now().year}',
              style: TextStyle(color: Colors.grey.shade600),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureItem({
    required IconData icon,
    required String title,
    required String description,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Colors.blue.shade700, size: 28),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyle(color: Colors.grey.shade700, fontSize: 15),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
