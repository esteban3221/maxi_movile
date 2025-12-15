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
  static final List<String> _loadingMessages = [
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
    // Usar post-frame callback para asegurar que el árbol está construido
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _executeWithOverlay(
        context: context,
        asyncRequest: asyncRequest,
        onSuccess: onSuccess,
        onError: onError,
        onProgress: onProgress,
      );
    });
  }

  // ✅ EJECUTAR CON OVERLAY
  static void _executeWithOverlay<T>({
    required BuildContext context,
    required Future<http.Response> asyncRequest,
    required Function(T) onSuccess,
    required Function(String) onError,
    required Function(double) onProgress,
  }) {
    try {
      // Verificar que el contexto sea válido
      if (context.mounted) {
        // Mostrar overlay
        _showProgressOverlay(context, 'Iniciando operación...');
        onProgress(0.0);

        // Ejecutar la petición
        unawaited(
          _executeAsync(
            context: context,
            asyncRequest: asyncRequest,
            onSuccess: onSuccess,
            onError: onError,
            onProgress: onProgress,
          ),
        );
      } else {
        // Si el contexto no está montado, ejecutar sin overlay
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
    } catch (e) {
      // Manejar cualquier error inicial
      _hideProgressOverlay();
      onError('Error inicial: $e');
    }
  }

  // ✅ EJECUCIÓN ASÍNCRONA PRINCIPAL
  static Future<void> _executeAsync<T>({
    required BuildContext context,
    required Future<http.Response> asyncRequest,
    required Function(T) onSuccess,
    required Function(String) onError,
    required Function(double) onProgress,
  }) async {
    try {
      // ✅ INICIAR TIMER PARA CAMBIAR MENSAJES
      _startMessageRotation();

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

        // Mostrar mensaje de éxito brevemente
        if (_progressOverlay != null && _progressOverlay!.mounted) {
          _progressOverlay!.markNeedsBuild();
        }

        // Breve delay para mostrar mensaje de éxito
        await Future.delayed(const Duration(milliseconds: 800));

        // Parsear respuesta
        final T result = _parseResponse<T>(response);

        // Ocultar overlay
        _hideProgressOverlay();

        // Verificar que el widget todavía esté montado
        if (context.mounted) {
          // Llamar callback de éxito
          onSuccess(result);
        }
      } else {
        // ERROR DEL SERVIDOR
        _hideProgressOverlay();
        onProgress(0.0);

        if (context.mounted) {
          onError('Error ${response.statusCode}: ${response.body}');
        }
      }
    } catch (e) {
      // ERROR DE CONEXIÓN
      _stopMessageRotation();
      _hideProgressOverlay();
      onProgress(0.0);

      if (context.mounted) {
        onError('Error de conexión: $e');
      }
    }
  }

  // ✅ MOSTRAR OVERLAY DE PROGRESO (Versión mejorada)
  static void _showProgressOverlay(BuildContext context, String message) {
    try {
      // Ocultar overlay anterior si existe
      _hideProgressOverlay();

      // Crear nuevo overlay
      _progressOverlay = OverlayEntry(
        builder: (context) => Material(
          color: Colors.transparent,
          child: Stack(
            children: [
              // Fondo semi-transparente
              Container(color: Colors.black.withOpacity(0.4)),
              // Contenido centrado
              Center(
                child: _ProgressOverlayContent(
                  message: message,
                  onCancel: () {
                    _stopMessageRotation();
                    _hideProgressOverlay();
                  },
                ),
              ),
            ],
          ),
        ),
      );

      // Insertar el overlay cuando esté disponible
      if (Overlay.of(context, rootOverlay: true).mounted) {
        Overlay.of(context, rootOverlay: true).insert(_progressOverlay!);
      }
    } catch (e) {
      print('Error mostrando overlay: $e');
    }
  }

  // ✅ OCULTAR OVERLAY DE FORMA SEGURA
  static void _hideProgressOverlay() {
    try {
      if (_progressOverlay != null) {
        _progressOverlay!.remove();
        _progressOverlay = null;
      }
    } catch (e) {
      print('Error ocultando overlay: $e');
    }
  }

  // ✅ INICIAR ROTACIÓN DE MENSAJES
  static void _startMessageRotation() {
    _messageStep = 0;

    if (_messageTimer != null && _messageTimer!.isActive) {
      _messageTimer!.cancel();
    }

    _messageTimer = Timer.periodic(const Duration(seconds: 2), (timer) {
      _messageStep = (_messageStep + 1) % _loadingMessages.length;
      if (_progressOverlay != null && _progressOverlay!.mounted) {
        try {
          _progressOverlay!.markNeedsBuild();
        } catch (e) {
          timer.cancel();
        }
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

// ✅ WIDGET DEL OVERLAY DE PROGRESO (Versión mejorada)
class _ProgressOverlayContent extends StatefulWidget {
  final String message;
  final VoidCallback? onCancel;

  const _ProgressOverlayContent({required this.message, this.onCancel});

  @override
  State<_ProgressOverlayContent> createState() =>
      __ProgressOverlayContentState();
}

class __ProgressOverlayContentState extends State<_ProgressOverlayContent>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 1),
      vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Obtener mensaje actual
    final currentMessage = AsyncHttpService._messageTimer != null
        ? AsyncHttpService._loadingMessages[AsyncHttpService._messageStep %
              AsyncHttpService._loadingMessages.length]
        : widget.message;

    return Container(
      width: 300,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 20,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Cabecera
          Row(
            children: [
              const Icon(Icons.autorenew, color: Colors.blue, size: 24),
              const SizedBox(width: 10),
              const Text(
                'Procesando',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue,
                ),
              ),
              const Spacer(),
              if (widget.onCancel != null)
                IconButton(
                  icon: const Icon(Icons.close, size: 20),
                  onPressed: widget.onCancel,
                  padding: EdgeInsets.zero,
                  visualDensity: VisualDensity.compact,
                ),
            ],
          ),

          const SizedBox(height: 15),

          // Mensaje
          Text(
            currentMessage,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 14, color: Colors.black87),
          ),

          const SizedBox(height: 20),

          // Spinner
          RotationTransition(
            turns: Tween(begin: 0.0, end: 1.0).animate(_controller),
            child: const Icon(Icons.refresh, size: 30, color: Colors.blue),
          ),

          const SizedBox(height: 15),

          // Barra de progreso
          LinearProgressIndicator(
            backgroundColor: Colors.grey[200],
            valueColor: const AlwaysStoppedAnimation<Color>(Colors.blue),
          ),
        ],
      ),
    );
  }
}
