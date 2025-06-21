import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../view_model/smart_plugs_view_model.dart';
import '../../core/ui/smart_plug_list_item.dart';

class SmartPlugsScreen extends StatelessWidget {
  const SmartPlugsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => SmartPlugsViewModel()..loadSmartPlugs(),
      child: const SmartPlugsView(),
    );
  }
}

class SmartPlugsView extends StatelessWidget {
  const SmartPlugsView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Smart Plugs'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              context.read<SmartPlugsViewModel>().loadSmartPlugs();
            },
          ),
        ],
      ),
      body: Consumer<SmartPlugsViewModel>(
        builder: (context, viewModel, child) {
          if (viewModel.isLoading) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (viewModel.error != null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    viewModel.error!,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: Theme.of(context).colorScheme.error,
                        ),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => viewModel.loadSmartPlugs(),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          if (viewModel.smartPlugs.isEmpty) {
            return const Center(
              child: Text('No smart plugs found'),
            );
          }

          return RefreshIndicator(
            onRefresh: () => viewModel.loadSmartPlugs(),
            child: ListView.builder(
              itemCount: viewModel.smartPlugs.length,
              itemBuilder: (context, index) {
                final smartPlug = viewModel.smartPlugs[index];
                return SmartPlugListItem(
                  smartPlug: smartPlug,
                  onPowerToggle: (newState) {
                    viewModel.togglePower(smartPlug.id, newState);
                  },
                  onTap: () {
                    Navigator.pushNamed(context, '/smart-plug-detail');
                  },
                );
              },
            ),
          );
        },
      ),
    );
  }
} 