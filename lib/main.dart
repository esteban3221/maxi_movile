import 'package:flutter/material.dart';
// ignore: depend_on_referenced_packages
import 'package:http/http.dart' as http;
import 'package:maxi_movile/providers/progress_provider.dart';
import 'package:provider/provider.dart';
import '../controller/api_rest.dart';
import '../services/database_service.dart';

import 'global.dart';
import 'menu.dart';
import 'ip_add.dart';

void main() {
  runApp(
    MultiProvider(
      providers: [ChangeNotifierProvider(create: (_) => ProgressProvider())],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  // cargar datos iniciales
  bool _isDarkMode = false;
  final DatabaseService _databaseService = DatabaseService();
  final global = GlobalVar();

  @override
  void initState() {
    super.initState();
    _loadInitialIp();
  }

  Future<void> _loadInitialIp() async {
    final ips = await _databaseService.getAllIps();
    if (ips.isNotEmpty) {
      setState(() {
        global.apiIp = ips.last.address;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Maxicajero',
      theme: ThemeData(
        primarySwatch: Colors.teal,
        brightness: _isDarkMode ? Brightness.dark : Brightness.light,
      ),
      home: MyHomePage(
        title: 'Maxicajero',
        isDarkMode: _isDarkMode,
        onToggleDarkMode: () {
          setState(() {
            _isDarkMode = !_isDarkMode;
          });
        },
      ),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({
    super.key,
    required this.title,
    required this.isDarkMode,
    required this.onToggleDarkMode,
  });

  final String title;
  final bool isDarkMode;
  final VoidCallback onToggleDarkMode;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  bool _obscureText = true;
  String password = '';

  final TextEditingController _passwordController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        actions: [
          Switch(
            value: widget.isDarkMode,
            onChanged: (value) => widget.onToggleDarkMode(),
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: <Widget>[
            const Text(
              'Bienvenido',
              style: TextStyle(
                fontFamily: 'Poppins',
                fontWeight: FontWeight.bold,
                fontSize: 40,
              ),
            ),
            const Icon(Icons.supervised_user_circle_rounded, size: 300),
            Padding(
              padding: const EdgeInsets.fromLTRB(40, 40, 40, 20),
              child: TextField(
                onChanged: (value) => password = value,
                onSubmitted: (value) => onBtnIniciarPressed(),
                controller: _passwordController,
                obscureText: _obscureText,
                decoration: InputDecoration(
                  labelText: 'Contraseña',
                  border: const UnderlineInputBorder(),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscureText ? Icons.visibility : Icons.visibility_off,
                    ),
                    onPressed: () {
                      setState(() {
                        _obscureText = !_obscureText;
                      });
                    },
                  ),
                ),
              ),
            ),
            ElevatedButton(
              onPressed: onBtnIniciarPressed,
              child: const Text('Iniciar sesión'),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const IpPage()),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  void onBtnIniciarPressed() {
    final request = http.post(
      Uri.parse('${GlobalVar().apiUrl}sesion/login'),
      headers: {'Content-Type': 'application/x-www-form-urlencoded'},
      body: {'grant_type': 'password', 'password': password},
    );

    AsyncHttpService.consumeAndDo<Map<String, dynamic>>(
      asyncRequest: request,
      onSuccess: (data) {
        setState(() {
          GlobalVar().userToken = data['token'] ?? '';
        });
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => DrawerMenuScreen(user: data['usuario']),
          ),
        );
      },
      onError: (error) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Error al iniciar sesión: Usuario o contraseña incorrecta / Posible error de conexión',
            ),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 4),
          ),
        );
      },
      onProgress: (progress) {
        // Aquí podrías actualizar una barra de progreso si lo deseas
      },
      context: context,
    );

    password = '';
    _passwordController.clear();
  }
}
