import 'package:cloud_firestore/cloud_firestore.dart';

class PostModel {
  final String id;
  final String authorId;
  final String authorName;
  final String content;
  final String? imageUrl;
  final int likes;
  final int comments;
  final DateTime createdAt;

  PostModel({
    required this.id,
    required this.authorId,
    required this.authorName,
    required this.content,
    this.imageUrl,
    required this.likes,
    required this.comments,
    required this.createdAt,
  });

  factory PostModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return PostModel(
      id: doc.id,
      authorId: data['authorId'] ?? '',
      authorName: data['authorName'] ?? 'Unknown',
      content: data['content'] ?? '',
      imageUrl: data['imageUrl'],
      likes: data['likes'] ?? 0,
      comments: data['comments'] ?? 0,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'authorId': authorId,
      'authorName': authorName,
      'content': content,
      'imageUrl': imageUrl,
      'likes': likes,
      'comments': comments,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}
