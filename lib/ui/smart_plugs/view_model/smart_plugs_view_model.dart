import 'dart:collection';

import 'package:flutter/foundation.dart';
import '../../../domain/models/smart_plug.dart';
import '../../../domain/repositories/smart_plug_repository.dart';

class SmartPlugsViewModel extends ChangeNotifier {
  bool _isLoading = false;
  String? _error;

  UnmodifiableListView<SmartPlug> get smartPlugs => _repository.smartPlugs;
  bool get isLoading => _isLoading;
  String? get error => _error;

  final SmartPlugRepository _repository;

  SmartPlugsViewModel(this._repository) {
    // Listen to changes in the repository
    _repository.addListener(_onRepositoryChanged);
  }

  @override
  void dispose() {
    _repository.removeListener(_onRepositoryChanged);
    super.dispose();
  }

  void _onRepositoryChanged() {
    notifyListeners();
  }

  Future<void> discoverSmartPlugs() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _repository.discoverSmartPlugs();
    } catch (e) {
      _error = 'Failed to discover smart plugs: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> togglePower(String plugId, bool newState) async {
    try {
      _error = null;
      await _repository.setPower(plugId, newState);
      // The repository will automatically update and notify listeners
    } catch (e) {
      _error = 'Failed to toggle power: $e';
      notifyListeners();
    }
  }
} 