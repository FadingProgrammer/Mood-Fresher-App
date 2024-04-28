import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:fluttertoast/fluttertoast.dart';

class FirebaseService {
  static Future<void> uploadPost({
    required File imageFile,
    required String uid,
    required String username,
    required String caption,
    String? location,
  }) async {
    try {
      String imageUrl = await uploadImage(imageFile,
          'post_image_${DateTime.now().millisecondsSinceEpoch}', "images");
      var postRef = await FirebaseFirestore.instance.collection('posts').add({
        'Image': imageUrl,
        'username': username,
        'caption': caption,
        'location': location ?? '',
        'likeCount': 0,
        'likedBy': [],
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

  static Future<String> uploadImage(
      File imageFile, String imageName, String category) async {
    try {
      Reference storageReference =
          FirebaseStorage.instance.ref().child('$category/$imageName');
      UploadTask uploadTask = storageReference.putFile(imageFile);
      TaskSnapshot taskSnapshot = await uploadTask;
      String imageUrl = await taskSnapshot.ref.getDownloadURL();
      return imageUrl;
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

  static Future<void> updateProfile(String displayName, String imageUrl) async {
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
        'posts': [],
        'likedPosts': [],
        'savedPosts': [],
      }, SetOptions(merge: true));
    } on FirebaseAuthException catch (e) {
      Fluttertoast.showToast(
          msg: e.message ?? e.toString(), gravity: ToastGravity.CENTER);
    }
  }

  static Future<UserCredential> loginWithGoogle() async {
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
      return Future.error(e);
    }
  }

  static Future<File> pickImage() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.image,
    );
    return File(result!.files.single.path!);
  }
}
