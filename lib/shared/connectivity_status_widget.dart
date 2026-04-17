import 'package:flutter/material.dart';
import 'sync_service.dart';

class ConnectivityStatusWidget extends StatefulWidget {
  final Widget child;
  final bool showOfflineBanner;

  const ConnectivityStatusWidget({
    super.key,
    required this.child,
    this.showOfflineBanner = true,
  });

  @override
  State<ConnectivityStatusWidget> createState() => _ConnectivityStatusWidgetState();
}

class _ConnectivityStatusWidgetState extends State<ConnectivityStatusWidget> {
  late SyncService _syncService;
  bool _isOnline = true;
  Map<String, dynamic>? _syncStatus;

  @override
  void initState() {
    super.initState();
    _syncService = SyncService.instance;
    _initializeServices();
    _startStatusMonitoring();
  }

  Future<void> _initializeServices() async {
    await _syncService.initialize();
    await _updateSyncStatus();
  }

  void _startStatusMonitoring() {
    // Monitor connectivity changes every 30 seconds
    Stream.periodic(const Duration(seconds: 30)).listen((_) {
      _updateSyncStatus();
    });
  }

  Future<void> _updateSyncStatus() async {
    try {
      final status = await _syncService.getSyncStatus();
      if (mounted) {
        setState(() {
          _isOnline = status['isOnline'] ?? false;
          _syncStatus = status;
        });
      }
    } catch (e) {
      debugPrint('Error updating sync status: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        widget.child,
        if (widget.showOfflineBanner && !_isOnline)
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: _buildOfflineBanner(),
          ),
        Positioned(
          top: 50,
          right: 16,
          child: _buildConnectivityIndicator(),
        ),
      ],
    );
  }

  Widget _buildOfflineBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.orange.withValues(alpha: 0.9),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: SafeArea(
        bottom: false,
        child: Row(
          children: [
            const Icon(
              Icons.wifi_off,
              color: Colors.white,
              size: 20,
            ),
            const SizedBox(width: 8),
            const Expanded(
              child: Text(
                'You\'re offline. Data will sync when connection is restored.',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            if (_syncStatus?['queuedOperations'] != null && _syncStatus!['queuedOperations'] > 0)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${_syncStatus!['queuedOperations']} queued',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: _updateSyncStatus,
              child: const Icon(
                Icons.refresh,
                color: Colors.white,
                size: 20,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildConnectivityIndicator() {
    return GestureDetector(
      onTap: _showConnectivityDetails,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: _isOnline 
              ? Colors.green.withValues(alpha: 0.8)
              : Colors.red.withValues(alpha: 0.8),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              _isOnline ? Icons.wifi : Icons.wifi_off,
              color: Colors.white,
              size: 16,
            ),
            const SizedBox(width: 4),
            Text(
              _isOnline ? 'Online' : 'Offline',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showConnectivityDetails() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => _buildConnectivityBottomSheet(),
    );
  }

  Widget _buildConnectivityBottomSheet() {
    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      maxChildSize: 0.9,
      minChildSize: 0.4,
      expand: false,
      builder: (context, scrollController) {
        return Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Icon(
                    Icons.network_check,
                    color: Theme.of(context).primaryColor,
                    size: 28,
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'Connectivity Status',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Expanded(
                child: ListView(
                  controller: scrollController,
                  children: [
                    _buildStatusCard(
                      'Connection Status',
                      _isOnline ? 'Online' : 'Offline',
                      _isOnline ? Icons.wifi : Icons.wifi_off,
                      _isOnline ? Colors.green : Colors.red,
                    ),
                    const SizedBox(height: 16),
                    _buildStatusCard(
                      'API Server',
                      _syncStatus?['connectivityStatus'] == true ? 'Reachable' : 'Unreachable',
                      _syncStatus?['connectivityStatus'] == true ? Icons.cloud_done : Icons.cloud_off,
                      _syncStatus?['connectivityStatus'] == true ? Colors.blue : Colors.orange,
                    ),
                    const SizedBox(height: 16),
                    _buildStatusCard(
                      'Queued Operations',
                      '${_syncStatus?['queuedOperations'] ?? 0} pending',
                      Icons.sync,
                      _syncStatus?['queuedOperations'] == 0 ? Colors.green : Colors.orange,
                    ),
                    const SizedBox(height: 16),
                    _buildStatusCard(
                      'Last Sync',
                      _formatLastSync(_syncStatus?['lastSyncTime']),
                      Icons.access_time,
                      Colors.purple,
                    ),
                    const SizedBox(height: 24),
                    if (!_isOnline && (_syncStatus?['queuedOperations'] ?? 0) > 0)
                      ElevatedButton.icon(
                        onPressed: _forceSyncPending,
                        icon: const Icon(Icons.sync),
                        label: const Text('Force Sync When Online'),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.all(16),
                        ),
                      ),
                    const SizedBox(height: 12),
                    OutlinedButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                        _updateSyncStatus();
                      },
                      icon: const Icon(Icons.refresh),
                      label: const Text('Refresh Status'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.all(16),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatusCard(String title, String value, IconData icon, Color color) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.grey,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    value,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatLastSync(dynamic lastSyncTime) {
    if (lastSyncTime == null) return 'Never';
    
    try {
      final DateTime syncTime = lastSyncTime is DateTime 
          ? lastSyncTime 
          : DateTime.parse(lastSyncTime.toString());
      
      final Duration diff = DateTime.now().difference(syncTime);
      
      if (diff.inMinutes < 1) {
        return 'Just now';
      } else if (diff.inMinutes < 60) {
        return '${diff.inMinutes} minutes ago';
      } else if (diff.inHours < 24) {
        return '${diff.inHours} hours ago';
      } else {
        return '${diff.inDays} days ago';
      }
    } catch (e) {
      return 'Unknown';
    }
  }

  Future<void> _forceSyncPending() async {
    try {
      await _syncService.forceSyncPending();
      await _updateSyncStatus();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Sync operation initiated'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Sync failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}