import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:timeago/timeago' as timeago;
import 'package:video_player/video_player.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/post_model.dart';
import '../services/post_service.dart';
import '../services/auth_service.dart';
import '../widgets/user_avatar.dart';
import '../widgets/reaction_picker.dart';
import 'comments_screen.dart';

class PostCard extends StatefulWidget {
  final PostModel post;

  const PostCard({super.key, required this.post});

  @override
  State<PostCard> createState() => _PostCardState();
}

class _PostCardState extends State<PostCard> {
  String? _userReaction;
  bool _isSaved = false;
  VideoPlayerController? _videoController;
  bool _isVideoInitialized = false;

  @override
  void initState() {
    super.initState();
    _loadUserReaction();
    _checkSaved();
    if (widget.post.mediaType == 'video' && widget.post.mediaUrl != null) {
      _videoController = VideoPlayerController.networkUrl(Uri.parse(widget.post.mediaUrl!))
        ..initialize().then((_) {
          if (mounted) setState(() => _isVideoInitialized = true);
        });
    }
  }

  @override
  void dispose() {
    _videoController?.dispose();
    super.dispose();
  }

  Future<void> _loadUserReaction() async {
    final reactions = context.read<PostService>().getReactions(widget.post.id);
    reactions.listen((list) {
      if (!mounted) return;
      final user = context.read<AuthService>().currentUser;
      if (user == null) return;
      final r = list.where((e) => e.userId == user.uid).toList();
      if (r.isNotEmpty) {
        setState(() => _userReaction = r.first.type);
      } else {
        setState(() => _userReaction = null);
      }
    });
  }

  Future<void> _checkSaved() async {
    final isSaved = await context.read<PostService>().isSaved(widget.post.id);
    if (mounted) setState(() => _isSaved = isSaved);
  }

  void _showReactionPicker() {
    HapticFeedback.mediumImpact();
    final overlay = Overlay.of(context).context.findRenderObject() as RenderBox;
    showMenu<String>(
      context: context,
      position: RelativeRect.fromLTRB(
        overlay.size.width / 2 - 150,
        overlay.size.height / 2 - 50,
        overlay.size.width / 2 - 150,
        overlay.size.height / 2 - 50,
      ),
      items: ['like', 'love', 'haha', 'wow', 'sad', 'angry'].map((type) {
        final emojis = {'like': '👍', 'love': '❤️', 'haha': '😂', 'wow': '😮', 'sad': '😢', 'angry': '😡'};
        return PopupMenuItem(value: type, child: Text(emojis[type]!));
      }).toList(),
    ).then((type) {
      if (type != null) {
        context.read<PostService>().setReaction(widget.post.id, type);
        setState(() => _userReaction = type);
      }
    });
  }

