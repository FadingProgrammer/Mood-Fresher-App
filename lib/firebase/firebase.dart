import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:mood_fresher/firebase/notification.dart';
import 'package:mood_fresher/modal/fileResult.dart';

class FirebaseService {
  static Future<void> uploadPost(
      {required FileResult result,
      required String uid,
      required String username,
      required String userImage,
      required String caption,
      String? location}) async {
    try {
      String fileUrl = await uploadFile(
          result.file,
          'post_${DateTime.now().millisecondsSinceEpoch}.${result.extension}',
          "posts");

      var postRef = await FirebaseFirestore.instance.collection('posts').add({
        'fileUrl': fileUrl,
        'fileType': result.type.toString(),
        'username': username,
        'userImage': userImage,
        'caption': caption,
        'location': location ?? '',
        'likeCount': 0,
        'likedBy': [],
        'savedBy': [],
        'comments': [],
        'timestamp': FieldValue.serverTimestamp(),
      });

      await FirebaseFirestore.instance.collection('users').doc(uid).update({
        'posts': FieldValue.arrayUnion([postRef.id]),
      });
    } catch (e) {
      Fluttertoast.showToast(msg: e.toString(), gravity: ToastGravity.CENTER);
    }
  }

  static Future<String> uploadFile(
      File file, String fileName, String category) async {
    try {
      Reference storageReference =
          FirebaseStorage.instance.ref().child('$category/$fileName');
      UploadTask uploadTask = storageReference.putFile(file);
      TaskSnapshot taskSnapshot = await uploadTask;
      String fileUrl = await taskSnapshot.ref.getDownloadURL();
      return fileUrl;
    } catch (e) {
      Fluttertoast.showToast(msg: e.toString(), gravity: ToastGravity.CENTER);
      rethrow;
    }
  }

  static Future<bool> signUp(String email, String password) async {
    try {
      await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      return true;
    } on FirebaseAuthException catch (e) {
      Fluttertoast.showToast(
          msg: e.message ?? e.toString(), gravity: ToastGravity.CENTER);
      return false;
    }
  }

  static Future<bool> signIn(String email, String password) async {
    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return true;
    } on FirebaseAuthException catch (e) {
      Fluttertoast.showToast(
          msg: e.message ?? e.toString(), gravity: ToastGravity.CENTER);
      return false;
    }
  }

  static Future<void> updateProfile(
      String displayName, String imageUrl, String bio) async {
    try {
      User? currentUser = FirebaseAuth.instance.currentUser;
      await currentUser?.updateDisplayName(displayName);
      await currentUser?.updatePhotoURL(imageUrl);
      await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser!.uid)
          .set({
        'Name': displayName,
        'Image': imageUrl,
        'email': currentUser.email,
        'bio': bio,
        'token': await NotificationServices().getToken(),
        'posts': [],
        'likedPosts': [],
        'savedPosts': [],
      }, SetOptions(merge: true));
    } on FirebaseAuthException catch (e) {
      Fluttertoast.showToast(
          msg: e.message ?? e.toString(), gravity: ToastGravity.CENTER);
    }
  }

  static Future<UserCredential?> loginWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();
      final GoogleSignInAuthentication googleAuth =
          await googleUser!.authentication;
      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );
      return await FirebaseAuth.instance.signInWithCredential(credential);
    } on FirebaseAuthException catch (e) {
      Fluttertoast.showToast(
          msg: e.message ?? e.toString(), gravity: ToastGravity.CENTER);
      return null;
    }
  }

  static Future<FileResult?> pickFile(FileType type) async {
    var extensions = type == FileType.image
        ? ['jpg', 'jpeg', 'png']
        : type == FileType.media
            ? ['jpg', 'jpeg', 'png', 'mp4', 'mov', 'avi']
            : ['pdf', 'doc', 'docx', 'ppt', 'pptx', 'xls', 'xlsx', 'txt'];
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: extensions,
    );
    if (result != null) {
      String? filePath = result.files.single.path;
      if (filePath != null) {
        String extension = filePath.split('.').last.toLowerCase();
        if (type == FileType.media) type = _getFileType(extension);
        if (type != FileType.any) {
          return FileResult(File(filePath), type, extension);
        }
      }
    }
    return null;
  }

  static FileType _getFileType(String extension) {
    if (extension == 'jpg' || extension == 'jpeg' || extension == 'png') {
      return FileType.image;
    } else if (extension == 'mp4' || extension == 'mov' || extension == 'avi') {
      return FileType.video;
    } else {
      return FileType.any;
    }
  }
}
