// services/async_http_service.dart
import 'package:http/http.dart' as http;
import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import '../global.dart';

class AsyncHttpService {
  static String get token => GlobalVar().userToken;

  static Map<String, String> get headers {
    return {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
    };
  }

  // ✅ VARIABLES PARA CONTROLAR EL OVERLAY
  static OverlayEntry? _progressOverlay;
  static Timer? _messageTimer;
  static int _messageStep = 0;
  static List<String> _loadingMessages = [
    'Conectando con el servidor...',
    'Procesando solicitud...',
    'Validando datos...',
    'Finalizando operación...',
  ];

  // ✅ MÉTODO PRINCIPAL
  static void consumeAndDo<T>({
    required BuildContext context,
    required Future<http.Response> asyncRequest,
    required Function(T) onSuccess,
    required Function(String) onError,
    required Function(double) onProgress,
  }) {
    // Mostrar overlay inmediatamente
    _showProgressOverlay(context, 'Iniciando operación...');

    // Iniciar progreso
    onProgress(0.0);

    // Ejecutar en segundo plano
    unawaited(
      _executeAsync(
        context: context,
        asyncRequest: asyncRequest,
        onSuccess: onSuccess,
        onError: onError,
        onProgress: onProgress,
      ),
    );
  }

  // ✅ EJECUCIÓN ASÍNCRONA
  static Future<void> _executeAsync<T>({
    required BuildContext context,
    required Future<http.Response> asyncRequest,
    required Function(T) onSuccess,
    required Function(String) onError,
    required Function(double) onProgress,
  }) async {
    try {
      // ✅ INICIAR TIMER PARA CAMBIAR MENSAJES
      _startMessageRotation(context);

      // ✅ SIMULAR PROGRESO INICIAL
      onProgress(-1.0);

      // Realizar la petición HTTP
      final response = await asyncRequest;

      // ✅ DETENER TIMER DE MENSAJES
      _stopMessageRotation();

      // ✅ VERIFICAR RESPUESTA
      if (response.statusCode >= 200 && response.statusCode < 300) {
        // ÉXITO
        onProgress(1.0);
        _updateProgressOverlay(context, '✅ Operación completada!');

        // Breve delay para mostrar mensaje de éxito
        await Future.delayed(const Duration(milliseconds: 800));

        // Parsear respuesta
        final T result = _parseResponse<T>(response);

        // Ocultar overlay
        _hideProgressOverlay();

        // Llamar callback de éxito
        onSuccess(result);
      } else {
        // ERROR DEL SERVIDOR
        _hideProgressOverlay();
        onProgress(0.0);
        onError('Error ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      // ERROR DE CONEXIÓN
      _stopMessageRotation();
      _hideProgressOverlay();
      onProgress(0.0);
      onError('Error de conexión: $e');
    }
  }

  // ✅ MOSTRAR OVERLAY DE PROGRESO
  static void _showProgressOverlay(BuildContext context, String message) {
    // Ocultar overlay anterior si existe
    _hideProgressOverlay();

    // Crear nuevo overlay
    _progressOverlay = OverlayEntry(
      builder: (context) => Positioned(
        top: MediaQuery.of(context).padding.top + 10,
        left: 20,
        right: 20,
        child: Material(
          color: Colors.transparent,
          child: _ProgressOverlayContent(message: message),
        ),
      ),
    );

    // Insertar en el overlay
    Overlay.of(context).insert(_progressOverlay!);
  }

  // ✅ ACTUALIZAR OVERLAY
  static void _updateProgressOverlay(BuildContext context, String message) {
    // Actualizar el overlay existente
    if (_progressOverlay != null && _progressOverlay!.mounted) {
      _progressOverlay!.markNeedsBuild();

      // También podríamos recrearlo para cambiar el mensaje
      // _hideProgressOverlay();
      // _showProgressOverlay(context, message);
    }
  }

  // ✅ OCULTAR OVERLAY
  static void _hideProgressOverlay() {
    _progressOverlay?.remove();
    _progressOverlay = null;
  }

  // ✅ INICIAR ROTACIÓN DE MENSAJES
  static void _startMessageRotation(BuildContext context) {
    _messageStep = 0;

    _messageTimer = Timer.periodic(const Duration(seconds: 2), (timer) {
      if (_progressOverlay != null && _progressOverlay!.mounted) {
        _messageStep = (_messageStep + 1) % _loadingMessages.length;
        _progressOverlay!.markNeedsBuild();
      }
    });
  }

  // ✅ DETENER ROTACIÓN DE MENSAJES
  static void _stopMessageRotation() {
    _messageTimer?.cancel();
    _messageTimer = null;
  }

  // ✅ PARSEAR RESPUESTA JSON
  static T _parseResponse<T>(http.Response response) {
    try {
      final dynamic jsonData = json.decode(response.body);

      if (T == String) {
        return response.body as T;
      } else if (T == Map<String, dynamic>) {
        return jsonData as T;
      } else if (T == List<dynamic>) {
        return jsonData as T;
      }

      return jsonData as T;
    } catch (e) {
      // Si hay error parsing, devolver la respuesta como string
      if (T == String) {
        return response.body as T;
      }
      throw Exception('Error parsing response: $e');
    }
  }
}

// ✅ WIDGET DEL OVERLAY DE PROGRESO
class _ProgressOverlayContent extends StatefulWidget {
  final String message;

  const _ProgressOverlayContent({required this.message});

  @override
  State<_ProgressOverlayContent> createState() =>
      _ProgressOverlayContentState();
}

class _ProgressOverlayContentState extends State<_ProgressOverlayContent>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();

    // Controlador para animación del spinner
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    )..repeat();

