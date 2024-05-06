import 'package:file_picker/file_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:mood_fresher/firebase/firebase.dart';
import 'package:mood_fresher/modal/fileResult.dart';
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
  final TextEditingController _bioController = TextEditingController();
  FileResult? result;
  String _errorText = '';
  bool isfinishing = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Center(child: Text('Profile Setup')),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              CircleAvatar(
                radius: 80,
                backgroundImage: result != null
                    ? FileImage(result!.file) as ImageProvider
                    : const NetworkImage(profilePlaceholder),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () async {
                  result = await FirebaseService.pickFile(FileType.image);
                  setState(() {});
                },
                child: const Text('Select Profile Picture'),
              ),
              const SizedBox(height: 16),
              Form(
                key: key,
                child: Column(
                  children: [
                    textField('Display Name', _displayNameController,
                        isRequired: true),
                    const SizedBox(height: 16),
                    textField('Bio', _bioController)
                  ],
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
                    ? const CircularProgressIndicator()
                    : const Text('Finish'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget textField(String label, TextEditingController controller,
      {bool isRequired = false}) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
      ),
      validator: (value) {
        if (isRequired && (value == null || value.isEmpty)) {
          return 'Enter $label';
        }
        return null;
      },
    );
  }

  Future<void> finishing() async {
    if (key.currentState?.validate() ?? false) {
      setState(() {
        isfinishing = true;
        _errorText = '';
      });
      String selectedImage = '';
      if (result != null) {
        selectedImage = await FirebaseService.uploadFile(result!.file,
            '${widget.currentUser.uid}.${result!.extension}', "profile");
      }
      selectedImage =
          selectedImage.isNotEmpty ? selectedImage : profilePlaceholder;
      String username = _displayNameController.text.trim();
      await FirebaseService.updateProfile(
              username, selectedImage, _bioController.text)
          .then((value) => Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) => HomeScreen(
                      uid: widget.currentUser.uid,
                      username: username,
                      photoURL: selectedImage),
                ),
              ));
    }
  }
}
