import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:mood_fresher/firebase/firebase.dart';
import 'package:mood_fresher/screens/home.dart';
import 'package:mood_fresher/utils/constants.dart';

class ProfileSetupScreen extends StatefulWidget {
  final User currentUser;
  const ProfileSetupScreen({super.key, required this.currentUser});

  @override
  ProfileSetupScreenState createState() => ProfileSetupScreenState();
}

class ProfileSetupScreenState extends State<ProfileSetupScreen> {
  final GlobalKey<FormState> key = GlobalKey<FormState>();
  final TextEditingController _displayNameController = TextEditingController();
  String selectedImage = '';
  String _errorText = '';
  bool isUploading = false;
  bool isfinishing = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile Setup'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircleAvatar(
              radius: 80,
              backgroundImage: selectedImage.isNotEmpty
                  ? NetworkImage(selectedImage)
                  : const NetworkImage(profilePlaceholder),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: update,
              child: isUploading
                  ? const Center(child: CircularProgressIndicator())
                  : const Text('Select Profile Picture'),
            ),
            const SizedBox(height: 16),
            Form(
              key: key,
              child: TextFormField(
                controller: _displayNameController,
                decoration: const InputDecoration(
                  labelText: 'Display Name',
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Enter Display Name';
                  }
                  return null;
                },
              ),
            ),
            if (_errorText.isNotEmpty)
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text(
                  _errorText,
                  style: const TextStyle(color: Colors.red),
                ),
              ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: finishing,
              child: isfinishing
                  ? const Center(child: CircularProgressIndicator())
                  : const Text('Finish'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> update() async {
    isUploading = true;
    selectedImage = await FirebaseService.uploadImage(
        await FirebaseService.pickImage(),
        "${widget.currentUser.uid}.jpg",
        "profile");
    setState(() {
      isUploading = false;
    });
  }

  Future<void> finishing() async {
    if (key.currentState!.validate() && !isUploading) {
      setState(() {
        isfinishing = true;
        _errorText = '';
      });
      await FirebaseService.updateProfile(_displayNameController.text.trim(),
              selectedImage.isNotEmpty ? selectedImage : profilePlaceholder)
          .then((value) => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      HomeScreen(currentUser: widget.currentUser),
                ),
              ));

      setState(() {
        isfinishing = false;
      });
    }
  }
}
