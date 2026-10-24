import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String uid;
  final String email;
  final String displayName;
  final String? photoUrl;
  final String? coverUrl;
  final String bio;
  final int friendsCount;
  final DateTime createdAt;
  final bool isOnline;
  final DateTime? lastSeen;
  final String? work;
  final String? education;
  final String? city;
  final String? relationship;
  final String? fcmToken;
  final String privacy; // public | friends | private
  final List<String> blockedUsers;

  UserModel({
    required this.uid,
    required this.email,
    required this.displayName,
    this.photoUrl,
    this.coverUrl,
    this.bio = '',
    this.friendsCount = 0,
    required this.createdAt,
    this.isOnline = false,
    this.lastSeen,
    this.work,
    this.education,
    this.city,
    this.relationship,
    this.fcmToken,
    this.privacy = 'public',
    this.blockedUsers = const [],
  });

  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return UserModel(
      uid: doc.id,
      email: data['email'] ?? '',
      displayName: data['displayName'] ?? 'User',
      photoUrl: data['photoUrl'] as String?,
      coverUrl: data['coverUrl'] as String?,
      bio: data['bio'] ?? '',
      friendsCount: data['friendsCount'] ?? 0,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      isOnline: data['isOnline'] ?? false,
      lastSeen: (data['lastSeen'] as Timestamp?)?.toDate(),
      work: data['work'] as String?,
      education: data['education'] as String?,
      city: data['city'] as String?,
      relationship: data['relationship'] as String?,
      fcmToken: data['fcmToken'] as String?,
      privacy: data['privacy'] ?? 'public',
      blockedUsers: List<String>.from(data['blockedUsers'] ?? []),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'email': email,
      'displayName': displayName,
      'photoUrl': photoUrl,
      'coverUrl': coverUrl,
      'bio': bio,
      'friendsCount': friendsCount,
      'createdAt': Timestamp.fromDate(createdAt),
      'isOnline': isOnline,
      'lastSeen': lastSeen != null ? Timestamp.fromDate(lastSeen!) : null,
      'work': work,
      'education': education,
      'city': city,
      'relationship': relationship,
      'fcmToken': fcmToken,
      'privacy': privacy,
      'blockedUsers': blockedUsers,
    };
  }

  UserModel copyWith({
    String? displayName,
    String? photoUrl,
    String? coverUrl,
    String? bio,
    int? friendsCount,
    bool? isOnline,
    DateTime? lastSeen,
    String? work,
    String? education,
    String? city,
    String? relationship,
    String? privacy,
    List<String>? blockedUsers,
  }) {
    return UserModel(
      uid: uid,
      email: email,
      displayName: displayName ?? this.displayName,
      photoUrl: photoUrl ?? this.photoUrl,
      coverUrl: coverUrl ?? this.coverUrl,
      bio: bio ?? this.bio,
      friendsCount: friendsCount ?? this.friendsCount,
      createdAt: createdAt,
      isOnline: isOnline ?? this.isOnline,
      lastSeen: lastSeen ?? this.lastSeen,
      work: work ?? this.work,
      education: education ?? this.education,
      city: city ?? this.city,
      relationship: relationship ?? this.relationship,
      fcmToken: fcmToken,
      privacy: privacy ?? this.privacy,
      blockedUsers: blockedUsers ?? this.blockedUsers,
    );
  }
}
