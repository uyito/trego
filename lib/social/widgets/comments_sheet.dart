import 'package:flutter/material.dart';
import '../social_service.dart';

/// Modal bottom sheet showing a post's comments with an input bar to add one.
///
/// Self-contained: loads its own comments via [SocialService.getComments] and
/// posts new ones via [SocialService.commentOnPost]. Returns the number of
/// comments added (via [Navigator.pop]) so the caller can bump its counter.
class CommentsSheet extends StatefulWidget {
  final String postId;
  final SocialService service;

  /// Called once per successfully-posted comment, so the caller can keep its
  /// comment counter live regardless of how the sheet is later dismissed.
  final VoidCallback? onCommentAdded;

  const CommentsSheet({
    super.key,
    required this.postId,
    required this.service,
    this.onCommentAdded,
  });

  /// Opens the sheet. [onCommentAdded] fires per added comment.
  static Future<void> show(
    BuildContext context, {
    required String postId,
    required SocialService service,
    VoidCallback? onCommentAdded,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (_) => CommentsSheet(
        postId: postId,
        service: service,
        onCommentAdded: onCommentAdded,
      ),
    );
  }

  @override
  State<CommentsSheet> createState() => _CommentsSheetState();
}

class _CommentsSheetState extends State<CommentsSheet> {
  final TextEditingController _controller = TextEditingController();
  List<Map<String, dynamic>> _comments = [];
  bool _loading = true;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final comments = await widget.service.getComments(widget.postId);
    if (!mounted) return;
    setState(() {
      _comments = comments;
      _loading = false;
    });
  }

  Future<void> _submit() async {
    final text = _controller.text.trim();
    if (text.isEmpty || _submitting) return;

    setState(() => _submitting = true);
    final ok = await widget.service.commentOnPost(widget.postId, text);
    if (!mounted) return;

    if (ok) {
      _controller.clear();
      widget.onCommentAdded?.call();
      await _load();
    } else {
      setState(() => _submitting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to post comment')),
      );
      return;
    }
    if (mounted) setState(() => _submitting = false);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.6,
        minChildSize: 0.4,
        maxChildSize: 0.9,
        builder: (context, scrollController) {
          return Column(
            children: [
              const Padding(
                padding: EdgeInsets.all(16),
                child: Text('Comments',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ),
              Expanded(child: _buildBody(scrollController)),
              const Divider(height: 1),
              _buildInputBar(),
            ],
          );
        },
      ),
    );
  }

  Widget _buildBody(ScrollController scrollController) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_comments.isEmpty) {
      return const Center(child: Text('No comments yet. Be the first!'));
    }
    return ListView.builder(
      controller: scrollController,
      itemCount: _comments.length,
      itemBuilder: (context, index) {
        final c = _comments[index];
        final author = c['author'] as Map<String, dynamic>?;
        final photo = author?['photoURL'] as String?;
        return ListTile(
          leading: CircleAvatar(
            backgroundImage: photo != null ? NetworkImage(photo) : null,
            child: photo == null ? const Icon(Icons.person) : null,
          ),
          title: Text(author?['name'] ?? 'Unknown'),
          subtitle: Text(c['content'] ?? ''),
        );
      },
    );
  }

  Widget _buildInputBar() {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _controller,
                minLines: 1,
                maxLines: 4,
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => _submit(),
                decoration: const InputDecoration(
                  hintText: 'Add a comment...',
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
              ),
            ),
            IconButton(
              icon: _submitting
                  ? const SizedBox(
                      width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.send),
              onPressed: _submitting ? null : _submit,
            ),
          ],
        ),
      ),
    );
  }
}
