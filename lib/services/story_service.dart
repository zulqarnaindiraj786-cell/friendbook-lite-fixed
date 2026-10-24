import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/story_model.dart';
import 'auth_service.dart';

class StoryService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Stream<List<StoryModel>> getActiveStories() {
    final now = DateTime.now();
    return _firestore
        .collection('stories')
        .where('expiresAt', isGreaterThan: Timestamp.fromDate(now))
        .orderBy('expiresAt', descending: false)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => StoryModel.fromFirestore(doc))
            .toList());
  }

  Stream<List<StoryModel>> getUserStories(String uid) {
    final now = DateTime.now();
    return _firestore
        .collection('stories')
        .where('authorId', isEqualTo: uid)
        .where('expiresAt', isGreaterThan: Timestamp.fromDate(now))
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => StoryModel.fromFirestore(doc))
            .toList());
  }

  Future<void> createStory({
    String? mediaUrl,
    String mediaType = 'image',
    String? caption,
  }) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('Not authenticated');
    final auth = AuthService();
    final userModel = await auth.getCurrentUserModel();

    final now = DateTime.now();
    final story = StoryModel(
      id: '',
      authorId: user.uid,
      authorName: userModel?.displayName ?? 'User',
      authorPhotoUrl: userModel?.photoUrl ?? '',
      mediaUrl: mediaUrl,
      mediaType: mediaType,
      caption: caption,
      createdAt: now,
      expiresAt: now.add(const Duration(hours: 24)),
    );
    await _firestore.collection('stories').add(story.toMap());
  }

  Future<void> deleteStory(String storyId) async {
    await _firestore.collection('stories').doc(storyId).delete();
  }

  Future<void> markViewed(String storyId) async {
    final user = _auth.currentUser;
    if (user == null) return;
    await _firestore.collection('stories').doc(storyId).update({
      'viewedBy': FieldValue.arrayUnion([user.uid]),
    });
  }
}
