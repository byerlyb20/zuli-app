import 'package:flutter/material.dart';
import 'ui/smart_plugs/widgets/smart_plugs_screen.dart';
import 'ui/smart_plug/widgets/smart_plug_detail_screen.dart';

void main() {
  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Zuli Smart Home',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blue,
          brightness: Brightness.light,
        ),
        useMaterial3: true,
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blue,
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => const SmartPlugsScreen(),
        '/smart-plug-detail': (context) => const SmartPlugDetailScreen(),
      },
    );
  }
}
