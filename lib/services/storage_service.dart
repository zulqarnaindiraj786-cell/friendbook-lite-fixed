import 'package:firebase_storage/firebase_storage.dart';
import 'package:uuid/uuid.dart';

class StorageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final _uuid = const Uuid();

  Future<String> uploadProfilePhoto(String uid, String filePath) async {
    final ref = _storage.ref().child('profiles/$uid/${_uuid.v4()}.jpg');
    await ref.putFile(filePath);
    return ref.getDownloadURL();
  }

  Future<String> uploadCoverPhoto(String uid, String filePath) async {
    final ref = _storage.ref().child('covers/$uid/${_uuid.v4()}.jpg');
    await ref.putFile(filePath);
    return ref.getDownloadURL();
  }

  Future<String> uploadPostMedia(String uid, String filePath, String type) async {
    final ext = type == 'video' ? 'mp4' : 'jpg';
    final ref = _storage.ref().child('posts/$uid/${_uuid.v4()}.$ext');
    await ref.putFile(filePath);
    return ref.getDownloadURL();
  }

  Future<String> uploadStoryMedia(String uid, String filePath, String type) async {
    final ext = type == 'video' ? 'mp4' : 'jpg';
    final ref = _storage.ref().child('stories/$uid/${_uuid.v4()}.$ext');
    await ref.putFile(filePath);
    return ref.getDownloadURL();
  }

  Future<String> uploadChatImage(String chatId, String filePath) async {
    final ref = _storage.ref().child('chats/$chatId/${_uuid.v4()}.jpg');
    await ref.putFile(filePath);
    return ref.getDownloadURL();
  }

  Future<String> uploadCommentImage(String postId, String filePath) async {
    final ref = _storage.ref().child('comments/$postId/${_uuid.v4()}.jpg');
    await ref.putFile(filePath);
    return ref.getDownloadURL();
  }
}
