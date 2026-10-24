import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:video_player/video_player.dart';
import '../models/story_model.dart';
import '../services/story_service.dart';
import '../services/auth_service.dart';
import '../widgets/user_avatar.dart';

class StoriesViewScreen extends StatefulWidget {
  final List<StoryModel> stories;
  final int startIndex;

  const StoriesViewScreen({super.key, required this.stories, this.startIndex = 0});

  @override
  State<StoriesViewScreen> createState() => _StoriesViewScreenState();
}

class _StoriesViewScreenState extends State<StoriesViewScreen> {
  late int _currentIndex;
  VideoPlayerController? _videoController;
  bool _isVideo = false;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.startIndex;
    _loadStory(widget.stories[_currentIndex]);
  }

  @override
  void dispose() {
    _videoController?.dispose();
    super.dispose();
  }

  void _loadStory(StoryModel story) {
    _videoController?.dispose();
    _videoController = null;
    _isVideo = story.mediaType == 'video';
    if (_isVideo && story.mediaUrl != null) {
      _videoController = VideoPlayerController.networkUrl(Uri.parse(story.mediaUrl!))
        ..initialize().then((_) {
          if (mounted) {
            _videoController!.play();
            setState(() {});
          }
        });
      _videoController!.addListener(() {
        if (_videoController!.value.position >= _videoController!.value.duration) {
          _nextStory();
        }
      });
    }
    // Mark as viewed
    context.read<StoryService>().markViewed(story.id);
  }

  void _nextStory() {
    if (_currentIndex < widget.stories.length - 1) {
      setState(() {
        _currentIndex++;
        _loadStory(widget.stories[_currentIndex]);
      });
    } else {
      Navigator.pop(context);
    }
  }

  void _prevStory() {
    if (_currentIndex > 0) {
      setState(() {
        _currentIndex--;
        _loadStory(widget.stories[_currentIndex]);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final story = widget.stories[_currentIndex];
    final user = context.read<AuthService>().currentUser;
    final isOwner = story.authorId == user?.uid;
    final viewedBy = story.viewedBy;
    final viewers = viewedBy.where((id) => id != story.authorId).length;

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          children: [
            // Media
            if (story.mediaUrl != null)
              _isVideo
                  ? (_videoController?.value.isInitialized == true
                      ? Center(child: AspectRatio(aspectRatio: _videoController!.value.aspectRatio, child: VideoPlayer(_videoController!)))
                      : const Center(child: CircularProgressIndicator()))
                  : Image.network(
                      story.mediaUrl!,
                      fit: BoxFit.contain,
                      width: double.infinity,
                      height: double.infinity,
                    )
            else
              Center(
                child: Text(story.caption ?? 'Story', style: const TextStyle(color: Colors.white, fontSize: 24)),
              ),
            // Progress bars
            Positioned(
              top: 8,
              left: 8,
              right: 8,
              child: Row(
                children: List.generate(widget.stories.length, (i) {
                  return Expanded(
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 2),
                      height: 3,
                      decoration: BoxDecoration(
                        color: i <= _currentIndex ? Colors.white : Colors.white.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  );
                }),
              ),
            ),
            // Header
            Positioned(
              top: 20,
              left: 8,
              right: 8,
              child: Row(
                children: [
                  UserAvatar(photoUrl: story.authorPhotoUrl, name: story.authorName, radius: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(story.authorName, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                        if (viewers > 0 && isOwner)
                          Text('$viewers views', style: const TextStyle(color: Colors.white70, fontSize: 12)),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                  if (isOwner)
                    IconButton(
                      icon: const Icon(Icons.delete, color: Colors.white),
                      onPressed: () {
                        context.read<StoryService>().deleteStory(story.id);
                        Navigator.pop(context);
                      },
                    ),
                ],
              ),
            ),
            // Tap zones
            Positioned.fill(
              child: Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: GestureDetector(onTap: _prevStory),
                  ),
                  Expanded(
                    flex: 7,
                    child: GestureDetector(onTap: _nextStory),
                  ),
                ],
              ),
            ),
            // Caption
            if (story.caption != null && story.caption!.isNotEmpty)
              Positioned(
                bottom: 40,
                left: 20,
                right: 20,
                child: Text(
                  story.caption!,
                  style: const TextStyle(color: Colors.white, fontSize: 16),
                  textAlign: TextAlign.center,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
