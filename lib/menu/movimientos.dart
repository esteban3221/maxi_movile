import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:maxi_movile/controller/api_rest.dart';
import 'package:http/http.dart' as http;
import '../global.dart';

class MLog {
  final int id;
  final String user;
  final String tipo;
  final int ingreso;
  final int cambio;
  final int total;
  final String estatus;
  final DateTime fecha;

  MLog({
    required this.id,
    required this.user,
    required this.tipo,
    required this.ingreso,
    required this.cambio,
    required this.total,
    required this.estatus,
    required this.fecha,
  });
}

class MovimientosScreen extends StatefulWidget {
  const MovimientosScreen({super.key});

  @override
  State<MovimientosScreen> createState() => _MovimientosScreenState();
}

class _MovimientosScreenState extends State<MovimientosScreen> {
  // Controles de tipo y fechas
  String _selectedTipo = "Todo";
  DateTime? _fechaInicio;
  DateTime? _fechaFin;

  // Controllers para los campos de fecha
  final TextEditingController _fechaInicioController = TextEditingController();
  final TextEditingController _fechaFinController = TextEditingController();

  // Lista de tipos disponibles
  final List<String> _tipos = [
    "Todo",
    "Venta",
    "Ingreso",
    "Pago",
    "Pago Manual",
    "Refill",
    "Transpaso",
    "Retirada de Casette",
  ];

  // Lista de movimientos
  final List<MLog> _movimientos = [];
  String _totalRegistros = "Mostrando 0 de 0 registros";

