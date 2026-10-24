import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/comment_model.dart';
import 'notification_service.dart';
import 'auth_service.dart';

class CommentService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final NotificationService _notificationService = NotificationService();

  Stream<List<CommentModel>> getComments(String postId) {
    return _firestore
        .collection('comments')
        .where('postId', isEqualTo: postId)
        .orderBy('createdAt', descending: false)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => CommentModel.fromFirestore(doc)).toList());
  }

  Future<void> addComment({
    required String postId,
    required String content,
    String? imageUrl,
    String? parentId,
  }) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('Not authenticated');

    final auth = AuthService();
    final userModel = await auth.getCurrentUserModel();

    final comment = CommentModel(
      id: '',
      postId: postId,
      authorId: user.uid,
      authorName: userModel?.displayName ?? 'User',
      authorPhotoUrl: userModel?.photoUrl ?? '',
      content: content,
      imageUrl: imageUrl,
      parentId: parentId,
      createdAt: DateTime.now(),
    );
    await _firestore.collection('comments').add(comment.toMap());
    await _firestore.collection('posts').doc(postId).update({
      'comments': FieldValue.increment(1),
    });

    final postDoc = await _firestore.collection('posts').doc(postId).get();
    final authorId = (postDoc.data() as Map<String, dynamic>?)?['authorId'] as String?;
    if (authorId != null && authorId != user.uid) {
      await _notificationService.createNotification(
        toUserId: authorId,
        type: 'comment',
        postId: postId,
        text: content,
      );
    }
  }

  Future<void> deleteComment(String commentId, String postId) async {
    await _firestore.collection('comments').doc(commentId).delete();
    await _firestore.collection('posts').doc(postId).update({
      'comments': FieldValue.increment(-1),
    });
  }

  Future<void> likeComment(String commentId) async {
    await _firestore.collection('comments').doc(commentId).update({
      'likes': FieldValue.increment(1),
    });
  }

  Future<void> unlikeComment(String commentId) async {
    await _firestore.collection('comments').doc(commentId).update({
      'likes': FieldValue.increment(-1),
    });
  }
}
