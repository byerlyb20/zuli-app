import 'package:flutter/material.dart';
import 'package:logging/logging.dart';
import 'package:provider/provider.dart';
import 'package:zuli_flutter_app/data/services/transport/flutter_blue_plus_transport.dart';
import 'domain/repositories/smart_plug_repository_impl.dart';
import 'domain/repositories/smart_plug_repository.dart';
import 'data/services/transport/ble_transport_interface.dart';
import 'ui/smart_plugs/widgets/smart_plugs_screen.dart';

void main() {
  Logger.root.level = Level.ALL;
  Logger.root.onRecord.listen((record) {
    print('${record.level.name}: ${record.time}: ${record.message}');
  });
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
          create: (_) => FlutterBluePlusTransport(),
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
