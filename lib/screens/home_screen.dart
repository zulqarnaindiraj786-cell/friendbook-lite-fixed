import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/post_model.dart';
import '../services/post_service.dart';
import 'create_post_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final postService = context.read<PostService>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('friendbook'),
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: theme.colorScheme.onPrimary,
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const CreatePostScreen()),
              );
            },
          ),
        ],
      ),
      body: StreamBuilder<List<PostModel>>(
        stream: postService.getPosts(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.cloud_off, size: 48, color: theme.colorScheme.outline),
                  const SizedBox(height: 12),
                  Text('Could not load posts',
                      style: theme.textTheme.titleMedium),
                  const SizedBox(height: 8),
                  FilledButton(
                    onPressed: () {},
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }
          final posts = snapshot.data ?? [];
          if (posts.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.article_outlined, size: 64, color: theme.colorScheme.outline),
                  const SizedBox(height: 16),
                  Text('No posts yet', style: theme.textTheme.titleLarge),
                  const SizedBox(height: 8),
                  Text(
                    'Be the first to share something!',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 20),
                  FilledButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const CreatePostScreen()),
                      );
                    },
                    icon: const Icon(Icons.add),
                    label: const Text('Create Post'),
                  ),
                ],
              ),
            );
          }
          return RefreshIndicator(
            onRefresh: () async => Future.delayed(const Duration(milliseconds: 500)),
            child: ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: posts.length,
              itemBuilder: (context, index) {
                final post = posts[index];
                return _PostCard(post: post);
              },
            ),
          );
        },
      ),
    );
  }
}

class _PostCard extends StatefulWidget {
  final PostModel post;

  const _PostCard({required this.post});

  @override
  State<_PostCard> createState() => _PostCardState();
}

class _PostCardState extends State<_PostCard> {
  bool _liked = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final post = widget.post;
    final timeAgo = _formatTime(post.createdAt);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 1,
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                CircleAvatar(
                  backgroundColor: theme.colorScheme.primary,
                  child: Text(
                    post.authorName.isNotEmpty ? post.authorName[0].toUpperCase() : 'U',
                    style: TextStyle(color: theme.colorScheme.onPrimary),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(post.authorName, style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
                      Text(timeAgo, style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.more_horiz),
                  onPressed: () {},
                ),
              ],
            ),
          ),
          if (post.content.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
              child: Text(post.content, style: theme.textTheme.bodyMedium),
            ),
          if (post.imageUrl != null && post.imageUrl!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Image.network(
                post.imageUrl!,
                fit: BoxFit.cover,
                width: double.infinity,
                errorBuilder: (_, __, ___) => Container(
                  height: 200,
                  color: theme.colorScheme.surfaceContainerHighest,
                  child: Icon(Icons.broken_image, size: 48, color: theme.colorScheme.outline),
                ),
              ),
            ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            child: Row(
              children: [
                _ReactionButton(
                  icon: _liked ? Icons.thumb_up : Icons.thumb_up_outlined,
                  label: '${post.likes}',
                  color: _liked ? theme.colorScheme.primary : theme.colorScheme.onSurfaceVariant,
                  onTap: () {
                    setState(() => _liked = !_liked);
                    final ps = context.read<PostService>();
                    if (_liked) {
                      ps.likePost(post.id);
                    } else {
                      ps.unlikePost(post.id);
                    }
                  },
                ),
                const SizedBox(width: 24),
                _ReactionButton(
                  icon: Icons.comment_outlined,
                  label: '${post.comments}',
                  color: theme.colorScheme.onSurfaceVariant,
                  onTap: () {},
                ),
                const SizedBox(width: 24),
                _ReactionButton(
                  icon: Icons.share_outlined,
                  label: 'Share',
                  color: theme.colorScheme.onSurfaceVariant,
                  onTap: () {},
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return DateFormat('MMM d').format(dt);
  }
}

class _ReactionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _ReactionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 20, color: color),
            const SizedBox(width: 6),
            Text(label, style: TextStyle(color: color, fontSize: 13)),
          ],
        ),
      ),
    );
  }
}
