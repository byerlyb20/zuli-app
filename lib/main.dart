import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'domain/repositories/smart_plug_repository_impl.dart';
import 'domain/repositories/smart_plug_repository.dart';
import 'data/services/transport/mock_ble_transport.dart';
import 'data/services/transport/ble_transport_interface.dart';
import 'ui/smart_plugs/widgets/smart_plugs_screen.dart';

void main() {
  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // Provide the BLE transport interface
        Provider<BleTransportInterface>(
          create: (_) => MockBleTransport(),
        ),
        // Provide the repository with transport dependency
        Provider<SmartPlugRepository>(
          create: (context) {
            final transport = context.read<BleTransportInterface>();
            return SmartPlugRepositoryImpl(transport);
          },
        ),
      ],
      child: MaterialApp(
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
        home: const SmartPlugsScreen(),
      ),
    );
  }
}
