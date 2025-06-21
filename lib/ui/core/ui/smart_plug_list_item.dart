import 'package:flutter/material.dart';
import '../../../domain/models/smart_plug.dart';

/// A simplified list item widget that displays a smart plug's name and power toggle
class SmartPlugListItem extends StatelessWidget {
  final SmartPlug smartPlug;
  final ValueChanged<bool>? onPowerToggle;
  final VoidCallback? onTap;

  const SmartPlugListItem({
    super.key,
    required this.smartPlug,
    this.onPowerToggle,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(smartPlug.friendlyName),
      trailing: Switch.adaptive(
        value: smartPlug.isPoweredOn,
        onChanged: onPowerToggle,
      ),
      onTap: onTap,
    );
  }
} 