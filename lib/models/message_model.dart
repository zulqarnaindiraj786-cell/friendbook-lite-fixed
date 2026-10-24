import 'package:cloud_firestore/cloud_firestore.dart';

class MessageModel {
  final String id;
  final String senderId;
  final String receiverId;
  final String text;
  final String? imageUrl;
  final String type; // text | image
  final bool isSeen;
  final DateTime createdAt;

  MessageModel({
    required this.id,
    required this.senderId,
    required this.receiverId,
    this.text = '',
    this.imageUrl,
    this.type = 'text',
    this.isSeen = false,
    required this.createdAt,
  });

  factory MessageModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return MessageModel(
      id: doc.id,
      senderId: data['senderId'] ?? '',
      receiverId: data['receiverId'] ?? '',
      text: data['text'] ?? '',
      imageUrl: data['imageUrl'] as String?,
      type: data['type'] ?? 'text',
      isSeen: data['isSeen'] ?? false,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'senderId': senderId,
      'receiverId': receiverId,
      'text': text,
      'imageUrl': imageUrl,
      'type': type,
      'isSeen': isSeen,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}

class ChatRoom {
  final String id;
  final List<String> participants;
  final String lastMessage;
  final DateTime lastMessageTime;
  final Map<String, bool> typing;
  final Map<String, DateTime> lastSeen;

  ChatRoom({
    required this.id,
    required this.participants,
    this.lastMessage = '',
    required this.lastMessageTime,
    this.typing = const {},
    this.lastSeen = const {},
  });

  factory ChatRoom.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ChatRoom(
      id: doc.id,
      participants: List<String>.from(data['participants'] ?? []),
      lastMessage: data['lastMessage'] ?? '',
      lastMessageTime: (data['lastMessageTime'] as Timestamp?)?.toDate() ??
          DateTime.now(),
      typing: Map<String, bool>.from(data['typing'] ?? {}),
      lastSeen: (data['lastSeen'] as Map<String, dynamic>?)?.map(
              (k, v) => MapEntry(k, (v as Timestamp).toDate())) ??
          {},
    );
  }
}

class NotificationModel {
  final String id;
  final String toUserId;
  final String fromUserId;
  final String fromUserName;
  final String fromUserPhotoUrl;
  final String type; // like | comment | friend_request | friend_accept | message | story
  final String? postId;
  final String? text;
  final bool isRead;
  final DateTime createdAt;

  NotificationModel({
    required this.id,
    required this.toUserId,
    required this.fromUserId,
    required this.fromUserName,
    this.fromUserPhotoUrl = '',
    required this.type,
    this.postId,
    this.text,
    this.isRead = false,
    required this.createdAt,
  });

  factory NotificationModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return NotificationModel(
      id: doc.id,
      toUserId: data['toUserId'] ?? '',
      fromUserId: data['fromUserId'] ?? '',
      fromUserName: data['fromUserName'] ?? 'Someone',
      fromUserPhotoUrl: data['fromUserPhotoUrl'] ?? '',
      type: data['type'] ?? 'like',
      postId: data['postId'] as String?,
      text: data['text'] as String?,
      isRead: data['isRead'] ?? false,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'toUserId': toUserId,
      'fromUserId': fromUserId,
      'fromUserName': fromUserName,
      'fromUserPhotoUrl': fromUserPhotoUrl,
      'type': type,
      'postId': postId,
      'text': text,
      'isRead': isRead,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}
