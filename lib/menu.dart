import 'package:flutter/material.dart';
import 'package:maxi_movile/global.dart';
import 'package:maxi_movile/home.dart';
import 'package:maxi_movile/menu/ingreso.dart';
import 'package:provider/provider.dart';
import 'menu/venta.dart';
import 'menu/pago.dart';
import 'menu/movimientos.dart';
import 'menu/ayuda.dart';
import 'menu/configuracion.dart';
import 'providers/progress_provider.dart';

class DrawerMenuScreen extends StatefulWidget {
  final String user;
  const DrawerMenuScreen({super.key, required this.user});

  @override
  State<DrawerMenuScreen> createState() => _DrawerMenuScreenState();
}

class _DrawerMenuScreenState extends State<DrawerMenuScreen> {
  late String _currentPage = widget.user;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('MaxiCajero - $_currentPage'),
        // ✅ Acción para probar el progreso
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              final progressProvider = Provider.of<ProgressProvider>(
                context,
                listen: false,
              );
              progressProvider.pulse(message: 'Actualizando...');

              // Ocultar después de 2 segundos (solo para prueba)
              Future.delayed(const Duration(seconds: 2), () {
                progressProvider.hide();
              });
            },
          ),
        ],
      ),
      drawer: _buildDrawer(),
      body: Stack(
        children: [
          // ✅ CONTENIDO PRINCIPAL
          _buildContent(),

          // ✅ PROGRESS INDICATOR GLOBAL (arriba de todo)
          _buildGlobalProgressIndicator(),
        ],
      ),
    );
  }

  // ✅ WIDGET DEL PROGRESS INDICATOR GLOBAL
  Widget _buildGlobalProgressIndicator() {
    return Consumer<ProgressProvider>(
      builder: (context, progressProvider, child) {
        if (!progressProvider.isVisible) return const SizedBox.shrink();

        return Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: Column(
            children: [
              // Barra de progreso
              SizedBox(
                height: 4,
                child: LinearProgressIndicator(
                  value: progressProvider.progress < 0
                      ? null
                      : progressProvider.progress,
                  backgroundColor: Colors.grey[300],
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
                  minHeight: 4,
                ),
              ),

              // Mensaje opcional
              if (progressProvider.message.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  color: Colors.blue.shade50,
                  child: Row(
                    children: [
                      const Icon(
                        Icons.info_outline,
                        size: 16,
                        color: Colors.blue,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          progressProvider.message,
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.blue,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Drawer _buildDrawer() {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const CircleAvatar(
                  radius: 30,
                  backgroundColor: Colors.white,
                  child: Icon(Icons.person, size: 40, color: Colors.blue),
                ),
                const SizedBox(height: 10),
                Text(
                  widget.user,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),

          _buildDrawerItem(
            icon: Icons.point_of_sale,
            title: 'Venta',
            onTap: () => _selectPage('Venta'),
          ),
          _buildDrawerItem(
            icon: Icons.input,
            title: 'Ingreso',
            onTap: () => _selectPage('Ingreso'),
          ),
          _buildDrawerItem(
            icon: Icons.payment,
            title: 'Pago',
            onTap: () => _selectPage('Pago'),
          ),
          _buildDrawerItem(
            icon: Icons.list_alt,
            title: 'Movimientos',
            onTap: () => _selectPage('Movimientos'),
          ),

          const Divider(),

          _buildDrawerItem(
            icon: Icons.settings,
            title: 'Configuración',
            onTap: () => _selectPage('Configuración'),
          ),
          _buildDrawerItem(
            icon: Icons.help,
            title: 'Ayuda',
            onTap: () => _selectPage('Ayuda'),
          ),
          _buildDrawerItem(
            icon: Icons.exit_to_app,
            title: 'Cerrar Sesión',
            onTap: () {
              GlobalVar().userToken = '';
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(
                  builder: (context) => const MyHomePage(title: 'Maxicajero'),
                ),
                (route) => false,
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildDrawerItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon),
      title: Text(title),
      onTap: onTap,
      selected: _currentPage == title,
      selectedTileColor: Colors.blue[50],
    );
  }

  Widget _buildContent() {
    switch (_currentPage) {
      case 'Venta':
        return VentaPage();
      case 'Ingreso':
        return IngresoPage();
      case 'Pago':
        return PagosPageCompact();
      case 'Movimientos':
        return MovimientosScreen();
      case 'Ayuda':
        return HelpScreen();
      case 'Configuración':
        return SettingsScreen();
      default:
        return defaultPage();
    }
  }

  Center defaultPage() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.menu_outlined, size: 50, color: Colors.grey),
          SizedBox(height: 10),
          Text(
            'Bienvenido ${widget.user} \nEscoga una opción del menú',
            style: TextStyle(fontSize: 18, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  void _selectPage(String page) {
    setState(() {
      _currentPage = page;
    });
    Navigator.pop(context);
  }
}
