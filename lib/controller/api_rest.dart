// services/async_http_service.dart
import 'package:http/http.dart' as http;
import 'dart:async';
import 'dart:convert';
import '../global.dart';

class AsyncHttpService {
  static String get token => GlobalVar().userToken;
  static Map<String, String> get headers {
    return {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
    };
  }

  // ✅ Equivalente a tu función consume_and_do
  static void consumeAndDo<T>({
    required Future<http.Response> asyncRequest,
    required Function(T) onSuccess,
    required Function(String) onError,
    required Function(double) onProgress, // Callback para progreso
  }) {
    // Iniciar el progreso
    onProgress(0.0);

    // Ejecutar en segundo plano (similar al std::thread)
    unawaited(
      _executeAsync(
        asyncRequest: asyncRequest,
        onSuccess: onSuccess,
        onError: onError,
        onProgress: onProgress,
      ),
    );
  }

  static Future<void> _executeAsync<T>({
    required Future<http.Response> asyncRequest,
    required Function(T) onSuccess,
    required Function(String) onError,
    required Function(double) onProgress,
  }) async {
    try {
      // Simular progreso mientras espera (similar al wait_for)
      final progressTimer = Timer.periodic(const Duration(milliseconds: 100), (
        timer,
      ) {
        // Actualizar progreso (pulse equivalent)
        onProgress(-1.0); // -1.0 indica "pulse" mode
      });

      final response = await asyncRequest;

      progressTimer.cancel();

      // Procesar respuesta en el hilo principal (similar a Glib::signal_idle())
      if (response.statusCode >= 200 && response.statusCode < 300) {
        // Completar progreso
        onProgress(1.0);

        // Parsear respuesta
        final T result = _parseResponse<T>(response);
        onSuccess(result);
      } else {
        onProgress(0.0);
        onError('Error ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      // Manejar errores (similar al catch std::exception)
      onProgress(0.0);
      onError('Error de conexión: $e');
    }
  }

  static T _parseResponse<T>(http.Response response) {
    final dynamic jsonData = json.decode(response.body);

    // Aquí puedes mapear a diferentes tipos según necesites
    if (T == String) {
      return response.body as T;
    } else if (T == Map<String, dynamic>) {
      return jsonData as T;
    } else if (T == List<dynamic>) {
      return jsonData as T;
    }

    return jsonData as T;
  }
}
