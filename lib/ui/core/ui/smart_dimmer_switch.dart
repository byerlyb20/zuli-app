import 'package:flutter/material.dart';

class SmartDimmerSwitch extends StatefulWidget {
  final bool isOn;
  final double brightness;
  final Function(bool) onPowerChanged;
  final Function(double) onBrightnessChanged;
  final String? label;

  const SmartDimmerSwitch({
    super.key,
    required this.isOn,
    required this.brightness,
    required this.onPowerChanged,
    required this.onBrightnessChanged,
    this.label,
  });

  @override
  State<SmartDimmerSwitch> createState() => _SmartDimmerSwitchState();
}

class _SmartDimmerSwitchState extends State<SmartDimmerSwitch> {
  late double _currentBrightness;
  late bool _isOn;

  @override
  void initState() {
    super.initState();
    _currentBrightness = widget.brightness;
    _isOn = widget.isOn;
  }

  @override
  void didUpdateWidget(SmartDimmerSwitch oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.brightness != widget.brightness) {
      _currentBrightness = widget.brightness;
    }
    if (oldWidget.isOn != widget.isOn) {
      _isOn = widget.isOn;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16.0),
        boxShadow: [
          BoxShadow(
            color: theme.shadowColor.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (widget.label != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: Text(
                widget.label!,
                style: theme.textTheme.titleMedium,
              ),
            ),
          Row(
            children: [
              Icon(
                _isOn ? Icons.lightbulb : Icons.lightbulb_outline,
                color: _isOn 
                    ? theme.colorScheme.primary 
                    : theme.colorScheme.onSurface.withOpacity(0.5),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    activeTrackColor: _isOn 
                        ? theme.colorScheme.primary 
                        : theme.colorScheme.onSurface.withOpacity(0.3),
                    inactiveTrackColor: theme.colorScheme.onSurface.withOpacity(0.1),
                    thumbColor: _isOn 
                        ? theme.colorScheme.primary 
                        : theme.colorScheme.onSurface.withOpacity(0.3),
                    overlayColor: theme.colorScheme.primary.withOpacity(0.1),
                  ),
                  child: Slider(
                    value: _currentBrightness,
                    min: 0.0,
                    max: 100.0,
                    onChanged: _isOn ? (value) {
                      setState(() {
                        _currentBrightness = value;
                      });
                      widget.onBrightnessChanged(value);
                    } : null,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Switch(
                value: _isOn,
                onChanged: (value) {
                  setState(() {
                    _isOn = value;
                  });
                  widget.onPowerChanged(value);
                },
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.only(top: 4.0),
            child: Text(
              '${_currentBrightness.round()}%',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.7),
              ),
            ),
          ),
        ],
      ),
    );
  }
} 