import 'dart:io';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:mood_fresher/firebase/firebase.dart';

class UploadPostScreen extends StatefulWidget {
  final String uid;
  final String username;
  const UploadPostScreen(
      {super.key, required this.uid, required this.username});

  @override
  State<UploadPostScreen> createState() => UploadPostScreenState();
}

class UploadPostScreenState extends State<UploadPostScreen> {
  TextEditingController captionController = TextEditingController();
  TextEditingController locationController = TextEditingController();
  GlobalKey<FormState> key = GlobalKey();
  File? image;
  bool isUploading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Center(child: Text('Post')),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: key,
            child: Column(
              children: [
                Container(
                  height: MediaQuery.of(context).size.height * 0.4,
                  decoration: BoxDecoration(
                    color: Theme.of(context).canvasColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: image != null
                      ? Image.file(image!)
                      : Center(
                          child: TextButton(
                            onPressed: () async {
                              image = await FirebaseService.pickImage();
                              setState(() {});
                            },
                            child: const Text(
                              "Choose an Image",
                            ),
                          ),
                        ),
                ),
                const SizedBox(height: 16),
                textField("Caption", captionController, isRequired: true),
                const SizedBox(height: 16),
                textField("Location", locationController),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: isUploading
                      ? null
                      : () async {
                          if (key.currentState?.validate() ?? false) {
                            if (image != null) {
                              setState(() {
                                isUploading = true;
                              });
                              await FirebaseService.uploadPost(
                                      imageFile: image!,
                                      uid: widget.uid,
                                      username: widget.username,
                                      caption: captionController.text,
                                      location: locationController.text)
                                  .then((value) => setState(() {
                                        isUploading = false;
                                        captionController.clear();
                                        locationController.clear();
                                        image = null;
                                      }));
                            } else {
                              Fluttertoast.showToast(
                                  msg: "Please choose an image.",
                                  gravity: ToastGravity.CENTER);
                            }
                          }
                        },
                  child: SizedBox(
                    width: double.infinity,
                    child: isUploading
                        ? const Center(child: CircularProgressIndicator())
                        : const Center(
                            child: Text('Upload Post'),
                          ),
                  ),
                ),
              ],
            ),
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
          return '';
        }
        return null;
      },
    );
  }
}
