import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'models/ip_addres.dart';
import '../services/database_service.dart';
import 'global.dart';

class IpPage extends StatefulWidget {
  const IpPage({super.key});

  @override
  State<IpPage> createState() => _IpPageState();
}

class _IpPageState extends State<IpPage> {
  final DatabaseService _databaseService = DatabaseService();
  final TextEditingController _aliasController = TextEditingController();
  final TextEditingController _ipController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();

  List<IpAddress> _ipList = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadIps();
  }

  // ✅ CARGAR IPs DES
  Future<void> _loadIps() async {
    setState(() => _isLoading = true);
    try {
      final ips = await _databaseService.getAllIps();
      setState(() => _ipList = ips);
    } catch (e) {
      if (kDebugMode) {
        print('Error loading IPs: $e');
      }
    } finally {
      setState(() => _isLoading = false);
      GlobalVar().apiIp = _ipList.isNotEmpty ? _ipList.first.address : '';
    }
  }

  // ✅ AGREGAR IP A BD
  Future<void> _addNewIp() async {
    final ipAddress = _ipController.text.trim();

    if (ipAddress.isEmpty) {
      _showError('La IP es obligatoria');
      return;
    }

    final newIp = IpAddress(
      alias: _aliasController.text.trim(),
      address: ipAddress,
      dateAdded: DateTime.now(),
      description: _descriptionController.text.trim(),
    );

    try {
      await _databaseService.insertIp(newIp);
      await _loadIps(); // Recargar lista des
      GlobalVar().apiIp = newIp.address;

      _aliasController.clear();
      _ipController.clear();
      _descriptionController.clear();

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('IP ${newIp.address} guardada')));
    } catch (e) {
      _showError('Error al guardar: $e');
    }
  }

  // ✅ ELIMINAR IP
  Future<void> _deleteIp(int index) async {
    final ip = _ipList[index];

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar IP'),
        content: Text('¿Eliminar ${ip.address} de la base de datos?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                await _databaseService.deleteIp(ip.address);
                await _loadIps(); // Recargar lista

                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(const SnackBar(content: Text('IP eliminada ')));
              } catch (e) {
                _showError('Error al eliminar: $e');
              }
            },
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
  }

  // ✅ ELIMINAR TODAS LAS IPs
  Future<void> _deleteAllIps() async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar todas'),
        content: const Text('¿Eliminar todas las IPs de la base de datos?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                await _databaseService.deleteAllIps();
                await _loadIps();

                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Todas las IPs eliminadas')),
                );
              } catch (e) {
                _showError('Error: $e');
              }
            },
            child: const Text('Eliminar todas'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Direcciones IP'),
        actions: [
          if (_ipList.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_sweep),
              onPressed: _deleteAllIps,
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                _buildAddIpCard(),
                Expanded(
                  child: _ipList.isEmpty
                      ? _buildEmptyState()
                      : ListView.builder(
                          itemCount: _ipList.length,
                          itemBuilder: (context, index) {
                            return _buildIpListItem(_ipList[index], index);
                          },
                        ),
                ),
              ],
            ),
    );
  }

  Widget _buildIpListItem(IpAddress ip, int index) {
    final isActive = ip.address == GlobalVar().apiIp;

    return Card(
      color: isActive ? Colors.blue.shade50 : null,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: isActive ? Colors.blue : null,
          child: Text('${ip.id ?? index + 1}'),
        ),
        title: Text(ip.alias.isEmpty ? 'Sin alias' : ip.alias),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(ip.address),
            if (ip.description!.isNotEmpty)
              Text(
                ip.description?.isNotEmpty == true ? ip.description! : '',
                style: const TextStyle(fontSize: 12),
              ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isActive)
              const Padding(
                padding: EdgeInsets.only(right: 8),
                child: Icon(Icons.check_circle, color: Colors.green, size: 20),
              ),
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              onPressed: () => _deleteIp(index),
            ),
          ],
        ),
        onTap: () {
          GlobalVar().apiIp = ip.address;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('IP ${ip.address} seleccionada como activa'),
            ),
          );
          setState(() {}); // para refrescar el UI
        },
      ),
    );
  }

  Widget _buildAddIpCard() {
    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _aliasController,
              decoration: const InputDecoration(
                labelText: 'Alias (Opcional)',
                hintText: 'Ejemplo: Oficina, Casa',
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _ipController,
              decoration: const InputDecoration(
                labelText: 'IP Address *',
                hintText: 'Ejemplo: 192.168.0.123',
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: 'Descripción (Opcional)',
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () {
                    _aliasController.clear();
                    _ipController.clear();
                    _descriptionController.clear();
                  },
                  child: const Text('Limpiar'),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _addNewIp,
                  child: const Text('Guardar'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: const [
          Icon(Icons.wifi_off, size: 64, color: Colors.grey),
          SizedBox(height: 12),
          Text('No hay IPs guardadas', style: TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        // padding: const EdgeInsets.symmetric(horizontal: 8.0),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18.0),
        ),
      ),
    );
  }
}
