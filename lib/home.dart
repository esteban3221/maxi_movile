import 'package:flutter/material.dart';
import 'package:maxi_movile/controller/api_rest.dart';
import 'package:maxi_movile/global.dart';
import 'package:maxi_movile/ip_add.dart';
import 'package:maxi_movile/menu.dart';
import 'package:http/http.dart' as http;
import 'package:maxi_movile/providers/theme_provider.dart';
import 'package:provider/provider.dart';

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});
  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  bool _obscureText = true;
  final TextEditingController _passwordController = TextEditingController();

  @override
  void dispose() {
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        actions: [
          Switch(
            value: themeProvider.isDarkMode,
            onChanged: (value) => themeProvider.toggleDarkMode(value),
          ),
        ],
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final width = constraints.maxWidth;
            final isTabletOrDesktop = width > 600;

            return Center(
              child: SingleChildScrollView(
                child: Container(
                  constraints: BoxConstraints(
                    maxWidth: isTabletOrDesktop ? 500 : width * 0.9,
                  ),
                  padding: EdgeInsets.symmetric(
                    horizontal: isTabletOrDesktop ? 40 : 24,
                    vertical: 32,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Icono - más pequeño en pantallas grandes
                      Icon(
                        Icons.supervised_user_circle_rounded,
                        size: isTabletOrDesktop ? 180 : 220,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      const SizedBox(height: 32),

                      Text(
                        'Bienvenido',
                        style: Theme.of(context).textTheme.headlineMedium
                            ?.copyWith(
                              fontWeight: FontWeight.bold,
                              fontSize: isTabletOrDesktop ? 36 : 40,
                            ),
                      ),
                      const SizedBox(height: 48),

                      // Campo contraseña
                      TextField(
                        controller: _passwordController,
                        obscureText: _obscureText,
                        onSubmitted: (_) => _onBtnIniciarPressed(),
                        decoration: InputDecoration(
                          labelText: 'Contraseña',
                          prefixIcon: const Icon(Icons.lock_outline),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          filled: true,
                          fillColor: Theme.of(context)
                              .colorScheme
                              .surfaceContainerHighest
                              .withOpacity(0.4),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscureText
                                  ? Icons.visibility
                                  : Icons.visibility_off,
                            ),
                            onPressed: () {
                              setState(() => _obscureText = !_obscureText);
                            },
                          ),
                        ),
                      ),
                      const SizedBox(height: 32),

                      // Botón
                      SizedBox(
                        width: double.infinity,
                        height: 54,
                        child: ElevatedButton(
                          onPressed: _onBtnIniciarPressed,
                          style: ElevatedButton.styleFrom(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text(
                            'Iniciar sesión',
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const IpPage()),
          );
        },
        child: const Icon(Icons.settings),
      ),
    );
  }

  void _onBtnIniciarPressed() {
    final password = _passwordController.text.trim();
    if (password.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Ingresa la contraseña')));
      return;
    }

    final request = http.post(
      Uri.parse('${GlobalVar().apiUrl}sesion/login'),
      headers: {'Content-Type': 'application/x-www-form-urlencoded'},
      body: {'grant_type': 'password', 'password': password},
    );

    AsyncHttpService.consumeAndDo<Map<String, dynamic>>(
      asyncRequest: request,
      context: context,
      onSuccess: (data) {
        GlobalVar().userToken = data['token'] ?? '';
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => DrawerMenuScreen(user: data['usuario']),
          ),
        );
      },
      onError: (error) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Error al iniciar sesión: $error\n'
              '(Usuario/contraseña incorrecta o sin conexión)',
            ),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      },
      onProgress: (_) {},
    );

    _passwordController.clear();
  }
}
