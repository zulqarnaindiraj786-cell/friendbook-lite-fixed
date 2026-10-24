import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/post_model.dart';
import 'notification_service.dart';
import 'auth_service.dart';

class PostService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final NotificationService _notificationService = NotificationService();

  Stream<List<PostModel>> getFeedPosts({DocumentSnapshot? lastDoc}) {
    Query query = _firestore
        .collection('posts')
        .orderBy('createdAt', descending: true)
        .limit(10);
    if (lastDoc != null) {
      query = query.startAfterDocument(lastDoc);
    }
    return query.snapshots().map((snapshot) =>
        snapshot.docs.map((doc) => PostModel.fromFirestore(doc)).toList());
  }

  Stream<List<PostModel>> getUserPosts(String uid) {
    return _firestore
        .collection('posts')
        .where('authorId', isEqualTo: uid)
        .orderBy('createdAt', descending: true)
        .limit(20)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => PostModel.fromFirestore(doc)).toList());
  }

  Stream<List<PostModel>> getSavedPosts(String uid) {
    return _firestore
        .collection('posts')
        .where('savedBy', arrayContains: uid)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => PostModel.fromFirestore(doc)).toList());
  }

  Future<List<PostModel>> getMorePosts({DocumentSnapshot? lastDoc}) async {
    Query query = _firestore
        .collection('posts')
        .orderBy('createdAt', descending: true)
        .limit(10);
    if (lastDoc != null) {
      query = query.startAfterDocument(lastDoc);
    }
    final snapshot = await query.get();
    return snapshot.docs.map((doc) => PostModel.fromFirestore(doc)).toList();
  }

  Future<DocumentSnapshot?> getLastDoc() async {
    final snapshot = await _firestore
        .collection('posts')
        .orderBy('createdAt', descending: true)
        .limit(10)
        .get();
    return snapshot.docs.isNotEmpty ? snapshot.docs.last : null;
  }

  Future<void> createPost({
    required String content,
    String? mediaUrl,
    String mediaType = 'none',
    String? feeling,
  }) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('Not authenticated');

    final auth = AuthService();
    final userModel = await auth.getCurrentUserModel();

    final post = PostModel(
      id: '',
      authorId: user.uid,
      authorName: userModel?.displayName ?? user.displayName ?? 'User',
      authorPhotoUrl: userModel?.photoUrl ?? '',
      content: content,
      mediaUrl: mediaUrl,
      mediaType: mediaType,
      feeling: feeling,
      likes: 0,
      comments: 0,
      createdAt: DateTime.now(),
    );
    await _firestore.collection('posts').add(post.toMap());
  }

  Future<void> editPost(String postId, String newContent) async {
    await _firestore.collection('posts').doc(postId).update({
      'content': newContent,
    });
  }

  Future<void> deletePost(String postId) async {
    final batch = _firestore.batch();
    batch.delete(_firestore.collection('posts').doc(postId));
    final comments = await _firestore
        .collection('comments')
        .where('postId', isEqualTo: postId)
        .get();
    for (final doc in comments.docs) {
      batch.delete(doc.reference);
    }
    final reactions = await _firestore
        .collection('posts')
        .doc(postId)
        .collection('reactions')
        .get();
    for (final doc in reactions.docs) {
      batch.delete(doc.reference);
    }
    await batch.commit();
  }

  Stream<List<Reaction>> getReactions(String postId) {
    return _firestore
        .collection('posts')
        .doc(postId)
        .collection('reactions')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Reaction.fromMap(doc.data()))
            .toList());
  }

  Future<void> setReaction(String postId, String type) async {
    final user = _auth.currentUser;
    if (user == null) return;
    final reactionRef = _firestore
        .collection('posts')
        .doc(postId)
        .collection('reactions')
        .doc(user.uid);

    final existing = await reactionRef.get();
    final batch = _firestore.batch();
    if (existing.exists) {
      final oldType = (existing.data() as Map<String, dynamic>)['type'] as String;
      if (oldType == type) {
        batch.delete(reactionRef);
        batch.update(_firestore.collection('posts').doc(postId),
            {'likes': FieldValue.increment(-1)});
      } else {
        batch.set(reactionRef, {
          'userId': user.uid,
          'type': type,
          'createdAt': FieldValue.serverTimestamp(),
        });
      }
    } else {
      batch.set(reactionRef, {
        'userId': user.uid,
        'type': type,
        'createdAt': FieldValue.serverTimestamp(),
      });
      batch.update(_firestore.collection('posts').doc(postId),
          {'likes': FieldValue.increment(1)});

      final postDoc = await _firestore.collection('posts').doc(postId).get();
      final authorId = (postDoc.data() as Map<String, dynamic>?)?['authorId'] as String?;
      if (authorId != null && authorId != user.uid) {
        final auth = AuthService();
        final userModel = await auth.getCurrentUserModel();
        batch.set(_firestore.collection('notifications').doc(), {
          'toUserId': authorId,
          'fromUserId': user.uid,
          'fromUserName': userModel?.displayName ?? 'Someone',
          'fromUserPhotoUrl': userModel?.photoUrl ?? '',
          'type': 'like',
          'postId': postId,
          'isRead': false,
          'createdAt': FieldValue.serverTimestamp(),
        });
      }
    }
    await batch.commit();
  }

  Future<void> removeReaction(String postId) async {
    final user = _auth.currentUser;
    if (user == null) return;
    final reactionRef = _firestore
        .collection('posts')
        .doc(postId)
        .collection('reactions')
        .doc(user.uid);
    final batch = _firestore.batch();
    batch.delete(reactionRef);
    batch.update(_firestore.collection('posts').doc(postId),
        {'likes': FieldValue.increment(-1)});
    await batch.commit();
  }

  Future<void> sharePost(String postId) async {
    final user = _auth.currentUser;
    if (user == null) return;
    final original = await _firestore.collection('posts').doc(postId).get();
    if (!original.exists) return;
    final data = original.data() as Map<String, dynamic>;
    final auth = AuthService();
    final userModel = await auth.getCurrentUserModel();

    final shared = PostModel(
      id: '',
      authorId: user.uid,
      authorName: userModel?.displayName ?? 'User',
      authorPhotoUrl: userModel?.photoUrl ?? '',
      content: data['content'] ?? '',
      mediaUrl: data['mediaUrl'],
      mediaType: data['mediaType'] ?? 'none',
      feeling: data['feeling'],
      likes: 0,
      comments: 0,
      createdAt: DateTime.now(),
      sharedFromId: postId,
    );
    await _firestore.collection('posts').add(shared.toMap());
    await _firestore.collection('posts').doc(postId).update({
      'shares': FieldValue.increment(1),
    });
  }

  Future<void> savePost(String postId) async {
    final user = _auth.currentUser;
    if (user == null) return;
    await _firestore.collection('posts').doc(postId).update({
      'savedBy': FieldValue.arrayUnion([user.uid]),
    });
  }

  Future<void> unsavePost(String postId) async {
    final user = _auth.currentUser;
    if (user == null) return;
    await _firestore.collection('posts').doc(postId).update({
      'savedBy': FieldValue.arrayRemove([user.uid]),
    });
  }

  Future<bool> isSaved(String postId) async {
    final user = _auth.currentUser;
    if (user == null) return false;
    final doc = await _firestore.collection('posts').doc(postId).get();
    final savedBy = List<String>.from(
        (doc.data() as Map<String, dynamic>?)?['savedBy'] ?? []);
    return savedBy.contains(user.uid);
  }
}
