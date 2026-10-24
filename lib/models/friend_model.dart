class FriendModel {
  final String uid;
  final String displayName;
  final String? photoUrl;
  final String bio;
  final bool isOnline;
  final DateTime? lastSeen;

  FriendModel({
    required this.uid,
    required this.displayName,
    this.photoUrl,
    this.bio = '',
    this.isOnline = false,
    this.lastSeen,
  });

  factory FriendModel.fromMap(Map<String, dynamic> data, String id) {
    return FriendModel(
      uid: id,
      displayName: data['displayName'] ?? 'User',
      photoUrl: data['photoUrl'] as String?,
      bio: data['bio'] ?? '',
      isOnline: data['isOnline'] ?? false,
      lastSeen: data['lastSeen'] != null
          ? (data['lastSeen'] as dynamic).toDate() as DateTime?
          : null,
    );
  }
}
