import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../providers/theme_provider.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _notificationsEnabled = true;
  String _appVersion = 'Cargando...';

  @override
  void initState() {
    super.initState();
    _loadSettings();
    _loadAppVersion();
  }

  Future<void> _loadAppVersion() async {
    try {
      final info = await PackageInfo.fromPlatform();
      setState(() {
        _appVersion = '${info.version} (build ${info.buildNumber})';
      });
    } catch (_) {
      _appVersion = 'No disponible';
    }
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _notificationsEnabled = prefs.getBool('notifications_enabled') ?? true;
    });
  }

  Future<void> _toggleNotifications(bool value) async {
    setState(() => _notificationsEnabled = value);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('notifications_enabled', value);
    // Aquí podrías activar/desactivar notificaciones reales (FCM, etc.)
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Configuración')),
      body: ListView(
        children: [
          _buildSectionHeader('Preferencias'),

          SwitchListTile(
            secondary: const Icon(Icons.dark_mode),
            title: const Text('Modo oscuro'),
            subtitle: const Text('Cambia la apariencia de la aplicación'),
            value: themeProvider.isDarkMode,
            onChanged: themeProvider.toggleDarkMode,
          ),

          SwitchListTile(
            secondary: const Icon(Icons.notifications),
            title: const Text('Notificaciones'),
            subtitle: const Text('Activar alertas y notificaciones push'),
            value: _notificationsEnabled,
            onChanged: _toggleNotifications,
          ),

          const Divider(height: 32),

          _buildSectionHeader('Información'),

          ListTile(
            leading: const Icon(Icons.info),
            title: const Text('Versión'),
            trailing: Text(_appVersion),
          ),

          ListTile(
            leading: const Icon(Icons.phone_android),
            title: const Text('Plataforma'),
            trailing: Text(_getPlatform()),
          ),

          const SizedBox(height: 40),
        ],
      ),
    );
  }

  String _getPlatform() {
    final platform = Theme.of(context).platform;
    if (platform == TargetPlatform.android) return 'Android';
    if (platform == TargetPlatform.iOS) return 'iOS';
    if (platform == TargetPlatform.windows) return 'Windows';
    if (platform == TargetPlatform.macOS) return 'macOS';
    if (platform == TargetPlatform.linux) return 'Linux';
    return 'Web / Desconocida';
  }

  Widget _buildSectionHeader(String text) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
      child: Text(
        text.toUpperCase(),
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Theme.of(context).colorScheme.primary.withOpacity(0.7),
        ),
      ),
    );
  }
}