  @override
  void initState() {
    super.initState();
    // Cargar datos después de que el widget esté construido
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _cargarDatos();
    });
  }

  @override
  void dispose() {
    _fechaInicioController.dispose();
    _fechaFinController.dispose();
    super.dispose();
  }

  Future<void> _cargarDatos() async {
    // Preparar el cuerpo JSON eliminando los valores null
    final Map<String, dynamic> requestBody = {'pag': 1};

    // Solo agregar tipo si no es "Todo"
    if (_selectedTipo != "Todo") {
      requestBody['tipo'] = _selectedTipo;
    } else {
      requestBody['tipo'] = 'Todo';
    }

    // Solo agregar fechas si están seleccionadas
    if (_fechaInicio != null) {
      // Para fecha inicio, usar el inicio del día (00:00:00)
      final fechaInicioInicioDia = DateTime(
        _fechaInicio!.year,
        _fechaInicio!.month,
        _fechaInicio!.day,
      );
      requestBody['f_ini'] = fechaInicioInicioDia.toIso8601String();
    } else {
      requestBody['f_ini'] = '';
    }

    if (_fechaFin != null) {
      // Para fecha fin, usar el final del día (23:59:59)
      final fechaFinFinalDia = DateTime(
        _fechaFin!.year,
        _fechaFin!.month,
        _fechaFin!.day,
        23,
        59,
        59,
      );
      requestBody['f_fin'] = fechaFinFinalDia.toIso8601String();
    } else {
      requestBody['f_fin'] = '';
    }

    print('Enviando JSON: ${json.encode(requestBody)}'); // Para debug

    final request = http.post(
      Uri.parse('${GlobalVar().apiUrl}log/movimientos'),
      headers: AsyncHttpService.headers,
      body: json.encode(requestBody),
    );

    AsyncHttpService.consumeAndDo(
      context: context,
      asyncRequest: request,
      onSuccess: (response) {
        final resp = response as Map<String, dynamic>?;
        final logs = resp?['log'] as List<dynamic>? ?? [];
        final totalRows = resp?['total_rows'] as int? ?? 0;

        setState(() {
          _movimientos.clear();
          for (var item in logs) {
            try {
              final mapItem = item as Map<String, dynamic>;
              _movimientos.add(
                MLog(
                  id: mapItem['id'] is int
                      ? mapItem['id'] as int
                      : int.tryParse(mapItem['id'].toString()) ?? 0,
                  user: mapItem['usuario']?.toString() ?? 'Desconocido',
                  tipo: mapItem['tipo']?.toString() ?? 'Sin tipo',
                  ingreso: mapItem['ingreso'] is int
                      ? mapItem['ingreso'] as int
                      : int.tryParse(mapItem['ingreso'].toString()) ?? 0,
                  cambio: mapItem['cambio'] is int
                      ? mapItem['cambio'] as int
                      : int.tryParse(mapItem['cambio'].toString()) ?? 0,
                  total: mapItem['total'] is int
                      ? mapItem['total'] as int
                      : int.tryParse(mapItem['total'].toString()) ?? 0,
                  estatus: mapItem['estatus']?.toString() ?? 'Sin estatus',
                  fecha:
                      DateTime.tryParse(mapItem['fecha']?.toString() ?? '') ??
                      DateTime.now(),
                ),
              );
            } catch (e) {
              print('Error al procesar item: $e, item: $item');
            }
          }
          _totalRegistros =
              "Mostrando ${_movimientos.length} de $totalRows registros";
        });
      },
      onError: (error) {
        // Manejar errores aquí
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $error'), backgroundColor: Colors.red),
        );
      },
      onProgress: (progress) {
        // Manejar progreso aquí
      },
    );
  }

  Future<void> _mostrarCalendarioInicio() async {
    final DateTime? fechaSeleccionada = await showDatePicker(
      context: context,
      initialDate: _fechaInicio ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );

    if (fechaSeleccionada != null) {
      setState(() {
        _fechaInicio = fechaSeleccionada;
        _fechaInicioController.text = DateFormat(
          'yyyy-MM-dd',
        ).format(fechaSeleccionada);
      });
      _aplicarFiltro();
    }
  }

  Future<void> _mostrarCalendarioFin() async {
    // Si hay fecha inicio, usarla como firstDate
    final firstDate = _fechaInicio ?? DateTime(2000);

    final DateTime? fechaSeleccionada = await showDatePicker(
      context: context,
      initialDate: _fechaFin ?? DateTime.now(),
      firstDate: firstDate,
      lastDate: DateTime.now(),
    );

    if (fechaSeleccionada != null) {
      setState(() {
        _fechaFin = fechaSeleccionada;
        _fechaFinController.text = DateFormat(
          'yyyy-MM-dd',
        ).format(fechaSeleccionada);
      });
      _aplicarFiltro();
    }
  }

  void _aplicarFiltro() {
    _cargarDatos();
  }

  void _removerFiltros() {
    setState(() {
      _selectedTipo = "Todo";
      _fechaInicio = null;
      _fechaFin = null;
      _fechaInicioController.clear();
      _fechaFinController.clear();
    });
    _aplicarFiltro();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          // Fila de filtros
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Row(
              children: [
                // Dropdown para tipo
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _selectedTipo,
                    decoration: const InputDecoration(
                      labelText: 'Tipo de Movimiento',
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                    ),
                    items: _tipos
                        .map(
                          (tipo) =>
                              DropdownMenuItem(value: tipo, child: Text(tipo)),
                        )
                        .toList(),
                    onChanged: (value) {
                      if (value != null) {
                        setState(() {
                          _selectedTipo = value;
                        });
                        _aplicarFiltro();
                      }
                    },
                  ),
                ),

                const SizedBox(width: 12),

                // Campo de fecha inicio
                Expanded(
                  child: TextFormField(
                    controller: _fechaInicioController,
                    readOnly: true,
                    decoration: InputDecoration(
                      labelText: 'Fecha Inicio',
                      hintText: 'DD/MM/AAAA',
                      border: const OutlineInputBorder(),
                      suffixIcon: IconButton(
                        icon: const Icon(Icons.calendar_today),
                        onPressed: _mostrarCalendarioInicio,
                      ),
                    ),
                    onTap: _mostrarCalendarioInicio,
                  ),
                ),

                const SizedBox(width: 12),

                // Campo de fecha fin
                Expanded(
                  child: TextFormField(
                    controller: _fechaFinController,
                    readOnly: true,
                    decoration: InputDecoration(
                      labelText: 'Fecha Fin',
                      hintText: 'DD/MM/AAAA',
                      border: const OutlineInputBorder(),
                      suffixIcon: IconButton(
                        icon: const Icon(Icons.calendar_today),
                        onPressed: _mostrarCalendarioFin,
                      ),
                    ),
                    onTap: _mostrarCalendarioFin,
                  ),
                ),

                const SizedBox(width: 12),

                // Botón para aplicar filtro
                Tooltip(
                  message: 'Aplicar Filtro',
                  child: IconButton(
                    icon: const Icon(Icons.filter_alt, size: 32),
                    color: Theme.of(context).primaryColor,
                    onPressed: _aplicarFiltro,
                  ),
                ),

                const SizedBox(width: 8),

                // Botón para remover filtros
                Tooltip(
                  message: 'Eliminar Filtros',
                  child: IconButton(
                    icon: const Icon(Icons.delete_sweep, size: 32),
                    color: Colors.red,
                    onPressed: _removerFiltros,
                  ),
                ),
              ],
            ),
          ),

          // Tabla de movimientos
          if (_movimientos.isEmpty)
            Expanded(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.receipt_long,
                      size: 64,
                      color: Colors.grey,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No hay movimientos',
                      style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Aplica filtros para ver los movimientos',
                      style: TextStyle(fontSize: 14, color: Colors.grey[500]),
                    ),
                  ],
                ),
              ),
            )
          else
            Expanded(
              child: Column(
                children: [
                  // Tabla
                  Expanded(
                    child: SingleChildScrollView(
                      scrollDirection: Axis.vertical,
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: DataTable(
                          columnSpacing: 20,
                          horizontalMargin: 12,
                          headingRowColor: MaterialStateProperty.resolveWith(
                            (states) =>
                                Theme.of(context).primaryColor.withOpacity(0.1),
                          ),
                          columns: const [
                            DataColumn(label: Text('ID'), numeric: true),
                            DataColumn(label: Text('Usuario')),
                            DataColumn(label: Text('Tipo')),
                            DataColumn(label: Text('Ingreso'), numeric: true),
                            DataColumn(label: Text('Cambio'), numeric: true),
                            DataColumn(label: Text('Total'), numeric: true),
                            DataColumn(label: Text('Estatus')),
                            DataColumn(label: Text('Fecha')),
                          ],
                          rows: _movimientos.map((movimiento) {
                            return DataRow(
                              cells: [
                                DataCell(Text(movimiento.id.toString())),
                                DataCell(Text(movimiento.user)),
                                DataCell(
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: _getTipoColor(movimiento.tipo),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      movimiento.tipo,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                                ),
                                DataCell(
                                  Text(
                                    '\$${movimiento.ingreso}',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                DataCell(
                                  Text(
                                    '\$${movimiento.cambio}',
                                    style: TextStyle(
                                      color: movimiento.cambio > 0
                                          ? Colors.red
                                          : Colors.black,
                                    ),
                                  ),
                                ),
                                DataCell(
                                  Text(
                                    '\$${movimiento.total}',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.green,
                                    ),
                                  ),
                                ),
                                DataCell(
                                  Chip(
                                    label: Text(movimiento.estatus),
                                    backgroundColor:
                                        movimiento.estatus
                                            .toLowerCase()
                                            .contains('completado')
                                        ? Colors.green[100]
                                        : Colors.orange[100],
                                    labelStyle: TextStyle(
                                      color:
                                          movimiento.estatus
                                              .toLowerCase()
                                              .contains('completado')
                                          ? Colors.green[800]
                                          : Colors.orange[800],
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                                DataCell(
                                  Text(
                                    DateFormat(
                                      'dd/MM/yyyy HH:mm',
                                    ).format(movimiento.fecha),
                                    style: const TextStyle(fontSize: 12),
                                  ),
                                ),
                              ],
                            );
                          }).toList(),
                        ),
                      ),
                    ),
                  ),

                  // Total de registros
                  Container(
                    padding: const EdgeInsets.all(12.0),
                    decoration: BoxDecoration(
                      border: Border(
                        top: BorderSide(
                          color: Theme.of(context).dividerColor,
                          width: 1,
                        ),
                      ),
                    ),
                    alignment: Alignment.centerLeft,
                    child: Row(
                      children: [
                        const Icon(
                          Icons.info_outline,
                          size: 16,
                          color: Colors.grey,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _totalRegistros,
                          style: TextStyle(
                            color: Theme.of(context).hintColor,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  // Función para obtener color según el tipo de movimiento
  Color _getTipoColor(String tipo) {
    switch (tipo.toLowerCase()) {
      case 'venta':
        return Colors.green;
      case 'ingreso':
        return Colors.blue;
      case 'pago':
        return Colors.purple;
      case 'refill':
        return Colors.orange;
      case 'transpaso':
        return Colors.teal;
      case 'retirada de casette':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
}

// Versión alternativa con ListView.builder (más eficiente para muchos datos)
class TablaMovimientosAlternativa extends StatelessWidget {
  final List<MLog> movimientos;

  const TablaMovimientosAlternativa({super.key, required this.movimientos});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: movimientos.length,
      itemBuilder: (context, index) {
        final movimiento = movimientos[index];
        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: _getTipoColor(movimiento.tipo),
              child: Text(
                movimiento.id.toString(),
                style: const TextStyle(color: Colors.white, fontSize: 12),
              ),
            ),
            title: Text(
              movimiento.tipo,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 4),
                Text('Usuario: ${movimiento.user}'),
                const SizedBox(height: 4),
                Text(
                  'Fecha: ${DateFormat('dd/MM/yyyy HH:mm').format(movimiento.fecha)}',
                ),
              ],
            ),
            trailing: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '\$${movimiento.total}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: Colors.green,
                  ),
                ),
                Text(
                  movimiento.estatus,
                  style: TextStyle(
                    fontSize: 12,
                    color:
                        movimiento.estatus.toLowerCase().contains('completado')
                        ? Colors.green
                        : Colors.orange,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Color _getTipoColor(String tipo) {
    switch (tipo.toLowerCase()) {
      case 'venta':
        return Colors.green;
      case 'ingreso':
        return Colors.blue;
      case 'pago':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }
}
