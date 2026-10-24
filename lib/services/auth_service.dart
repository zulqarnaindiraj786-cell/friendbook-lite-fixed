import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../models/user_model.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  User? get currentUser => _auth.currentUser;
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  Future<UserModel?> signUp({
    required String email,
    required String password,
    required String displayName,
    String? photoUrl,
  }) async {
    final credential = await _auth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
    final user = credential.user;
    if (user == null) return null;

    final userModel = UserModel(
      uid: user.uid,
      email: email.trim(),
      displayName: displayName.trim(),
      photoUrl: photoUrl,
      createdAt: DateTime.now(),
    );

    await _firestore.collection('users').doc(user.uid).set(userModel.toMap());
    await user.updateDisplayName(displayName.trim());
    if (photoUrl != null) await user.updatePhotoURL(photoUrl);

    await _setOnlineStatus(true);
    return userModel;
  }

  Future<UserModel?> signIn({
    required String email,
    required String password,
  }) async {
    final credential = await _auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
    final user = credential.user;
    if (user == null) return null;

    final doc = await _firestore.collection('users').doc(user.uid).get();
    await _setOnlineStatus(true);
    if (doc.exists) return UserModel.fromFirestore(doc);
    return null;
  }

  Future<UserModel?> signInWithGoogle() async {
    final googleUser = await _googleSignIn.signIn();
    if (googleUser == null) return null;

    final googleAuth = await googleUser.authentication;
    final credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );

    final userCredential = await _auth.signInWithCredential(credential);
    final user = userCredential.user;
    if (user == null) return null;

    final docRef = _firestore.collection('users').doc(user.uid);
    final doc = await docRef.get();
    if (!doc.exists) {
      final userModel = UserModel(
        uid: user.uid,
        email: user.email ?? '',
        displayName: user.displayName ?? 'User',
        photoUrl: user.photoURL,
        createdAt: DateTime.now(),
      );
      await docRef.set(userModel.toMap());
    }
    await _setOnlineStatus(true);
    return UserModel.fromFirestore(await docRef.get());
  }

  Future<void> resetPassword(String email) async {
    await _auth.sendPasswordResetEmail(email: email.trim());
  }

  Future<void> signOut() async {
    await _setOnlineStatus(false);
    try {
      await _googleSignIn.signOut();
    } catch (_) {}
    await _auth.signOut();
  }

  Future<void> changePassword(String newPassword) async {
    final user = _auth.currentUser;
    if (user == null) return;
    await user.updatePassword(newPassword);
  }

  Future<UserModel?> getCurrentUserModel() async {
    final user = _auth.currentUser;
    if (user == null) return null;
    final doc = await _firestore.collection('users').doc(user.uid).get();
    if (doc.exists) return UserModel.fromFirestore(doc);
    return null;
  }

  Stream<UserModel> userStream(String uid) {
    return _firestore.collection('users').doc(uid).snapshots().map(
        (doc) => UserModel.fromFirestore(doc));
  }

  Stream<QuerySnapshot> userCollectionStream() {
    return _firestore.collection('users').limit(50).snapshots();
  }

  Future<void> updateProfile({
    required String displayName,
    String? bio,
    String? photoUrl,
    String? coverUrl,
    String? work,
    String? education,
    String? city,
    String? relationship,
    String? privacy,
  }) async {
    final user = _auth.currentUser;
    if (user == null) return;
    final updates = <String, dynamic>{'displayName': displayName};
    if (bio != null) updates['bio'] = bio;
    if (photoUrl != null) updates['photoUrl'] = photoUrl;
    if (coverUrl != null) updates['coverUrl'] = coverUrl;
    if (work != null) updates['work'] = work;
    if (education != null) updates['education'] = education;
    if (city != null) updates['city'] = city;
    if (relationship != null) updates['relationship'] = relationship;
    if (privacy != null) updates['privacy'] = privacy;
    await _firestore.collection('users').doc(user.uid).update(updates);
    await user.updateDisplayName(displayName);
    if (photoUrl != null) await user.updatePhotoURL(photoUrl);
  }

  Future<void> blockUser(String otherUid) async {
    final user = _auth.currentUser;
    if (user == null) return;
    await _firestore.collection('users').doc(user.uid).update({
      'blockedUsers': FieldValue.arrayUnion([otherUid]),
    });
  }

  Future<void> unblockUser(String otherUid) async {
    final user = _auth.currentUser;
    if (user == null) return;
    await _firestore.collection('users').doc(user.uid).update({
      'blockedUsers': FieldValue.arrayRemove([otherUid]),
    });
  }

  Future<void> deleteAccount() async {
    final user = _auth.currentUser;
    if (user == null) return;
    await _firestore.collection('users').doc(user.uid).delete();
    await user.delete();
  }

  Future<void> _setOnlineStatus(bool isOnline) async {
    final user = _auth.currentUser;
    if (user == null) return;
    await _firestore.collection('users').doc(user.uid).update({
      'isOnline': isOnline,
      'lastSeen': FieldValue.serverTimestamp(),
    });
  }

  Future<void> setOnline() => _setOnlineStatus(true);
  Future<void> setOffline() => _setOnlineStatus(false);
}
