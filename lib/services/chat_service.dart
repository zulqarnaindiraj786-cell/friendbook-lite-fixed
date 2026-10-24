import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/message_model.dart';
import 'auth_service.dart';

class ChatService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String getChatId(String uid1, String uid2) {
    final ids = [uid1, uid2]..sort();
    return ids.join('_');
  }

  Stream<List<ChatRoom>> getChatRooms() {
    final user = _auth.currentUser;
    if (user == null) return Stream.value([]);
    return _firestore
        .collection('chats')
        .where('participants', arrayContains: user.uid)
        .orderBy('lastMessageTime', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => ChatRoom.fromFirestore(doc))
            .toList());
  }

  Stream<List<MessageModel>> getMessages(String chatId) {
    return _firestore
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .orderBy('createdAt', descending: false)
        .limit(100)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => MessageModel.fromFirestore(doc))
            .toList());
  }

  Future<void> sendMessage({
    required String receiverId,
    String text = '',
    String? imageUrl,
    String type = 'text',
  }) async {
    final user = _auth.currentUser;
    if (user == null) return;
    final chatId = getChatId(user.uid, receiverId);
    final message = MessageModel(
      id: '',
      senderId: user.uid,
      receiverId: receiverId,
      text: text,
      imageUrl: imageUrl,
      type: type,
      isSeen: false,
      createdAt: DateTime.now(),
    );

    final batch = _firestore.batch();
    batch.set(
        _firestore.collection('chats').doc(chatId).collection('messages').doc(),
        message.toMap());
    batch.set(_firestore.collection('chats').doc(chatId), {
      'participants': [user.uid, receiverId],
      'lastMessage': type == 'image' ? '📷 Photo' : text,
      'lastMessageTime': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
    await batch.commit();
  }

  Future<void> markAsSeen(String chatId) async {
    final user = _auth.currentUser;
    if (user == null) return;
    final snapshot = await _firestore
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .where('receiverId', isEqualTo: user.uid)
        .where('isSeen', isEqualTo: false)
        .get();
    final batch = _firestore.batch();
    for (final doc in snapshot.docs) {
      batch.update(doc.reference, {'isSeen': true});
    }
    await batch.commit();
  }

  Future<void> setTyping(String chatId, bool isTyping) async {
    final user = _auth.currentUser;
    if (user == null) return;
    await _firestore.collection('chats').doc(chatId).set({
      'typing': {user.uid: isTyping},
    }, SetOptions(merge: true));
  }

  Future<int> getUnreadCount() async {
    final user = _auth.currentUser;
    if (user == null) return 0;
    final rooms = await _firestore
        .collection('chats')
        .where('participants', arrayContains: user.uid)
        .get();
    int count = 0;
    for (final room in rooms.docs) {
      final messages = await room.reference
          .collection('messages')
          .where('receiverId', isEqualTo: user.uid)
          .where('isSeen', isEqualTo: false)
          .get();
      count += messages.docs.length;
    }
    return count;
  }
}
