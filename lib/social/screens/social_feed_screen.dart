import 'package:flutter/material.dart';
import '../social_service.dart';

class SocialFeedScreen extends StatefulWidget {
  const SocialFeedScreen({super.key});

  @override
  State<SocialFeedScreen> createState() => _SocialFeedScreenState();
}

class _SocialFeedScreenState extends State<SocialFeedScreen> {
  final SocialService _socialService = SocialService();
  final ScrollController _scrollController = ScrollController();
  
  List<Map<String, dynamic>> _posts = [];
  bool _isLoading = false;
  bool _hasMore = true;
  int _offset = 0;
  final int _limit = 20;

  @override
  void initState() {
    super.initState();
    _loadFeed();
    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    if (_scrollController.position.pixels == _scrollController.position.maxScrollExtent) {
      _loadMorePosts();
    }
  }

  Future<void> _loadFeed() async {
    if (_isLoading) return;
    
    setState(() => _isLoading = true);
    
    try {
      final posts = await _socialService.getFeed(limit: _limit);
      setState(() {
        _posts = posts;
        _offset = posts.length;
        _hasMore = posts.length == _limit;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to load feed')),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadMorePosts() async {
    if (_isLoading || !_hasMore) return;
    
    setState(() => _isLoading = true);
    
    try {
      final newPosts = await _socialService.getFeed(limit: _limit, offset: _offset);
      setState(() {
        _posts.addAll(newPosts);
        _offset += newPosts.length;
        _hasMore = newPosts.length == _limit;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to load more posts')),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Social Feed'),
        actions: [
          IconButton(
            icon: Icon(Icons.notifications),
            onPressed: () => Navigator.pushNamed(context, '/notifications'),
          ),
          IconButton(
            icon: Icon(Icons.add),
            onPressed: () => _showCreatePostDialog(),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadFeed,
        child: _buildFeedList(),
      ),
      bottomNavigationBar: _buildBottomNavBar(),
    );
  }

  Widget _buildFeedList() {
    if (_posts.isEmpty && _isLoading) {
      return Center(child: CircularProgressIndicator());
    }

    if (_posts.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.people_outline, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text('No posts yet', style: Theme.of(context).textTheme.headlineSmall),
            Text('Follow friends or create your first post!'),
            SizedBox(height: 24),
            ElevatedButton(
              onPressed: _showCreatePostDialog,
              child: Text('Create Post'),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      controller: _scrollController,
      itemCount: _posts.length + (_hasMore ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == _posts.length) {
          return _buildLoadingIndicator();
        }
        return _buildPostCard(_posts[index]);
      },
    );
  }

  Widget _buildPostCard(Map<String, dynamic> post) {
    return Card(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ListTile(
            leading: CircleAvatar(
              backgroundImage: post['author']['photoURL'] != null
                  ? NetworkImage(post['author']['photoURL'])
                  : null,
              child: post['author']['photoURL'] == null
                  ? Icon(Icons.person)
                  : null,
            ),
            title: Text(post['author']['name'] ?? 'Unknown'),
            subtitle: Text(_formatTimestamp(post['createdAt'])),
            trailing: _buildPostMenu(post),
          ),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Text(
              post['content'] ?? '',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
          ),
          if (post['attachments']?.isNotEmpty == true)
            _buildPostAttachments(post['attachments']),
          _buildPostActions(post),
        ],
      ),
    );
  }

  Widget _buildPostAttachments(List attachments) {
    return SizedBox(
      height: 200,
      child: PageView.builder(
        itemCount: attachments.length,
        itemBuilder: (context, index) {
          final attachment = attachments[index];
          return Image.network(
            attachment,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) => 
                Container(color: Colors.grey[300], child: const Icon(Icons.error)),
          );
        },
      ),
    );
  }

  Widget _buildPostActions(Map<String, dynamic> post) {
    return Row(
      children: [
        IconButton(
          icon: Icon(
            post['userLiked'] == true ? Icons.favorite : Icons.favorite_border,
            color: post['userLiked'] == true ? Colors.red : null,
          ),
          onPressed: () => _toggleLike(post),
        ),
        Text('${post['likesCount'] ?? 0}'),
        SizedBox(width: 16),
        IconButton(
          icon: Icon(Icons.comment_outlined),
          onPressed: () => _showCommentsDialog(post),
        ),
        Text('${post['commentsCount'] ?? 0}'),
        Spacer(),
        IconButton(
          icon: Icon(Icons.share_outlined),
          onPressed: () => _sharePost(post),
        ),
      ],
    );
  }

  Widget _buildPostMenu(Map<String, dynamic> post) {
    return PopupMenuButton<String>(
      onSelected: (value) => _handlePostAction(value, post),
      itemBuilder: (context) => [
        PopupMenuItem(value: 'report', child: Text('Report')),
        if (post['isOwn'] == true) ...[
          PopupMenuItem(value: 'edit', child: Text('Edit')),
          PopupMenuItem(value: 'delete', child: Text('Delete')),
        ],
      ],
    );
  }

  Widget _buildLoadingIndicator() {
    return Padding(
      padding: EdgeInsets.all(16),
      child: Center(child: CircularProgressIndicator()),
    );
  }

  Widget _buildBottomNavBar() {
    return BottomNavigationBar(
      type: BottomNavigationBarType.fixed,
      currentIndex: 0,
      onTap: (index) => _navigateToTab(index),
      items: [
        BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Feed'),
        BottomNavigationBarItem(icon: Icon(Icons.people), label: 'Friends'),
        BottomNavigationBarItem(icon: Icon(Icons.emoji_events), label: 'Challenges'),
        BottomNavigationBarItem(icon: Icon(Icons.leaderboard), label: 'Leaderboard'),
        BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
      ],
    );
  }

  void _showCreatePostDialog() {
    final TextEditingController controller = TextEditingController();
    String selectedType = 'general';
    String selectedVisibility = 'friends';

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text('Create Post'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: controller,
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: "What's on your mind?",
                  border: OutlineInputBorder(),
                ),
              ),
              SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: selectedType,
                decoration: InputDecoration(labelText: 'Post Type'),
                items: [
                  DropdownMenuItem(value: 'general', child: Text('General')),
                  DropdownMenuItem(value: 'workout', child: Text('Workout')),
                  DropdownMenuItem(value: 'nutrition', child: Text('Nutrition')),
                  DropdownMenuItem(value: 'achievement', child: Text('Achievement')),
                ],
                onChanged: (value) => setState(() => selectedType = value!),
              ),
              SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: selectedVisibility,
                decoration: InputDecoration(labelText: 'Visibility'),
                items: [
                  DropdownMenuItem(value: 'friends', child: Text('Friends Only')),
                  DropdownMenuItem(value: 'public', child: Text('Public')),
                  DropdownMenuItem(value: 'private', child: Text('Private')),
                ],
                onChanged: (value) => setState(() => selectedVisibility = value!),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => _createPost(controller.text, selectedType, selectedVisibility),
              child: Text('Post'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _createPost(String content, String type, String visibility) async {
    if (content.trim().isEmpty) return;

    Navigator.pop(context);
    
    try {
      final post = await _socialService.createPost(
        content: content,
        type: type,
        visibility: visibility,
      );
      
      if (post != null) {
        setState(() => _posts.insert(0, post));
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Post created successfully!')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to create post')),
        );
      }
    }
  }

  Future<void> _toggleLike(Map<String, dynamic> post) async {
    final postId = post['id'];
    final wasLiked = post['userLiked'] == true;
    
    // Optimistically update UI
    setState(() {
      post['userLiked'] = !wasLiked;
      post['likesCount'] = (post['likesCount'] ?? 0) + (wasLiked ? -1 : 1);
    });

    try {
      final success = await _socialService.likePost(postId);
      if (!success) {
        // Revert on failure
        setState(() {
          post['userLiked'] = wasLiked;
          post['likesCount'] = (post['likesCount'] ?? 0) + (wasLiked ? 1 : -1);
        });
      }
    } catch (e) {
      // Revert on error
      setState(() {
        post['userLiked'] = wasLiked;
        post['likesCount'] = (post['likesCount'] ?? 0) + (wasLiked ? 1 : -1);
      });
    }
  }

  void _showCommentsDialog(Map<String, dynamic> post) {
    // TODO: Implement comments dialog
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Comments feature coming soon!')),
    );
  }

  void _sharePost(Map<String, dynamic> post) {
    // TODO: Implement post sharing
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Share feature coming soon!')),
    );
  }

  void _handlePostAction(String action, Map<String, dynamic> post) {
    switch (action) {
      case 'report':
        // TODO: Implement report functionality
        break;
      case 'edit':
        // TODO: Implement edit functionality
        break;
      case 'delete':
        // TODO: Implement delete functionality
        break;
    }
  }

  void _navigateToTab(int index) {
    switch (index) {
      case 0:
        // Already on feed
        break;
      case 1:
        Navigator.pushNamed(context, '/friends');
        break;
      case 2:
        Navigator.pushNamed(context, '/challenges');
        break;
      case 3:
        Navigator.pushNamed(context, '/leaderboard');
        break;
      case 4:
        Navigator.pushNamed(context, '/profile');
        break;
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
    _scrollController.dispose();
    super.dispose();
  }
}