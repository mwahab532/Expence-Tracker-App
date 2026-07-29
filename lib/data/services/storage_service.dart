import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:uuid/uuid.dart';

class StorageService {
  final FirebaseStorage _storage;
  StorageService({FirebaseStorage? storage}) : _storage = storage ?? FirebaseStorage.instance;

  Future<String> uploadFile({
    required File file,
    required String folder,
    required String uid,
  }) async {
    final fileName = '${const Uuid().v4()}${_extensionOf(file.path)}';
    final ref = _storage.ref().child(folder).child(uid).child(fileName);
    final task = await ref.putFile(file);
    return task.ref.getDownloadURL();
  }

  Future<void> deleteFileByUrl(String url) async {
    await _storage.refFromURL(url).delete();
  }

  String _extensionOf(String path) {
    final i = path.lastIndexOf('.');
    return i == -1 ? '.jpg' : path.substring(i);
  }
}
