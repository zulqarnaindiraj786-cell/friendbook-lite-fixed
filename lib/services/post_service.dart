import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/post_model.dart';

class PostService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Stream<List<PostModel>> getPosts() {
    return _firestore
        .collection('posts')
        .orderBy('createdAt', descending: true)
        .limit(50)
        .snapshots()
        .map((snapshot) =>
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

  Future<void> createPost({
    required String content,
    String? imageUrl,
  }) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('Not authenticated');

    final post = PostModel(
      id: '',
      authorId: user.uid,
      authorName: user.displayName ?? 'User',
      content: content,
      imageUrl: imageUrl,
      likes: 0,
      comments: 0,
      createdAt: DateTime.now(),
    );

    await _firestore.collection('posts').add(post.toMap());
  }

  Future<void> likePost(String postId) async {
    final user = _auth.currentUser;
    if (user == null) return;
    final likeRef = _firestore
        .collection('posts')
        .doc(postId)
        .collection('likes')
        .doc(user.uid);

    final batch = _firestore.batch();
    batch.set(likeRef, {'userId': user.uid, 'createdAt': FieldValue.serverTimestamp()});
    batch.update(_firestore.collection('posts').doc(postId), {
      'likes': FieldValue.increment(1),
    });
    await batch.commit();
  }

  Future<void> unlikePost(String postId) async {
    final user = _auth.currentUser;
    if (user == null) return;
    final likeRef = _firestore
        .collection('posts')
        .doc(postId)
        .collection('likes')
        .doc(user.uid);

    final batch = _firestore.batch();
    batch.delete(likeRef);
    batch.update(_firestore.collection('posts').doc(postId), {
      'likes': FieldValue.increment(-1),
    });
    await batch.commit();
  }

  Future<void> deletePost(String postId) async {
    await _firestore.collection('posts').doc(postId).delete();
  }
}
