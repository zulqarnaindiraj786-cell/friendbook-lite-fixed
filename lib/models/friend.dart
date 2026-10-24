import 'package:cloud_firestore/cloud_firestore.dart';

class FriendModel {
  final String uid;
  final String displayName;
  final String? photoUrl;
  final String bio;
  final bool isOnline;

  FriendModel({
    required this.uid,
    required this.displayName,
    this.photoUrl,
    this.bio = '',
    this.isOnline = false,
  });

  factory FriendModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return FriendModel(
      uid: doc.id,
      displayName: data['displayName'] ?? 'User',
      photoUrl: data['photoUrl'],
      bio: data['bio'] ?? '',
      isOnline: data['isOnline'] ?? false,
    );
  }
}
