import 'package:cloud_firestore/cloud_firestore.dart';

class Reaction {
  final String userId;
  final String type; // like | love | haha | wow | sad | angry
  final DateTime createdAt;

  Reaction({required this.userId, required this.type, required this.createdAt});

  factory Reaction.fromMap(Map<String, dynamic> data) {
    return Reaction(
      userId: data['userId'] ?? '',
      type: data['type'] ?? 'like',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() => {
        'userId': userId,
        'type': type,
        'createdAt': Timestamp.fromDate(createdAt),
      };
}

class PostModel {
  final String id;
  final String authorId;
  final String authorName;
  final String authorPhotoUrl;
  final String content;
  final String? mediaUrl;
  final String mediaType; // image | video | none
  final String? feeling;
  final int likes;
  final int comments;
  final int shares;
  final DateTime createdAt;
  final String? sharedFromId;
  final List<String> savedBy;

  PostModel({
    required this.id,
    required this.authorId,
    required this.authorName,
    this.authorPhotoUrl = '',
    required this.content,
    this.mediaUrl,
    this.mediaType = 'none',
    this.feeling,
    required this.likes,
    required this.comments,
    this.shares = 0,
    required this.createdAt,
    this.sharedFromId,
    this.savedBy = const [],
  });

  factory PostModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return PostModel(
      id: doc.id,
      authorId: data['authorId'] ?? '',
      authorName: data['authorName'] ?? 'Unknown',
      authorPhotoUrl: data['authorPhotoUrl'] ?? '',
      content: data['content'] ?? '',
      mediaUrl: data['mediaUrl'] as String?,
      mediaType: data['mediaType'] ?? 'none',
      feeling: data['feeling'] as String?,
      likes: data['likes'] ?? 0,
      comments: data['comments'] ?? 0,
      shares: data['shares'] ?? 0,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      sharedFromId: data['sharedFromId'] as String?,
      savedBy: List<String>.from(data['savedBy'] ?? []),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'authorId': authorId,
      'authorName': authorName,
      'authorPhotoUrl': authorPhotoUrl,
      'content': content,
      'mediaUrl': mediaUrl,
      'mediaType': mediaType,
      'feeling': feeling,
      'likes': likes,
      'comments': comments,
      'shares': shares,
      'createdAt': Timestamp.fromDate(createdAt),
      'sharedFromId': sharedFromId,
      'savedBy': savedBy,
    };
  }
}
