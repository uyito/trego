import 'package:flutter/material.dart';
import '../../shared/theme/context_tokens.dart';
import '../../shared/theme/trego_tokens.dart';
import '../social_service.dart';

class FriendsScreen extends StatefulWidget {
  /// Injectable for tests; defaults to a real [SocialService].
  final SocialService? service;

  /// Which tab to open on: 0 = Friends, 1 = Requests.
  final int initialTab;

  const FriendsScreen({super.key, this.service, this.initialTab = 0});

  @override
  State<FriendsScreen> createState() => _FriendsScreenState();
}

class _FriendsScreenState extends State<FriendsScreen> with SingleTickerProviderStateMixin {
  late final SocialService _socialService = widget.service ?? SocialService();
  late TabController _tabController;

  List<Map<String, dynamic>> _friends = [];
  List<Map<String, dynamic>> _friendRequests = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 2,
      vsync: this,
      initialIndex: widget.initialTab.clamp(0, 1),
    );
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    
    try {
      final friends = await _socialService.getFriends();
      final requests = await _socialService.getFriendRequests();
      
      setState(() {
        _friends = friends;
        _friendRequests = requests;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to load friends data')),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    return Scaffold(
      backgroundColor: tokens.canvas,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(56 + 48),
        child: Material(
          color: tokens.surfaceSunken,
          child: SafeArea(
            bottom: false,
            child: Column(
              children: [
                SizedBox(
                  height: 56,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: Space.lg),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text('Friends', style: context.typo.title),
                        ),
                        IconButton(
                          icon: Icon(Icons.person_add, color: tokens.ink),
                          onPressed: _showAddFriendDialog,
                        ),
                      ],
                    ),
                  ),
                ),
                TabBar(
                  controller: _tabController,
                  labelColor: tokens.brand,
                  unselectedLabelColor: tokens.inkMuted,
                  indicatorColor: tokens.brand,
                  tabs: [
                    Tab(text: 'Friends (${_friends.length})'),
                    Tab(text: 'Requests (${_friendRequests.length})'),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildFriendsTab(),
          _buildRequestsTab(),
        ],
      ),
    );
  }

  Widget _buildFriendsTab() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_friends.isEmpty) {
      final tokens = context.tokens;
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.people_outline, size: 64, color: tokens.inkMuted),
            const SizedBox(height: Space.lg),
            Text('No friends yet', style: context.typo.title),
            const SizedBox(height: Space.xs),
            Text(
              'Send friend requests to connect with others',
              style: context.typo.body.copyWith(color: tokens.inkMuted),
            ),
            const SizedBox(height: Space.xl),
            ElevatedButton(
              onPressed: _showAddFriendDialog,
              child: const Text('Add Friends'),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView.builder(
        itemCount: _friends.length,
        itemBuilder: (context, index) => _buildFriendTile(_friends[index]),
      ),
    );
  }

  Widget _buildRequestsTab() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_friendRequests.isEmpty) {
      final tokens = context.tokens;
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.mail_outline, size: 64, color: tokens.inkMuted),
            const SizedBox(height: Space.lg),
            Text('No friend requests', style: context.typo.title),
            const SizedBox(height: Space.xs),
            Text(
              'Friend requests will appear here',
              style: context.typo.body.copyWith(color: tokens.inkMuted),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView.builder(
        itemCount: _friendRequests.length,
        itemBuilder: (context, index) => _buildRequestTile(_friendRequests[index]),
      ),
    );
  }

  Widget _buildFriendTile(Map<String, dynamic> friend) {
    final tokens = context.tokens;
    return Card(
      color: tokens.surface,
      margin: const EdgeInsets.symmetric(horizontal: Space.lg, vertical: Space.xs),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(Radii.standardCard),
        side: BorderSide(color: tokens.border),
      ),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: tokens.surfaceSunken,
          backgroundImage: friend['photoURL'] != null
              ? NetworkImage(friend['photoURL'])
              : null,
          child: friend['photoURL'] == null
              ? Icon(Icons.person, color: tokens.inkMuted)
              : null,
        ),
        title: Text(friend['name'] ?? 'Unknown', style: context.typo.titleSmall),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (friend['status'] != null)
              Text(friend['status'], style: context.typo.bodySmall.copyWith(color: tokens.inkMuted)),
            if (friend['mutualFriends'] != null)
              Text(
                '${friend['mutualFriends']} mutual friends',
                style: context.typo.bodySmall.copyWith(color: tokens.inkMuted),
              ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (friend['isOnline'] == true)
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: tokens.success,
                  shape: BoxShape.circle,
                ),
              ),
            const SizedBox(width: Space.sm),
            PopupMenuButton<String>(
              onSelected: (value) => _handleFriendAction(value, friend),
              itemBuilder: (context) => [
                const PopupMenuItem(value: 'profile', child: Text('View Profile')),
                const PopupMenuItem(value: 'message', child: Text('Message')),
                const PopupMenuItem(value: 'challenge', child: Text('Challenge')),
                const PopupMenuItem(value: 'unfriend', child: Text('Unfriend')),
              ],
            ),
          ],
        ),
        onTap: () => _viewFriendProfile(friend),
      ),
    );
  }

  Widget _buildRequestTile(Map<String, dynamic> request) {
    final bool isIncoming = request['type'] == 'incoming';
    final tokens = context.tokens;

    return Card(
      color: tokens.surface,
      margin: const EdgeInsets.symmetric(horizontal: Space.lg, vertical: Space.xs),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(Radii.standardCard),
        side: BorderSide(color: tokens.border),
      ),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: tokens.surfaceSunken,
          backgroundImage: request['user']['photoURL'] != null
              ? NetworkImage(request['user']['photoURL'])
              : null,
          child: request['user']['photoURL'] == null
              ? Icon(Icons.person, color: tokens.inkMuted)
              : null,
        ),
        title: Text(request['user']['name'] ?? 'Unknown', style: context.typo.titleSmall),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              isIncoming ? 'Wants to be friends' : 'Request sent',
              style: context.typo.bodySmall,
            ),
            if (request['message'] != null)
              Text(
                '"${request['message']}"',
                style: context.typo.bodySmall.copyWith(fontStyle: FontStyle.italic),
              ),
            Text(
              _formatTimestamp(request['createdAt']),
              style: context.typo.bodySmall.copyWith(color: tokens.inkMuted),
            ),
          ],
        ),
        trailing: isIncoming
            ? Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextButton(
                    onPressed: () => _respondToRequest(request['id'], false),
                    child: const Text('Decline'),
                  ),
                  ElevatedButton(
                    onPressed: () => _respondToRequest(request['id'], true),
                    child: const Text('Accept'),
                  ),
                ],
              )
            : TextButton(
                onPressed: () => _cancelRequest(request['id']),
                child: const Text('Cancel'),
              ),
      ),
    );
  }

  void _showAddFriendDialog() {
    final TextEditingController searchController = TextEditingController();
    final TextEditingController messageController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Add Friend'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: searchController,
              decoration: InputDecoration(
                labelText: 'Add by username or email',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.person_search),
              ),
            ),
            SizedBox(height: 16),
            TextField(
              controller: messageController,
              decoration: InputDecoration(
                labelText: 'Message (optional)',
                border: OutlineInputBorder(),
                hintText: "Hi! Let's be workout buddies!",
              ),
              maxLines: 2,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => _sendFriendRequest(
              searchController.text,
              messageController.text,
            ),
            child: Text('Send Request'),
          ),
        ],
      ),
    );
  }

  Future<void> _sendFriendRequest(String friendId, String message) async {
    if (friendId.trim().isEmpty) return;

    Navigator.pop(context);
    
    try {
      final success = await _socialService.sendFriendRequest(
        friendId.trim(),
        message: message.trim().isNotEmpty ? message.trim() : null,
      );
      
      if (success) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Friend request sent!')),
          );
        }
        _loadData(); // Refresh data
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to send friend request')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error sending friend request')),
        );
      }
    }
  }

  Future<void> _respondToRequest(String requestId, bool accept) async {
    try {
      final success = await _socialService.respondToFriendRequest(requestId, accept);
      
      if (success) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(accept ? 'Friend request accepted!' : 'Friend request declined')),
          );
        }
        _loadData(); // Refresh data
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to respond to request')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error responding to request')),
        );
      }
    }
  }

  Future<void> _cancelRequest(String requestId) async {
    try {
      final success = await _socialService.cancelFriendRequest(requestId);
      if (!mounted) return;
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Request cancelled')),
        );
        _loadData();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to cancel request')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error cancelling request')),
        );
      }
    }
  }

  void _handleFriendAction(String action, Map<String, dynamic> friend) {
    switch (action) {
      case 'profile':
        _viewFriendProfile(friend);
        break;
      case 'message':
        // TODO: Navigate to messaging
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Messaging feature coming soon!')),
          );
        }
        break;
      case 'challenge':
        // TODO: Navigate to challenge creation
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Challenge feature coming soon!')),
          );
        }
        break;
      case 'unfriend':
        _showUnfriendDialog(friend);
        break;
    }
  }

  void _viewFriendProfile(Map<String, dynamic> friend) {
    // TODO: Navigate to friend profile view once that screen exists.
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Friend profiles coming soon!')),
      );
    }
  }

  void _showUnfriendDialog(Map<String, dynamic> friend) {
    final tokens = context.tokens;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Unfriend ${friend['name']}?'),
        content: const Text('This person will be removed from your friends list.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _unfriend(friend);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: tokens.danger,
              foregroundColor: tokens.onDanger,
            ),
            child: const Text('Unfriend'),
          ),
        ],
      ),
    );
  }

  Future<void> _unfriend(Map<String, dynamic> friend) async {
    final friendUid = friend['uid'] ?? friend['id'];
    // Optimistically remove, restore on failure.
    final index = _friends.indexOf(friend);
    if (index != -1) setState(() => _friends.removeAt(index));

    final ok = await _socialService.unfriend(friendUid);
    if (!mounted) return;
    if (!ok && index != -1) {
      setState(() => _friends.insert(index, friend));
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to unfriend')),
      );
    }
  }

  String _formatTimestamp(String? timestamp) {
    if (timestamp == null) return '';
    
    final dateTime = DateTime.tryParse(timestamp);
    if (dateTime == null) return '';
    
    final now = DateTime.now();
    final difference = now.difference(dateTime);
    
    if (difference.inMinutes < 1) return 'Just now';
    if (difference.inMinutes < 60) return '${difference.inMinutes}m ago';
    if (difference.inHours < 24) return '${difference.inHours}h ago';
    if (difference.inDays < 7) return '${difference.inDays}d ago';
    
    return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
}