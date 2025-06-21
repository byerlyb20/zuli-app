import 'package:flutter/foundation.dart';
import '../../../domain/models/smart_plug.dart';
import '../../../domain/repositories/smart_plug_repository.dart';

class SmartPlugsViewModel extends ChangeNotifier {
  List<SmartPlug> _smartPlugs = [];
  bool _isLoading = false;
  String? _error;

  List<SmartPlug> get smartPlugs => List.unmodifiable(_smartPlugs);
  bool get isLoading => _isLoading;
  String? get error => _error;

  final SmartPlugRepository _repository;

  SmartPlugsViewModel(this._repository);

  Future<void> loadSmartPlugs() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _smartPlugs = await _repository.getSmartPlugs();
    } catch (e) {
      _error = 'Failed to load smart plugs: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> togglePower(String plugId, bool newState) async {
    try {
      final index = _smartPlugs.indexWhere((plug) => plug.id == plugId);
      if (index == -1) return;

      await _repository.togglePower(plugId, newState);
      
      // Update the local state after successful API call
      _smartPlugs[index] = _smartPlugs[index].copyWith(isPoweredOn: newState);
      notifyListeners();
    } catch (e) {
      _error = 'Failed to toggle power: $e';
      notifyListeners();
    }
  }
} 