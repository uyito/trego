import 'package:flutter/material.dart';

class LoadingProvider extends ChangeNotifier {
  final Map<String, bool> _loadingStates = {};
  
  bool isLoading(String key) => _loadingStates[key] ?? false;
  
  bool get hasAnyLoading => _loadingStates.values.any((loading) => loading);
  
  void setLoading(String key, bool loading) {
    _loadingStates[key] = loading;
    notifyListeners();
  }
  
  void startLoading(String key) => setLoading(key, true);
  void stopLoading(String key) => setLoading(key, false);
  
  void clear() {
    _loadingStates.clear();
    notifyListeners();
  }
  
  Future<T> withLoading<T>(String key, Future<T> Function() operation) async {
    try {
      startLoading(key);
      return await operation();
    } finally {
      stopLoading(key);
    }
  }
}