  void _showPostMenu() {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (widget.post.authorId == context.read<AuthService>().currentUser?.uid) ...[
              ListTile(
                leading: const Icon(Icons.edit_outlined),
                title: const Text('Edit Post'),
                onTap: () {
                  Navigator.pop(context);
                  _showEditDialog();
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete_outline, color: Colors.red),
                title: const Text('Delete Post', style: TextStyle(color: Colors.red)),
                onTap: () {
                  Navigator.pop(context);
                  _confirmDelete();
                },
              ),
            ],
            ListTile(
              leading: Icon(_isSaved ? Icons.bookmark : Icons.bookmark_border),
              title: Text(_isSaved ? 'Remove from Saved' : 'Save Post'),
              onTap: () {
                Navigator.pop(context);
                _toggleSave();
              },
            ),
            ListTile(
              leading: const Icon(Icons.share_outlined),
              title: const Text('Share to Timeline'),
              onTap: () {
                Navigator.pop(context);
                context.read<PostService>().sharePost(widget.post.id);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Post shared to your timeline!')),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.link),
              title: const Text('Share Link'),
              onTap: () {
                Navigator.pop(context);
                Clipboard.setData(ClipboardData(text: 'https://friendbook.app/post/${widget.post.id}'));
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Link copied to clipboard')),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showEditDialog() {
    final controller = TextEditingController(text: widget.post.content);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Post'),
        content: TextField(
          controller: controller,
          maxLines: 5,
          decoration: const InputDecoration(hintText: 'What\'s on your mind?'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          FilledButton(
            onPressed: () {
              context.read<PostService>().editPost(widget.post.id, controller.text.trim());
              Navigator.pop(context);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _confirmDelete() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Post'),
        content: const Text('Are you sure you want to delete this post?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              context.read<PostService>().deletePost(widget.post.id);
              Navigator.pop(context);
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _toggleSave() {
    final ps = context.read<PostService>();
    if (_isSaved) {
      ps.unsavePost(widget.post.id);
      setState(() => _isSaved = false);
    } else {
      ps.savePost(widget.post.id);
      setState(() => _isSaved = true);
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(_isSaved ? 'Post saved' : 'Post removed from saved')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final post = widget.post;
    final isOwner = post.authorId == context.read<AuthService>().currentUser?.uid;
    final reactionEmojis = {'like': '👍', 'love': '❤️', 'haha': '😂', 'wow': '😮', 'sad': '😢', 'angry': '😡'};

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                UserAvatar(photoUrl: post.authorPhotoUrl, name: post.authorName, radius: 22),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(post.authorName, style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
                          if (post.feeling != null) ...[
                            const SizedBox(width: 4),
                            Text(post.feeling!, style: theme.textTheme.bodySmall),
                          ],
                          if (post.sharedFromId != null) ...[
                            const SizedBox(width: 4),
                            Icon(Icons.forward, size: 14, color: theme.colorScheme.outline),
                            const SizedBox(width: 4),
                            Text('Shared', style: theme.textTheme.bodySmall),
                          ],
                        ],
                      ),
                      Row(
                        children: [
                          Text(timeago.format(post.createdAt), style: theme.textTheme.bodySmall),
                          const SizedBox(width: 4),
                          Icon(Icons.public, size: 12, color: theme.colorScheme.outline),
                        ],
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.more_horiz),
                  onPressed: _showPostMenu,
                ),
              ],
            ),
          ),
          if (post.content.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
              child: Text(post.content, style: theme.textTheme.bodyLarge),
            ),
          if (post.mediaUrl != null && post.mediaUrl!.isNotEmpty) ...[
            const SizedBox(height: 8),
            if (post.mediaType == 'video')
              _isVideoInitialized
                  ? AspectRatio(
                      aspectRatio: _videoController!.value.aspectRatio,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          VideoPlayer(_videoController!),
                          IconButton(
                            icon: Icon(
                              _videoController!.value.isPlaying ? Icons.pause_circle_filled : Icons.play_circle_filled,
                              size: 56,
                              color: Colors.white.withOpacity(0.8),
                            ),
                            onPressed: () {
                              setState(() {
                                _videoController!.value.isPlaying
                                    ? _videoController!.pause()
                                    : _videoController!.play();
                              });
                            },
                          ),
                        ],
                      ),
                    )
                  : Container(
                      height: 250,
                      color: theme.colorScheme.surfaceContainerHighest,
                      child: const Center(child: CircularProgressIndicator()),
                    )
            else
              CachedNetworkImage(
                imageUrl: post.mediaUrl!,
                fit: BoxFit.cover,
                width: double.infinity,
                placeholder: (context, url) => Container(
                  height: 300,
                  color: theme.colorScheme.surfaceContainerHighest,
                  child: const Center(child: CircularProgressIndicator()),
                ),
                errorWidget: (context, url, error) => Container(
                  height: 200,
                  color: theme.colorScheme.surfaceContainerHighest,
                  child: Icon(Icons.broken_image, size: 48, color: theme.colorScheme.outline),
                ),
              ),
          ],
          // Reaction summary
          if (post.likes > 0 || post.comments > 0 || post.shares > 0)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              child: Row(
                children: [
                  if (post.likes > 0) ...[
                    const Icon(Icons.thumb_up, size: 16, color: Color(0xFF0866FF)),
                    const SizedBox(width: 4),
                    Text('${post.likes}', style: theme.textTheme.bodySmall),
                  ],
                  const Spacer(),
                  if (post.comments > 0)
                    Text('${post.comments} comments', style: theme.textTheme.bodySmall),
                  if (post.shares > 0) ...[
                    const SizedBox(width: 8),
                    Text('${post.shares} shares', style: theme.textTheme.bodySmall),
                  ],
                ],
              ),
            ),
          const Divider(height: 1),
          // Action bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      final newType = _userReaction == null ? 'like' : null;
                      if (newType != null) {
                        context.read<PostService>().setReaction(post.id, newType);
                        setState(() => _userReaction = newType);
                      } else {
                        context.read<PostService>().removeReaction(post.id);
                        setState(() => _userReaction = null);
                      }
                    },
                    onLongPress: _showReactionPicker,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          _userReaction != null ? (reactionEmojis[_userReaction] ?? '👍') : '👍',
                          style: const TextStyle(fontSize: 18),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          _userReaction != null
                              ? _userReaction!.capitalize()
                              : 'Like',
                          style: theme.textTheme.labelMedium?.copyWith(
                            color: _userReaction == 'like'
                                ? const Color(0xFF0866FF)
                                : _userReaction == 'love'
                                    ? Colors.red
                                    : null,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Expanded(
                  child: TextButton.icon(
                    onPressed: () {
                      Navigator.push(context, MaterialPageRoute(
                        builder: (_) => CommentsScreen(postId: post.id),
                      ));
                    },
                    icon: const Icon(Icons.comment_outlined),
                    label: const Text('Comment'),
                  ),
                ),
                Expanded(
                  child: TextButton.icon(
                    onPressed: () {
                      context.read<PostService>().sharePost(post.id);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Post shared!')),
                      );
                    },
                    icon: const Icon(Icons.share_outlined),
                    label: const Text('Share'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

extension StringExtension on String {
  String capitalize() {
    return "${this[0].toUpperCase()}${substring(1)}";
  }
}
