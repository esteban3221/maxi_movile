import 'package:flutter/foundation.dart';

class ProgressProvider with ChangeNotifier {
  // ✅ Estados del progreso
  double _progress = 0.0;
  bool _isVisible = false;
  String _message = '';

  // ✅ Getters
  double get progress => _progress;
  bool get isVisible => _isVisible;
  String get message => _message;

  // ✅ Mostrar progreso indeterminado (sin porcentaje)
  void showIndeterminate({String message = ''}) {
    _progress = -1.0; // -1.0 = indeterminado
    _isVisible = true;
    _message = message;
    notifyListeners();
  }

  // ✅ Mostrar progreso determinado (con porcentaje)
  void showDeterminate(double progress, {String message = ''}) {
    _progress = progress.clamp(0.0, 1.0);
    _isVisible = true;
    _message = message;
    notifyListeners();
  }

  // ✅ Actualizar progreso
  void updateProgress(double progress, {String message = ''}) {
    _progress = progress.clamp(0.0, 1.0);
    if (message.isNotEmpty) _message = message;
    notifyListeners();
  }

  // ✅ Ocultar progreso
  void hide() {
    _isVisible = false;
    _message = '';
    notifyListeners();
  }

  // ✅ Pulse (animación de carga)
  void pulse({String message = ''}) {
    _progress = -1.0;
    _isVisible = true;
    _message = message;
    notifyListeners();
  }
}
