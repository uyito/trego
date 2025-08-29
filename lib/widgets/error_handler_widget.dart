import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_state_provider.dart';

class ErrorHandlerWidget extends StatefulWidget {
  final Widget child;

  const ErrorHandlerWidget({super.key, required this.child});

  @override
  State<ErrorHandlerWidget> createState() => _ErrorHandlerWidgetState();
}

class _ErrorHandlerWidgetState extends State<ErrorHandlerWidget> {
  @override
  Widget build(BuildContext context) {
    return Consumer<AppStateProvider>(
      builder: (context, appState, _) {
        // Show error overlay if there's an error
        return Stack(
          children: [
            widget.child,
            if (appState.lastError != null) _buildErrorOverlay(appState),
            if (!appState.isOnline) _buildOfflineOverlay(),
            if (!appState.isServerHealthy && appState.isOnline) _buildServerErrorOverlay(appState),
          ],
        );
      },
    );
  }

  Widget _buildErrorOverlay(AppStateProvider appState) {
    final error = appState.lastError!;
    final errorTime = appState.lastErrorTime!;
    final isRecent = DateTime.now().difference(errorTime).inSeconds < 5;
    
    if (!isRecent) return const SizedBox.shrink();

    return Positioned(
      top: MediaQuery.of(context).viewPadding.top + 16,
      left: 16,
      right: 16,
      child: Card(
        color: Colors.red[50],
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              const Icon(Icons.error_outline, color: Colors.red),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Error',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.red,
                      ),
                    ),
                    Text(
                      error,
                      style: const TextStyle(color: Colors.red),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close, color: Colors.red),
                onPressed: () => appState.clearError(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOfflineOverlay() {
    return Positioned(
      top: MediaQuery.of(context).viewPadding.top,
      left: 0,
      right: 0,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        color: Colors.orange,
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.wifi_off, color: Colors.white, size: 16),
            SizedBox(width: 8),
            Text(
              'No internet connection',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildServerErrorOverlay(AppStateProvider appState) {
    return Positioned(
      top: MediaQuery.of(context).viewPadding.top,
      left: 0,
      right: 0,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        color: Colors.red,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.cloud_off, color: Colors.white, size: 16),
            const SizedBox(width: 8),
            const Text(
              'Server connection issues',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: () => appState.refreshServerHealth(),
              child: const Icon(Icons.refresh, color: Colors.white, size: 16),
            ),
          ],
        ),
      ),
    );
  }
}