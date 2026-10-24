import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/message_model.dart';

class NotificationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Stream<List<NotificationModel>> getNotifications() {
    final user = _auth.currentUser;
    if (user == null) return Stream.value([]);
    return _firestore
        .collection('notifications')
        .where('toUserId', isEqualTo: user.uid)
        .orderBy('createdAt', descending: true)
        .limit(50)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => NotificationModel.fromFirestore(doc))
            .toList());
  }

  Future<void> createNotification({
    required String toUserId,
    required String type,
    String? postId,
    String? text,
    Map<String, dynamic>? extraData,
  }) async {
    final user = _auth.currentUser;
    if (user == null) return;

    final notification = NotificationModel(
      id: '',
      toUserId: toUserId,
      fromUserId: user.uid,
      fromUserName: _auth.currentUser?.displayName ?? 'Someone',
      fromUserPhotoUrl: _auth.currentUser?.photoURL ?? '',
      type: type,
      postId: postId,
      text: text,
      isRead: false,
      createdAt: DateTime.now(),
    );
    final data = notification.toMap();
    if (extraData != null) data.addAll(extraData);
    await _firestore.collection('notifications').add(data);
  }

  Future<void> markAllAsRead() async {
    final user = _auth.currentUser;
    if (user == null) return;
    final snapshot = await _firestore
        .collection('notifications')
        .where('toUserId', isEqualTo: user.uid)
        .where('isRead', isEqualTo: false)
        .get();
    final batch = _firestore.batch();
    for (final doc in snapshot.docs) {
      batch.update(doc.reference, {'isRead': true});
    }
    await batch.commit();
  }

  Future<int> getUnreadCount() async {
    final user = _auth.currentUser;
    if (user == null) return 0;
    final snapshot = await _firestore
        .collection('notifications')
        .where('toUserId', isEqualTo: user.uid)
        .where('isRead', isEqualTo: false)
        .get();
    return snapshot.docs.length;
  }
}
