import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:mood_fresher/firebase/firebase.dart';
import 'package:mood_fresher/modal/fileResult.dart';
import 'package:mood_fresher/widgets/mediaplayer.dart';

class UploadPostScreen extends StatefulWidget {
  final String uid;
  final String username;
  final String photoURL;
  const UploadPostScreen(
      {super.key,
      required this.uid,
      required this.username,
      required this.photoURL});

  @override
  State<UploadPostScreen> createState() => UploadPostScreenState();
}

class UploadPostScreenState extends State<UploadPostScreen> {
  TextEditingController captionController = TextEditingController();
  TextEditingController locationController = TextEditingController();
  GlobalKey<FormState> key = GlobalKey();
  FileResult? result;
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
                  child: result != null
                      ? _buildMediaWidget()
                      : Center(
                          child: TextButton(
                            onPressed: () async {
                              result = await FirebaseService.pickFile(
                                  FileType.media);
                              setState(() {});
                            },
                            child: const Text(
                              "Choose File",
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
                            if (result != null) {
                              setState(() {
                                isUploading = true;
                              });
                              await FirebaseService.uploadPost(
                                      result: result!,
                                      uid: widget.uid,
                                      username: widget.username,
                                      userImage: widget.photoURL,
                                      caption: captionController.text,
                                      location: locationController.text)
                                  .then((value) => setState(() {
                                        isUploading = false;
                                        captionController.clear();
                                        locationController.clear();
                                        result = null;
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

  Widget _buildMediaWidget() {
    if (result!.type == FileType.image) {
      return Image.file(result!.file, fit: BoxFit.cover);
    } else if (result!.type == FileType.video) {
      return MediaPlayer.fileVideo(result!.file, autoPlay: true);
    } else {
      return Container(color: Colors.grey);
    }
  }

  Widget textField(String label, TextEditingController controller,
      {bool isRequired = false}) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(labelText: label),
      validator: (value) {
        if (isRequired && (value == null || value.isEmpty)) {
          return '';
        }
        return null;
      },
    );
  }
}
