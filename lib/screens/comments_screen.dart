import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import '../models/comment_model.dart';
import '../services/auth_service.dart';
import '../services/comment_service.dart';
import '../services/storage_service.dart';
import '../widgets/user_avatar.dart';

class CommentsScreen extends StatefulWidget {
  final String postId;

  const CommentsScreen({super.key, required this.postId});

  @override
  State<CommentsScreen> createState() => _CommentsScreenState();
}

class _CommentsScreenState extends State<CommentsScreen> {
  final _commentController = TextEditingController();
  File? _commentImage;
  final _storage = StorageService();
  bool _isSending = false;
  String? _replyingToId;

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final image = await picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (image != null) {
      setState(() => _commentImage = File(image.path));
    }
  }

  Future<void> _submitComment() async {
    final content = _commentController.text.trim();
    if (content.isEmpty && _commentImage == null) return;
    setState(() => _isSending = true);
    try {
      String? imageUrl;
      if (_commentImage != null) {
        imageUrl = await _storage.uploadCommentImage(widget.postId, _commentImage!.path);
      }
      await context.read<CommentService>().addComment(
        postId: widget.postId,
        content: content,
        imageUrl: imageUrl,
        parentId: _replyingToId,
      );
      _commentController.clear();
      setState(() {
        _commentImage = null;
        _replyingToId = null;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to comment: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Comments')),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<List<CommentModel>>(
              stream: context.read<CommentService>().getComments(widget.postId),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                final comments = snapshot.data ?? [];
                if (comments.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.chat_bubble_outline, size: 48, color: theme.colorScheme.outline),
                        const SizedBox(height: 12),
                        Text('No comments yet', style: theme.textTheme.titleMedium),
                        const SizedBox(height: 4),
                        Text('Be the first to comment', style: theme.textTheme.bodySmall),
                      ],
                    ),
                  );
                }
                final topLevel = comments.where((c) => c.parentId == null).toList();
                final replies = comments.where((c) => c.parentId != null).toList();
                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: topLevel.length,
                  itemBuilder: (context, index) {
                    final comment = topLevel[index];
                    final commentReplies = replies.where((r) => r.parentId == comment.id).toList();
                    return _CommentTile(
                      comment: comment,
                      replies: commentReplies,
                      onReply: () => setState(() => _replyingToId = comment.id),
                      onDelete: (id) => context.read<CommentService>().deleteComment(id, widget.postId),
                    );
                  },
                );
              },
            ),
          ),
          if (_replyingToId != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: theme.colorScheme.surfaceContainerHighest,
              child: Row(
                children: [
                  Text('Replying to comment', style: theme.textTheme.bodySmall),
                  const Spacer(),
                  TextButton(
                    onPressed: () => setState(() => _replyingToId = null),
                    child: const Text('Cancel'),
                  ),
                ],
              ),
            ),
          if (_commentImage != null)
            Stack(
              children: [
                Image.file(_commentImage!, height: 100, width: 100, fit: BoxFit.cover),
                Positioned(
                  top: 4,
                  right: 4,
                  child: CircleAvatar(
                    radius: 14,
                    backgroundColor: Colors.black54,
                    child: IconButton(
                      icon: const Icon(Icons.close, size: 14, color: Colors.white),
                      onPressed: () => setState(() => _commentImage = null),
                    ),
                  ),
                ),
              ],
            ),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              border: Border(top: BorderSide(color: theme.colorScheme.outline.withOpacity(0.2))),
            ),
            child: SafeArea(
              child: Row(
                children: [
                  CircleAvatar(
                    backgroundColor: theme.colorScheme.primary,
                    child: Icon(Icons.person, color: theme.colorScheme.onPrimary, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: _commentController,
                      decoration: const InputDecoration(
                        hintText: 'Write a comment...',
                        isDense: true,
                      ),
                      onSubmitted: (_) => _submitComment(),
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.image, color: Colors.green),
                    onPressed: _pickImage,
                  ),
                  IconButton(
                    icon: Icon(Icons.emoji_emotions, color: Colors.amber),
                    onPressed: () {},
                  ),
                  IconButton(
                    icon: _isSending
                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                        : Icon(Icons.send, color: theme.colorScheme.primary),
                    onPressed: _isSending ? null : _submitComment,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CommentTile extends StatefulWidget {
  final CommentModel comment;
  final List<CommentModel> replies;
  final VoidCallback onReply;
  final Function(String) onDelete;

  const _CommentTile({
    required this.comment,
    required this.replies,
    required this.onReply,
    required this.onDelete,
  });

  @override
  State<_CommentTile> createState() => _CommentTileState();
}

class _CommentTileState extends State<_CommentTile> {
  bool _liked = false;
  bool _showReplies = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final c = widget.comment;
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              UserAvatar(photoUrl: c.authorPhotoUrl, name: c.authorName, radius: 18),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(c.authorName, style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
                          const SizedBox(height: 4),
                          Text(c.content, style: theme.textTheme.bodyMedium),
                          if (c.imageUrl != null) ...[
                            const SizedBox(height: 8),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.network(c.imageUrl!, height: 150, width: double.infinity, fit: BoxFit.cover),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        TextButton(
                          onPressed: () {
                            setState(() => _liked = !_liked);
                            final svc = context.read<CommentService>();
                            if (_liked) {
                              svc.likeComment(c.id);
                            } else {
                              svc.unlikeComment(c.id);
                            }
                          },
                          child: Text(
                            _liked ? 'Unlike' : 'Like',
                            style: theme.textTheme.labelSmall?.copyWith(fontWeight: FontWeight.w600),
                          ),
                        ),
                        const SizedBox(width: 8),
                        if (c.likes > 0)
                          Padding(
                            padding: const EdgeInsets.only(top: 2),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.thumb_up, size: 14, color: Color(0xFF0866FF)),
                                const SizedBox(width: 4),
                                Text('${c.likes}', style: theme.textTheme.labelSmall),
                              ],
                            ),
                          ),
                        const SizedBox(width: 16),
                        TextButton(
                          onPressed: widget.onReply,
                          child: Text('Reply', style: theme.textTheme.labelSmall?.copyWith(fontWeight: FontWeight.w600)),
                        ),
                        const Spacer(),
                        if (widget.comment.authorId == context.read<AuthService>().currentUser?.uid)
                          IconButton(
                            icon: Icon(Icons.delete_outline, size: 16, color: theme.colorScheme.outline),
                            onPressed: () => widget.onDelete(c.id),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (widget.replies.isNotEmpty) ...[
            TextButton(
              onPressed: () => setState(() => _showReplies = !_showReplies),
              child: Text(_showReplies ? 'Hide replies' : 'View ${widget.replies.length} replies'),
            ),
            if (_showReplies)
              Padding(
                padding: const EdgeInsets.only(left: 42),
                child: Column(
                  children: widget.replies.map((reply) => _ReplyTile(comment: reply, onDelete: widget.onDelete)).toList(),
                ),
              ),
          ],
        ],
      ),
    );
  }
}

class _ReplyTile extends StatelessWidget {
  final CommentModel comment;
  final Function(String) onDelete;

  const _ReplyTile({required this.comment, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          UserAvatar(photoUrl: comment.authorPhotoUrl, name: comment.authorName, radius: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(comment.authorName, style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text(comment.content, style: theme.textTheme.bodyMedium),
                  if (comment.imageUrl != null) ...[
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(comment.imageUrl!, height: 120, width: double.infinity, fit: BoxFit.cover),
                    ),
                  ],
                ],
              ),
            ),
          ),
          if (comment.authorId == context.read<AuthService>().currentUser?.uid)
            IconButton(
              icon: Icon(Icons.delete_outline, size: 16, color: theme.colorScheme.outline),
              onPressed: () => onDelete(comment.id),
            ),
        ],
      ),
    );
  }
}
