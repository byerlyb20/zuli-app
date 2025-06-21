import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../view_model/smart_plug_detail_view_model.dart';
import '../../core/ui/smart_dimmer_switch.dart';

class SmartPlugDetailScreen extends StatelessWidget {
  const SmartPlugDetailScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => SmartPlugDetailViewModel(),
      child: const SmartPlugDetailView(),
    );
  }
}

class SmartPlugDetailView extends StatelessWidget {
  const SmartPlugDetailView({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final viewModel = context.watch<SmartPlugDetailViewModel>();

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(viewModel.deviceName),
            Text(
              "Description",
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.7),
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              // TODO: Navigate to settings
            },
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Spacer(),
              // Power usage indicator
              Card(
                elevation: 0,
                color: theme.colorScheme.primaryContainer.withOpacity(0.1),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      Text(
                        'Current Power Usage',
                        style: theme.textTheme.titleSmall,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${viewModel.powerUsage.toStringAsFixed(1)}W',
                        style: theme.textTheme.headlineMedium?.copyWith(
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 32),
              // Dimmer switch
              SmartDimmerSwitch(
                isOn: viewModel.isOn,
                brightness: viewModel.brightness,
                onPowerChanged: viewModel.togglePower,
                onBrightnessChanged: viewModel.updateBrightness,
                label: 'Brightness Control',
              ),
              const Spacer(),
              // Device status
              Padding(
                padding: const EdgeInsets.only(bottom: 24.0),
                child: Text(
                  viewModel.isOn ? 'Device is ON' : 'Device is OFF',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: viewModel.isOn 
                        ? theme.colorScheme.primary 
                        : theme.colorScheme.onSurface.withOpacity(0.6),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
} 