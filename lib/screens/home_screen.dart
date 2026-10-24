import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:shimmer/shimmer.dart';

import '../models/post_model.dart';
import '../models/story_model.dart';
import '../services/post_service.dart';
import '../services/story_service.dart';
import '../services/auth_service.dart';
import '../services/storage_service.dart';
import '../widgets/post_card.dart';
import 'create_post_screen.dart';
import 'stories_view_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final ScrollController _scrollController = ScrollController();
  List<PostModel> _posts = [];
  bool _isLoading = false;
  bool _isLoadingMore = false;
  String? _lastDocId;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_scrollListener);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_scrollListener);
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollListener() {
    if (_scrollController.position.pixels == _scrollController.position.maxScrollExtent) {
      _loadMore();
    }
  }

  void _loadMore() async {
    if (_isLoadingMore || _posts.isEmpty) return;
    setState(() => _isLoadingMore = true);
    try {
      final postService = context.read<PostService>();
      final lastDoc = await postService.getLastDoc();
      if (lastDoc != null) {
        final more = await postService.getMorePosts(lastDoc: lastDoc);
        setState(() {
          _posts.addAll(more);
        });
      }
    } catch (_) {}
    setState(() => _isLoadingMore = false);
  }

  Future<void> _refresh() async {
    setState(() => _isLoading = true);
    await Future.delayed(const Duration(milliseconds: 500));
    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final postService = context.read<PostService>();
    final storyService = context.read<StoryService>();

    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _refresh,
          child: CustomScrollView(
            controller: _scrollController,
            slivers: [
              // Stories section
              SliverToBoxAdapter(
                child: _StoriesSection(storyService: storyService),
              ),
              // Create post bar
              SliverToBoxAdapter(
                child: _CreatePostBar(),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 8)),
              // Posts
              StreamBuilder<List<PostModel>>(
                stream: postService.getFeedPosts(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) => _PostSkeleton(),
                        childCount: 3,
                      ),
                    );
                  }
                  if (snapshot.hasError) {
                    return SliverToBoxAdapter(
                      child: Center(
                        child: Padding(
                          padding: const EdgeInsets.all(32),
                          child: Column(
                            children: [
                              Icon(Icons.cloud_off, size: 48, color: theme.colorScheme.outline),
                              const SizedBox(height: 12),
                              Text('Could not load posts', style: theme.textTheme.titleMedium),
                              const SizedBox(height: 8),
                              FilledButton(onPressed: _refresh, child: const Text('Retry')),
                            ],
                          ),
                        ),
                      ),
                    );
                  }
                  final posts = snapshot.data ?? [];
                  if (posts.isEmpty) {
                    return SliverToBoxAdapter(
                      child: Center(
                        child: Padding(
                          padding: const EdgeInsets.all(32),
                          child: Column(
                            children: [
                              Icon(Icons.article_outlined, size: 64, color: theme.colorScheme.outline),
                              const SizedBox(height: 16),
                              Text('No posts yet', style: theme.textTheme.titleLarge),
                              const SizedBox(height: 8),
                              Text('Be the first to share something!', style: theme.textTheme.bodyMedium),
                              const SizedBox(height: 20),
                              FilledButton.icon(
                                onPressed: () => Navigator.push(context,
                                    MaterialPageRoute(builder: (_) => const CreatePostScreen())),
                                icon: const Icon(Icons.add),
                                label: const Text('Create Post'),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }
                  _posts = posts;
                  return SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        if (index == posts.length) {
                          return _isLoadingMore
                              ? const Padding(
                                  padding: EdgeInsets.all(16),
                                  child: Center(child: CircularProgressIndicator()),
                                )
                              : const SizedBox.shrink();
                        }
                        return Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          child: PostCard(post: posts[index]),
                        );
                      },
                      childCount: posts.length + 1,
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StoriesSection extends StatelessWidget {
  final StoryService storyService;

  const _StoriesSection({required this.storyService});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final user = context.read<AuthService>().currentUser;

    return Container(
      height: 120,
      color: theme.colorScheme.surface,
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: StreamBuilder<List<StoryModel>>(
        stream: storyService.getActiveStories(),
        builder: (context, snapshot) {
          final stories = snapshot.data ?? [];
          // Group by author
          final byAuthor = <String, List<StoryModel>>{};
          for (final s in stories) {
            byAuthor.putIfAbsent(s.authorId, () => []).add(s);
          }
          final authors = byAuthor.keys.toList();

          return ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            itemCount: authors.length + 1,
            itemBuilder: (context, index) {
              if (index == 0) {
                return _CreateStoryBubble(userId: user?.uid ?? '');
              }
              final authorId = authors[index - 1];
              final authorStories = byAuthor[authorId]!;
              final story = authorStories.first;
              final hasUnviewed = story.viewedBy.contains(user?.uid ?? '') == false;

              return GestureDetector(
                onTap: () {
                  Navigator.push(context, MaterialPageRoute(
                    builder: (_) => StoriesViewScreen(
                      stories: authorStories,
                      startIndex: 0,
                    ),
                  ));
                },
                child: Container(
                  width: 80,
                  margin: const EdgeInsets.only(right: 8),
                  child: Column(
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: hasUnviewed
                              ? const LinearGradient(
                                  colors: [Color(0xFF0866FF), Color(0xFF42A5F5), Colors.purple],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                )
                              : LinearGradient(colors: [theme.colorScheme.outline.withOpacity(0.3), theme.colorScheme.outline.withOpacity(0.3)]),
                        ),
                        padding: const EdgeInsets.all(3),
                        child: CircleAvatar(
                          radius: 32,
                          backgroundColor: theme.colorScheme.surfaceContainerHighest,
                          backgroundImage: story.mediaUrl != null
                              ? Image.network(story.mediaUrl!).image
                              : null,
                          child: story.mediaUrl == null
                              ? UserAvatar(photoUrl: story.authorPhotoUrl, name: story.authorName, radius: 32)
                              : null,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        story.authorId == user?.uid ? 'Your Story' : story.authorName.split(' ').first,
                        style: theme.textTheme.labelSmall,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class _CreateStoryBubble extends StatelessWidget {
  final String userId;

  const _CreateStoryBubble({required this.userId});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: () async {
        final picker = ImagePicker();
        final image = await picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
        if (image != null && context.mounted) {
          final storage = StorageService();
          final url = await storage.uploadStoryMedia(userId, image.path, 'image');
          await context.read<StoryService>().createStory(mediaUrl: url, mediaType: 'image');
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Story added!')),
            );
          }
        }
      },
      child: Container(
        width: 80,
        margin: const EdgeInsets.only(right: 8),
        child: Column(
          children: [
            Stack(
              children: [
                CircleAvatar(
                  radius: 32,
                  backgroundColor: theme.colorScheme.surfaceContainerHighest,
                  child: Icon(Icons.person, size: 32, color: theme.colorScheme.onSurfaceVariant),
                ),
                Positioned(
                  right: 0,
                  bottom: 0,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary,
                      shape: BoxShape.circle,
                      border: Border.all(color: theme.colorScheme.surface, width: 2),
                    ),
                    child: Icon(Icons.add, size: 16, color: theme.colorScheme.onPrimary),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text('Add Story', style: theme.textTheme.labelSmall),
          ],
        ),
      ),
    );
  }
}

class _CreatePostBar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final user = context.read<AuthService>().currentUser;
    return Container(
      color: theme.colorScheme.surface,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: theme.colorScheme.primary,
            backgroundImage: user?.photoURL != null ? NetworkImage(user!.photoURL!) : null,
            child: user?.photoURL == null
                ? Text((user?.displayName ?? 'U')[0].toUpperCase(), style: TextStyle(color: theme.colorScheme.onPrimary))
                : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: GestureDetector(
              onTap: () => Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const CreatePostScreen())),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Text("What's on your mind?", style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
              ),
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: Icon(Icons.photo_library, color: Colors.green),
            onPressed: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => const CreatePostScreen())),
          ),
        ],
      ),
    );
  }
}

class _PostSkeleton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Shimmer.fromColors(
      baseColor: theme.colorScheme.surfaceContainerHighest,
      highlightColor: theme.colorScheme.surface,
      child: Container(
        margin: const EdgeInsets.all(8),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(radius: 22, backgroundColor: theme.colorScheme.surface),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(width: 120, height: 12, color: theme.colorScheme.surface),
                    const SizedBox(height: 6),
                    Container(width: 60, height: 10, color: theme.colorScheme.surface),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(width: double.infinity, height: 16, color: theme.colorScheme.surface),
            const SizedBox(height: 8),
            Container(width: 200, height: 16, color: theme.colorScheme.surface),
            const SizedBox(height: 12),
            Container(width: double.infinity, height: 200, color: theme.colorScheme.surface),
          ],
        ),
      ),
    );
  }
}
