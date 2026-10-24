import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'notification_service.dart';
import 'auth_service.dart';

class FriendService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final NotificationService _notificationService = NotificationService();

  Stream<List<String>> getFriendIds(String uid) {
    return _firestore
        .collection('friends')
        .where('participants', arrayContains: uid)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) {
              final data = doc.data();
              final participants = List<String>.from(data['participants'] ?? []);
              return participants.firstWhere((id) => id != uid, orElse: () => '');
            }).where((id) => id.isNotEmpty).toList());
  }

  Stream<QuerySnapshot> getFriendRequests(String uid) {
    return _firestore
        .collection('friend_requests')
        .where('toUid', isEqualTo: uid)
        .where('status', isEqualTo: 'pending')
        .snapshots();
  }

  Stream<List<Map<String, dynamic>>> getSentRequests(String uid) {
    return _firestore
        .collection('friend_requests')
        .where('fromUid', isEqualTo: uid)
        .where('status', isEqualTo: 'pending')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => {'id': doc.id, ...doc.data() as Map<String, dynamic>})
            .toList());
  }

  Future<void> sendFriendRequest(String toUid) async {
    final user = _auth.currentUser;
    if (user == null) return;

    final existing = await _firestore
        .collection('friend_requests')
        .where('fromUid', isEqualTo: user.uid)
        .where('toUid', isEqualTo: toUid)
        .get();
    if (existing.docs.isNotEmpty) return;

    final docRef = await _firestore.collection('friend_requests').add({
      'fromUid': user.uid,
      'toUid': toUid,
      'status': 'pending',
      'createdAt': FieldValue.serverTimestamp(),
    });

    final auth = AuthService();
    final userModel = await auth.getCurrentUserModel();
    await _notificationService.createNotification(
      toUserId: toUid,
      type: 'friend_request',
      text: 'sent you a friend request',
      extraData: {'requestId': docRef.id},
    );
  }

  Future<void> acceptFriendRequest(String requestId, String fromUid) async {
    final user = _auth.currentUser;
    if (user == null) return;
    final batch = _firestore.batch();
    batch.update(_firestore.collection('friend_requests').doc(requestId), {
      'status': 'accepted',
    });
    batch.set(_firestore.collection('friends').doc(), {
      'participants': [user.uid, fromUid],
      'createdAt': FieldValue.serverTimestamp(),
    });
    batch.set(_firestore.collection('users').doc(user.uid), {
      'friendsCount': FieldValue.increment(1),
    }, SetOptions(merge: true));
    batch.set(_firestore.collection('users').doc(fromUid), {
      'friendsCount': FieldValue.increment(1),
    }, SetOptions(merge: true));
    await batch.commit();

    await _notificationService.createNotification(
      toUserId: fromUid,
      type: 'friend_accept',
      text: 'accepted your friend request',
    );
  }

  Future<void> rejectFriendRequest(String requestId) async {
    await _firestore.collection('friend_requests').doc(requestId).delete();
  }

  Future<void> unfriend(String otherUid) async {
    final user = _auth.currentUser;
    if (user == null) return;
    final snapshot = await _firestore
        .collection('friends')
        .where('participants', arrayContains: user.uid)
        .get();
    for (final doc in snapshot.docs) {
      final participants = List<String>.from(doc['participants'] ?? []);
      if (participants.contains(otherUid)) {
        await doc.reference.delete();
        break;
      }
    }
    await _firestore.collection('users').doc(user.uid).update({
      'friendsCount': FieldValue.increment(-1),
    });
    await _firestore.collection('users').doc(otherUid).update({
      'friendsCount': FieldValue.increment(-1),
    });
  }

  Future<bool> areFriends(String uid1, String uid2) async {
    final snapshot = await _firestore
        .collection('friends')
        .where('participants', arrayContains: uid1)
        .get();
    for (final doc in snapshot.docs) {
      final participants = List<String>.from(doc['participants'] ?? []);
      if (participants.contains(uid2)) return true;
    }
    return false;
  }

  Future<bool> hasPendingRequest(String otherUid) async {
    final user = _auth.currentUser;
    if (user == null) return false;
    final snapshot = await _firestore
        .collection('friend_requests')
        .where('fromUid', isEqualTo: user.uid)
        .where('toUid', isEqualTo: otherUid)
        .where('status', isEqualTo: 'pending')
        .get();
    return snapshot.docs.isNotEmpty;
  }

  Stream<List<Map<String, dynamic>>> searchUsers(String query) {
    if (query.isEmpty) {
      return Stream.value([]);
    }
    final capitalized = query[0].toUpperCase() + query.substring(1).toLowerCase();
    return _firestore
        .collection('users')
        .where('displayName', isGreaterThanOrEqualTo: capitalized)
        .where('displayName', isLessThanOrEqualTo: '$capitalized\uf8ff')
        .limit(20)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => {'uid': doc.id, ...doc.data() as Map<String, dynamic>})
            .toList());
  }
}
