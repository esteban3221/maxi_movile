import 'package:flutter/material.dart';
import 'package:maxi_movile/global.dart';
import 'package:maxi_movile/home.dart';
import 'package:provider/provider.dart';
import 'providers/theme_provider.dart'; // ← nuevo
import 'providers/progress_provider.dart';

void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ProgressProvider()),
        ChangeNotifierProvider(create: (_) => ThemeProvider()), // ← agregado
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  // ← Cambia a Stateless
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    return MaterialApp(
      title: 'Maxicajero',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.teal,
        brightness: themeProvider.isDarkMode
            ? Brightness.dark
            : Brightness.light,
        useMaterial3: true,
      ),
      home: const MyHomePage(title: 'Maxicajero'),
    );
  }
}
