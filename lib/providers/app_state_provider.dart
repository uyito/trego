import 'package:flutter/material.dart';
import '../auth/auth_service.dart';
import '../shared/api_client.dart';

class AppStateProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();
  final ApiClient _apiClient = ApiClient.instance;
  
  // Auth state
  bool _isAuthenticated = false;
  Map<String, dynamic>? _user;
  bool _isInitializing = true;

  // App connectivity
  bool _isOnline = true;
  bool _isServerHealthy = true;

  // Error handling
  String? _lastError;
  DateTime? _lastErrorTime;

  // Getters
  bool get isAuthenticated => _isAuthenticated;
  Map<String, dynamic>? get user => _user;
  bool get isInitializing => _isInitializing;
  bool get isOnline => _isOnline;
  bool get isServerHealthy => _isServerHealthy;
  String? get lastError => _lastError;
  DateTime? get lastErrorTime => _lastErrorTime;

  AppStateProvider() {
    _initialize();
  }

  Future<void> _initialize() async {
    try {
      // Initialize auth service
      await _authService.initialize();
      
      // Load auth token
      await _apiClient.loadAuthToken();
      
      // Check server health
      await _checkServerHealth();
      
      // Listen to auth state changes
      _authService.authStateChanges.listen(_onAuthStateChanged);
      
      // Set initial auth state
      _onAuthStateChanged(_authService.currentUser);
      
    } catch (e) {
      _handleError('Failed to initialize app', e);
    } finally {
      _isInitializing = false;
      notifyListeners();
    }
  }

  void _onAuthStateChanged(user) {
    _isAuthenticated = user != null;
    _user = user != null ? {
      'uid': user.uid,
      'email': user.email,
      'displayName': user.displayName,
      'photoURL': user.photoURL,
    } : null;
    
    notifyListeners();
  }

  Future<void> _checkServerHealth() async {
    try {
      _isServerHealthy = await _apiClient.checkConnectivity();
    } catch (e) {
      _isServerHealthy = false;
      _handleError('Server connectivity issue', e);
    }
    notifyListeners();
  }

  void updateConnectivity(bool isOnline) {
    if (_isOnline != isOnline) {
      _isOnline = isOnline;
      notifyListeners();
      
      if (isOnline) {
        _checkServerHealth();
      }
    }
  }

  void _handleError(String message, dynamic error) {
    _lastError = message;
    _lastErrorTime = DateTime.now();
    
    // Log error for debugging
    debugPrint('AppStateProvider Error: $message - $error');
    
    notifyListeners();
  }

  void clearError() {
    _lastError = null;
    _lastErrorTime = null;
    notifyListeners();
  }

  Future<void> signOut() async {
    try {
      await _authService.signOut();
    } catch (e) {
      _handleError('Sign out failed', e);
    }
  }

  Future<void> refreshServerHealth() async {
    await _checkServerHealth();
  }
}