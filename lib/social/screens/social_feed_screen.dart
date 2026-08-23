import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import '../../shared/theme/context_tokens.dart';
import '../../shared/theme/trego_tokens.dart';
import '../../widgets/core/trego_app_bar.dart';
import '../social_service.dart';
import '../widgets/comments_sheet.dart';
import '../widgets/edit_post_dialog.dart';
import '../widgets/mention_text.dart';
import '../widgets/report_dialog.dart';
import 'friends_screen.dart';

class SocialFeedScreen extends StatefulWidget {
  /// Injectable for tests; defaults to a real [SocialService].
  final SocialService? service;

  const SocialFeedScreen({super.key, this.service});

  @override
  SocialFeedScreenState createState() => SocialFeedScreenState();
}

class SocialFeedScreenState extends State<SocialFeedScreen> {
  /// Re-fetch the feed. Called by the shell when the Feed tab is (re)selected.
  Future<void> reload() => _loadFeed();

  late final SocialService _socialService = widget.service ?? SocialService();
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
      backgroundColor: context.tokens.canvas,
      appBar: TregoAppBar(
        title: 'Feed',
        trailing: [
          IconButton(
            icon: const Icon(Icons.people_outline),
            tooltip: 'Friends',
            onPressed: _openFriends,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showCreatePostDialog,
        tooltip: 'New post',
        child: const Icon(Icons.edit),
      ),
      body: RefreshIndicator(
        onRefresh: _loadFeed,
        child: _buildFeedList(),
      ),
    );
  }

