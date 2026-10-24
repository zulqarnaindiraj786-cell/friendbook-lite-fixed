import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/friend.dart';

class FriendService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Stream<List<FriendModel>> getAllUsers() {
    return _firestore.collection('users').limit(50).snapshots().map((snapshot) {
      final currentUid = _auth.currentUser?.uid;
      return snapshot.docs
          .where((doc) => doc.id != currentUid)
          .map((doc) => FriendModel.fromFirestore(doc))
          .toList();
    });
  }

  Future<void> sendFriendRequest(String toUid) async {
    final user = _auth.currentUser;
    if (user == null) return;
    await _firestore.collection('friend_requests').add({
      'fromUid': user.uid,
      'toUid': toUid,
      'status': 'pending',
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> acceptFriendRequest(String requestId, String fromUid) async {
    final user = _auth.currentUser;
    if (user == null) return;
    final batch = _firestore.batch();
    batch.update(_firestore.collection('friend_requests').doc(requestId), {
      'status': 'accepted',
    });
    batch.set(_firestore.collection('friends').doc(), {
      'uid1': user.uid,
      'uid2': fromUid,
      'createdAt': FieldValue.serverTimestamp(),
    });
    batch.set(_firestore.collection('users').doc(user.uid), {
      'friendsCount': FieldValue.increment(1),
    }, SetOptions(merge: true));
    batch.set(_firestore.collection('users').doc(fromUid), {
      'friendsCount': FieldValue.increment(1),
    }, SetOptions(merge: true));
    await batch.commit();
  }
}
