import 'package:cloud_firestore/cloud_firestore.dart';

class StoryModel {
  final String id;
  final String authorId;
  final String authorName;
  final String authorPhotoUrl;
  final String? mediaUrl;
  final String mediaType; // image | video
  final String? caption;
  final List<String> viewedBy;
  final DateTime createdAt;
  final DateTime expiresAt;

  StoryModel({
    required this.id,
    required this.authorId,
    required this.authorName,
    this.authorPhotoUrl = '',
    this.mediaUrl,
    this.mediaType = 'image',
    this.caption,
    this.viewedBy = const [],
    required this.createdAt,
    required this.expiresAt,
  });

  factory StoryModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return StoryModel(
      id: doc.id,
      authorId: data['authorId'] ?? '',
      authorName: data['authorName'] ?? 'Unknown',
      authorPhotoUrl: data['authorPhotoUrl'] ?? '',
      mediaUrl: data['mediaUrl'] as String?,
      mediaType: data['mediaType'] ?? 'image',
      caption: data['caption'] as String?,
      viewedBy: List<String>.from(data['viewedBy'] ?? []),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      expiresAt: (data['expiresAt'] as Timestamp?)?.toDate() ??
          DateTime.now().add(const Duration(hours: 24)),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'authorId': authorId,
      'authorName': authorName,
      'authorPhotoUrl': authorPhotoUrl,
      'mediaUrl': mediaUrl,
      'mediaType': mediaType,
      'caption': caption,
      'viewedBy': viewedBy,
      'createdAt': Timestamp.fromDate(createdAt),
      'expiresAt': Timestamp.fromDate(expiresAt),
    };
  }

  bool get isExpired => DateTime.now().isAfter(expiresAt);
}