  void _openFriends() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const FriendsScreen()),
    );
  }

  Widget _buildFeedList() {
    if (_posts.isEmpty && _isLoading) {
      return Center(child: CircularProgressIndicator());
    }

    if (_posts.isEmpty) {
      final tokens = context.tokens;
      // Friends-scoped feeds are legitimately empty until you add friends
      // or post something, so nudge toward both.
      return ListView(
        // Keep pull-to-refresh working over the empty state.
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          SizedBox(height: MediaQuery.of(context).size.height * 0.18),
          Icon(Icons.forum_outlined, size: 64, color: tokens.inkMuted),
          const SizedBox(height: Space.lg),
          Center(
            child: Text('Your feed is quiet', style: context.typo.title),
          ),
          const SizedBox(height: Space.sm),
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: Space.xxl),
              child: Text(
                'Add friends to see their runs, or share your first post.',
                textAlign: TextAlign.center,
                style: context.typo.body.copyWith(color: tokens.inkMuted),
              ),
            ),
          ),
          const SizedBox(height: Space.xl),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              OutlinedButton.icon(
                onPressed: _openFriends,
                icon: const Icon(Icons.person_add_alt_1),
                label: const Text('Find friends'),
              ),
              const SizedBox(width: Space.md),
              ElevatedButton.icon(
                onPressed: _showCreatePostDialog,
                icon: const Icon(Icons.edit),
                label: const Text('Create post'),
              ),
            ],
          ),
        ],
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
    final tokens = context.tokens;
    return Card(
      color: tokens.surface,
      margin: const EdgeInsets.symmetric(horizontal: Space.lg, vertical: Space.sm),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(Radii.standardCard),
        side: BorderSide(color: tokens.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ListTile(
            leading: CircleAvatar(
              backgroundColor: tokens.surfaceSunken,
              backgroundImage: post['author']['photoURL'] != null
                  ? NetworkImage(post['author']['photoURL'])
                  : null,
              child: post['author']['photoURL'] == null
                  ? Icon(Icons.person, color: tokens.inkMuted)
                  : null,
            ),
            title: Text(post['author']['name'] ?? 'Unknown', style: context.typo.titleSmall),
            subtitle: Text(
              _formatTimestamp(post['createdAt']),
              style: context.typo.bodySmall.copyWith(color: tokens.inkMuted),
            ),
            trailing: _buildPostMenu(post),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: Space.lg, vertical: Space.sm),
            child: MentionText(
              content: post['content'] ?? '',
              mentions: mentionsOf(post),
              style: context.typo.body,
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
    final tokens = context.tokens;
    return SizedBox(
      height: 200,
      child: PageView.builder(
        itemCount: attachments.length,
        itemBuilder: (context, index) {
          final attachment = attachments[index];
          return Image.network(
            attachment,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) => Container(
              color: tokens.surfaceSunken,
              child: Icon(Icons.error, color: tokens.inkMuted),
            ),
          );
        },
      ),
    );
  }

  Widget _buildPostActions(Map<String, dynamic> post) {
    final tokens = context.tokens;
    return Row(
      children: [
        IconButton(
          icon: Icon(
            post['userLiked'] == true ? Icons.favorite : Icons.favorite_border,
            color: post['userLiked'] == true ? tokens.danger : tokens.inkMuted,
          ),
          onPressed: () => _toggleLike(post),
        ),
        Text('${post['likesCount'] ?? 0}', style: context.typo.bodySmall),
        const SizedBox(width: Space.lg),
        IconButton(
          icon: Icon(Icons.comment_outlined, color: tokens.inkMuted),
          onPressed: () => _showCommentsDialog(post),
        ),
        Text('${post['commentsCount'] ?? 0}', style: context.typo.bodySmall),
        const Spacer(),
        IconButton(
          icon: Icon(Icons.share_outlined, color: tokens.inkMuted),
          onPressed: () => _sharePost(post),
        ),
      ],
    );
  }

  Widget _buildPostMenu(Map<String, dynamic> post) {
    final isOwn = post['isOwn'] == true;
    return PopupMenuButton<String>(
      onSelected: (value) => _handlePostAction(value, post),
      itemBuilder: (context) => [
        if (isOwn) ...[
          const PopupMenuItem(value: 'edit', child: Text('Edit')),
          const PopupMenuItem(value: 'delete', child: Text('Delete')),
        ] else
          const PopupMenuItem(value: 'report', child: Text('Report')),
      ],
    );
  }

  Widget _buildLoadingIndicator() {
    return const Padding(
      padding: EdgeInsets.all(Space.lg),
      child: Center(child: CircularProgressIndicator()),
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
              const SizedBox(height: Space.lg),
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
              const SizedBox(height: Space.lg),
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
    CommentsSheet.show(
      context,
      postId: post['id'],
      service: _socialService,
      onCommentAdded: () {
        if (mounted) {
          setState(() => post['commentsCount'] = (post['commentsCount'] ?? 0) + 1);
        }
      },
    );
  }

  void _sharePost(Map<String, dynamic> post) {
    final author = post['author'] as Map<String, dynamic>?;
    final name = author?['name'] ?? 'Someone';
    final content = post['content'] ?? '';
    Share.share('$name on Trego:\n\n$content');
  }

  void _handlePostAction(String action, Map<String, dynamic> post) {
    switch (action) {
      case 'report':
        _reportPost(post);
        break;
      case 'edit':
        _editPost(post);
        break;
      case 'delete':
        _deletePost(post);
        break;
    }
  }

  Future<void> _reportPost(Map<String, dynamic> post) async {
    final reason = await showReportDialog(context);
    if (reason == null) return;

    // Fire-and-forget: acknowledge immediately, send in the background.
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Thanks — we\'ll review this post.')),
      );
    }
    await _socialService.reportPost(post['id'], reason);
  }

  Future<void> _editPost(Map<String, dynamic> post) async {
    final newContent = await showEditPostDialog(context, post['content'] ?? '');
    if (newContent == null) return;

    final updated = await _socialService.updatePost(post['id'], newContent);
    if (!mounted) return;

    if (updated != null) {
      setState(() => post['content'] = updated['content'] ?? newContent);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to update post')),
      );
    }
  }

  Future<void> _deletePost(Map<String, dynamic> post) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete post?'),
        content: const Text('This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    // Optimistically remove, restore on failure (mirrors _toggleLike).
    final index = _posts.indexOf(post);
    if (index == -1) return;
    setState(() => _posts.removeAt(index));

    final ok = await _socialService.deletePost(post['id']);
    if (!mounted) return;

    if (!ok) {
      setState(() => _posts.insert(index, post));
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to delete post')),
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
    _scrollController.dispose();
    super.dispose();
  }
}