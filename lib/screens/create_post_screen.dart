import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../services/post_service.dart';
import '../services/storage_service.dart';
import 'package:video_player/video_player.dart';

class CreatePostScreen extends StatefulWidget {
  final String? prefillContent;
  final String? sharedPostId;

  const CreatePostScreen({super.key, this.prefillContent, this.sharedPostId});

  @override
  State<CreatePostScreen> createState() => _CreatePostScreenState();
}

class _CreatePostScreenState extends State<CreatePostScreen> {
  final _contentController = TextEditingController();
  bool _isPosting = false;
  File? _mediaFile;
  String _mediaType = 'none';
  String? _feeling;
  final _storage = StorageService();
  VideoPlayerController? _videoController;

  static const List<Map<String, String>> _feelings = [
    {'emoji': '😀', 'label': 'Feeling Happy'},
    {'emoji': '😢', 'label': 'Feeling Sad'},
    {'emoji': '😍', 'label': 'Feeling Loved'},
    {'emoji': '😮', 'label': 'Feeling Wow'},
    {'emoji': '😡', 'label': 'Feeling Angry'},
    {'emoji': '😴', 'label': 'Feeling Tired'},
    {'emoji': '🎉', 'label': 'Feeling Celebratory'},
    {'emoji': '🤔', 'label': 'Feeling Thoughtful'},
    {'emoji': '😎', 'label': 'Feeling Cool'},
    {'emoji': '🤗', 'label': 'Feeling Grateful'},
  ];

  @override
  void initState() {
    super.initState();
    if (widget.prefillContent != null) _contentController.text = widget.prefillContent!;
  }

  @override
  void dispose() {
    _contentController.dispose();
    _videoController?.dispose();
    super.dispose();
  }

  Future<void> _pickMedia(ImageSource source, String type) async {
    final picker = ImagePicker();
    if (type == 'video') {
      final video = await picker.pickVideo(source: source, maxDuration: const Duration(seconds: 60));
      if (video != null) {
        setState(() {
          _mediaFile = File(video.path);
          _mediaType = 'video';
        });
        _videoController = VideoPlayerController.file(_mediaFile!)..initialize().then((_) => setState(() {}));
      }
    } else {
      final image = await picker.pickImage(source: source, imageQuality: 80);
      if (image != null) {
        setState(() {
          _mediaFile = File(image.path);
          _mediaType = 'image';
        });
      }
    }
  }

  void _removeMedia() {
    setState(() {
      _mediaFile = null;
      _mediaType = 'none';
    });
    _videoController?.dispose();
    _videoController = null;
  }

  Future<void> _submitPost() async {
    final content = _contentController.text.trim();
    if (content.isEmpty && _mediaFile == null) return;
    setState(() => _isPosting = true);
    try {
      final postService = context.read<PostService>();
      String? mediaUrl;
      String mediaType = 'none';

      if (_mediaFile != null) {
        final user = postService.toString();
        mediaType = _mediaType;
        final storage = StorageService();
        final auth = context.read<dynamic>();
        final uid = auth.currentUser?.uid ?? 'unknown';
        mediaUrl = await storage.uploadPostMedia(uid, _mediaFile!.path, _mediaType);
      }

      if (widget.sharedPostId != null) {
        // For shared posts, the share action was already handled elsewhere
      }

      await postService.createPost(
        content: content,
        mediaUrl: mediaUrl,
        mediaType: mediaType,
        feeling: _feeling,
      );
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to post: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) setState(() => _isPosting = false);
    }
  }

  void _showFeelingPicker() {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('How are you feeling?',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _feelings.map((f) {
                return GestureDetector(
                  onTap: () {
                    setState(() => _feeling = f['label']);
                    Navigator.pop(context);
                  },
                  child: Chip(
                    avatar: Text(f['emoji']!, style: const TextStyle(fontSize: 20)),
                    label: Text(f['label']!),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Post'),
        actions: [
          TextButton(
            onPressed: _isPosting ? null : _submitPost,
            child: _isPosting
                ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2))
                : Text('Post', style: TextStyle(color: theme.colorScheme.primary, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: theme.colorScheme.primary,
                  child: Icon(Icons.person, color: theme.colorScheme.onPrimary),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('You', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
                      if (_feeling != null)
                        Text(_feeling!, style: theme.textTheme.bodySmall),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _contentController,
              maxLines: 6,
              autofocus: true,
              decoration: const InputDecoration(
                hintText: "What's on your mind?",
                border: InputBorder.none,
              ),
              style: theme.textTheme.bodyLarge,
            ),
            if (_mediaFile != null) ...[
              Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: _mediaType == 'video' && _videoController?.value.isInitialized == true
                        ? AspectRatio(
                            aspectRatio: _videoController!.value.aspectRatio,
                            child: VideoPlayer(_videoController!),
                          )
                        : Image.file(_mediaFile!, height: 250, width: double.infinity, fit: BoxFit.cover),
                  ),
                  Positioned(
                    top: 8,
                    right: 8,
                    child: CircleAvatar(
                      backgroundColor: Colors.black54,
                      child: IconButton(
                        icon: const Icon(Icons.close, color: Colors.white),
                        onPressed: _removeMedia,
                      ),
                    ),
                  ),
                  if (_mediaType == 'video' && _videoController?.value.isInitialized == true)
                    Center(
                      child: IconButton(
                        icon: Icon(_videoController!.value.isPlaying ? Icons.pause : Icons.play_arrow, size: 48, color: Colors.white),
                        onPressed: () {
                          setState(() {
                            _videoController!.value.isPlaying ? _videoController!.pause() : _videoController!.play();
                          });
                        },
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 16),
            ],
            const SizedBox(height: 8),
            Row(
              children: [
                IconButton(
                  icon: Icon(Icons.photo_library, color: Colors.green),
                  onPressed: () => _pickMedia(ImageSource.gallery, 'image'),
                ),
                IconButton(
                  icon: Icon(Icons.camera_alt, color: Colors.blue),
                  onPressed: () => _pickMedia(ImageSource.camera, 'image'),
                ),
                IconButton(
                  icon: Icon(Icons.video_library, color: Colors.red),
                  onPressed: () => _pickMedia(ImageSource.gallery, 'video'),
                ),
                IconButton(
                  icon: const Icon(Icons.videocam, color: Colors.orange),
                  onPressed: () => _pickMedia(ImageSource.camera, 'video'),
                ),
                IconButton(
                  icon: Icon(Icons.emoji_emotions_outlined, color: Colors.amber),
                  onPressed: _showFeelingPicker,
                ),
              ],
            ),
            if (_feeling != null)
              Chip(
                avatar: Text(_feelings.firstWhere((f) => f['label'] == _feeling)['emoji']!, style: const TextStyle(fontSize: 20)),
                label: Text(_feeling!),
                onDeleted: () => setState(() => _feeling = null),
              ),
          ],
        ),
      ),
    );
  }
}