    // Animación para el spinner
    _animation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.linear));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Obtener mensaje actual (rotatorio si está activo)
    final currentMessage = AsyncHttpService._messageTimer != null
        ? AsyncHttpService._loadingMessages[AsyncHttpService._messageStep %
              AsyncHttpService._loadingMessages.length]
        : widget.message;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue.shade800,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
        border: Border.all(color: Colors.blue.shade600, width: 1),
      ),
      child: Row(
        children: [
          // SPINNER ANIMADO
          Container(
            width: 40,
            height: 40,
            padding: const EdgeInsets.all(8),
            child: RotationTransition(
              turns: _animation,
              child: const Icon(Icons.autorenew, color: Colors.white, size: 24),
            ),
          ),

          const SizedBox(width: 16),

          // TEXTO Y BARRA DE PROGRESO
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // TÍTULO
                const Text(
                  'Procesando',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 4),

                // MENSAJE ACTUAL
                Text(
                  currentMessage,
                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),

                const SizedBox(height: 8),

                // BARRA DE PROGRESO ANIMADA
                Container(
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(2),
                  ),
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      return AnimatedBuilder(
                        animation: _controller,
                        builder: (context, child) {
                          // Calcular posición de la barra animada
                          final progress = _controller.value;
                          final barWidth = constraints.maxWidth * 0.4;
                          final position =
                              progress * (constraints.maxWidth + barWidth) -
                              barWidth;

                          return Stack(
                            children: [
                              // FONDO
                              Container(
                                width: constraints.maxWidth,
                                height: 4,
                                color: Colors.transparent,
                              ),

                              // BARRA ANIMADA
                              Positioned(
                                left: position,
                                child: Container(
                                  width: barWidth,
                                  height: 4,
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [
                                        Colors.white.withOpacity(0.6),
                                        Colors.white,
                                        Colors.white.withOpacity(0.6),
                                      ],
                                    ),
                                    borderRadius: BorderRadius.circular(2),
                                  ),
                                ),
                              ),
                            ],
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),

          // BOTÓN PARA CANCELAR (OPCIONAL)
          if (AsyncHttpService._messageTimer != null)
            IconButton(
              icon: const Icon(Icons.close, color: Colors.white70, size: 18),
              onPressed: () {
                // Cancelar la operación
                AsyncHttpService._stopMessageRotation();
                AsyncHttpService._hideProgressOverlay();
              },
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
              tooltip: 'Cancelar',
            ),
        ],
      ),
    );
  }
}
