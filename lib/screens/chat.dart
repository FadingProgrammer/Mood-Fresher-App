import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:mood_fresher/firebase/firebase.dart';
import 'package:mood_fresher/firebase/notification.dart';
import 'package:mood_fresher/modal/fileResult.dart';
import 'package:mood_fresher/modal/message.dart';
import 'package:mood_fresher/widgets/mediaplayer.dart';
import 'package:photo_view/photo_view.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:path_provider/path_provider.dart';
import 'package:open_file/open_file.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ChatScreen extends StatefulWidget {
  final String chatId;
  final String uid;
  final String username;
  final String userImage;
  final String recipientId;
  final String recipient;
  final String recipientToken;
  final String recipientImage;

  const ChatScreen({
    super.key,
    required this.chatId,
    required this.uid,
    required this.username,
    required this.userImage,
    required this.recipientId,
    required this.recipient,
    required this.recipientImage,
    required this.recipientToken,
  });

  @override
  ChatScreenState createState() => ChatScreenState();
}

class ChatScreenState extends State<ChatScreen> {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _messageController = TextEditingController();
  final TextEditingController _captionController = TextEditingController();

  void _sendMessage(Message message) async {
    await FirebaseFirestore.instance
        .collection('chats')
        .doc(widget.chatId)
        .update({
      'messages': FieldValue.arrayUnion([message.toMap()])
    }).then((value) async => NotificationServices.sendNotification(
            chatId: widget.chatId,
            recipientId: widget.recipientId,
            recipientName: widget.recipient,
            recipientImage: widget.recipientImage,
            recipientToken: widget.recipientToken,
            senderId: widget.uid,
            sender: widget.username,
            senderImage: widget.userImage,
            senderToken: await NotificationServices().getToken(),
            message: message.message));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            CircleAvatar(backgroundImage: NetworkImage(widget.recipientImage)),
            Padding(
              padding: const EdgeInsets.only(left: 8.0),
              child: Text(
                widget.recipient,
                style:
                    const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder(
              stream: FirebaseFirestore.instance
                  .collection('chats')
                  .doc(widget.chatId)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                } else {
                  final messages = List<Map<String, dynamic>>.from(
                      snapshot.data!.get('messages'));
                  final reversedMessages = messages.reversed.toList();
                  return ListView.builder(
                    reverse: true,
                    itemCount: reversedMessages.length,
                    controller: _scrollController,
                    itemBuilder: (context, index) {
                      var message = Message.fromMap(reversedMessages[index]);
                      bool isCurrentUser = message.senderId == widget.uid;
                      var alignment = isCurrentUser
                          ? CrossAxisAlignment.end
                          : CrossAxisAlignment.start;
                      return Padding(
                        padding: const EdgeInsets.symmetric(
                            vertical: 4.0, horizontal: 8.0),
                        child: Column(
                          crossAxisAlignment: alignment,
                          children: [
                            Container(
                              constraints: BoxConstraints(
                                  maxWidth:
                                      MediaQuery.of(context).size.width * 0.8),
                              decoration: BoxDecoration(
                                color: isCurrentUser
                                    ? Colors.blue
                                    : Theme.of(context).cardColor,
                                borderRadius: BorderRadius.circular(8.0),
                              ),
                              padding: const EdgeInsets.all(8.0),
                              child: Column(
                                crossAxisAlignment: alignment,
                                children: [
                                  _buildMessage(message, index, messages),
                                  Text(
                                    timeago.format(message.timestamp,
                                        locale: 'en_short'),
                                    style: const TextStyle(fontSize: 10),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  );
                }
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: const InputDecoration(
                      hintText: 'Enter your message...',
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.all(Radius.circular(20))),
                    ),
                  ),
                ),
                IconButton(
                    onPressed: () {
                      showModalBottomSheet(
                        context: context,
                        builder: (BuildContext context) {
                          return Container(
                            padding: const EdgeInsets.symmetric(vertical: 20.0),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: <Widget>[
                                ListTile(
                                  title: const Text('Images & Videos'),
                                  onTap: () async {
                                    Navigator.pop(context);
                                    var result = await FirebaseService.pickFile(
                                        FileType.media);
                                    if (result != null) {
                                      _sendMediaMessage(result);
                                    }
                                  },
                                ),
                                ListTile(
                                  title: const Text('Documents'),
                                  onTap: () async {
                                    Navigator.pop(context);
                                    var result = await FirebaseService.pickFile(
                                        FileType.custom);
                                    if (result != null) {
                                      _sendMediaMessage(result);
                                    }
                                  },
                                ),
                              ],
                            ),
                          );
                        },
                      );
                    },
                    icon: const Icon(Icons.add)),
                IconButton(
                  icon: const Icon(Icons.send),
                  onPressed: () {
                    String message = _messageController.text.trim();
                    _messageController.clear();
                    if (message.isNotEmpty) {
                      _sendMessage(Message(
                        senderId: widget.uid,
                        message: message,
                        timestamp: DateTime.now(),
                        type: MessageType.text,
                        mediaUrl: '',
                        mediaName: '',
                      ));
                    } else {
                      Fluttertoast.showToast(
                          msg: 'Please enter a message.',
                          gravity: ToastGravity.CENTER);
                    }
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessage(
      Message message, int index, List<Map<String, dynamic>> messages) {
    switch (message.type) {
      case MessageType.text:
        return Text(message.message);
      case MessageType.image:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            GestureDetector(
              onTap: () {
                var url = message.mediaUrl;
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => Center(
                      child: Hero(
                        tag: url,
                        child: PhotoView(
                          imageProvider: NetworkImage(url),
                          minScale: PhotoViewComputedScale.contained,
                          maxScale: PhotoViewComputedScale.covered * 2.5,
                        ),
                      ),
                    ),
                  ),
                );
              },
              child: Image.network(
                message.mediaUrl,
                width: 200,
                height: 200,
                fit: BoxFit.cover,
              ),
            ),
            if (message.message.isNotEmpty) Text(message.message)
          ],
        );
      case MessageType.video:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 200,
              height: 200,
              child: MediaPlayer.urlVideo(message.mediaUrl),
            ),
            if (message.message.isNotEmpty) Text(message.message)
          ],
        );
      case MessageType.document:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              decoration: BoxDecoration(
                  border: Border.all(color: Colors.white),
                  borderRadius: BorderRadius.circular(8)),
              child: ListTile(
                  leading: const Icon(Icons.file_present),
                  title: Text(message.mediaName),
                  trailing: message.downloadState == DownloadState.notDownloaded
                      ? IconButton(
                          onPressed: () async =>
                              await downloadDocument(message, index, messages),
                          icon: const Icon(Icons.download_for_offline_rounded))
                      : message.downloadState == DownloadState.downloading
                          ? const CircularProgressIndicator()
                          : null,
                  onTap: () async {
                    if (message.downloadState == DownloadState.downloaded) {
                      await openDocumnet(message.mediaName);
                    } else if (message.downloadState ==
                        DownloadState.notDownloaded) {
                      await downloadDocument(message, index, messages);
                    }
                  }),
            ),
            if (message.message.isNotEmpty) Text(message.message)
          ],
        );
      default:
        return Container();
    }
  }

  Future<void> openDocumnet(String fileName) async {
    var result =
        await getExternalStorageDirectories(type: StorageDirectory.documents);
    if (result != null) {
      var filePath = '${result.first.path}/$fileName';
      if (await File(filePath).exists()) {
        await OpenFile.open(filePath);
      } else {
        Fluttertoast.showToast(
            msg: "Document not found!", gravity: ToastGravity.CENTER);
      }
    }
  }

  Future<void> downloadDocument(
      Message message, int index, List<Map<String, dynamic>> messages) async {
    var ref = FirebaseFirestore.instance.collection('chats').doc(widget.chatId);
    message.downloadState = DownloadState.downloading;
    messages[messages.length - 1 - index] = message.toMap();
    await ref.update({'messages': messages});
    var result =
        await getExternalStorageDirectories(type: StorageDirectory.documents);
    if (result != null) {
      var response = await http.get(Uri.parse(message.mediaUrl));
      if (response.statusCode == 200) {
        final file = File('${result.first.path}/${message.mediaName}');
        await file.writeAsBytes(response.bodyBytes).then((value) async {
          message.downloadState = DownloadState.downloaded;
          messages[messages.length - 1 - index] = message.toMap();
          await ref.update({'messages': messages});
        });
      } else {
        Fluttertoast.showToast(
            msg: "Can't Download. Ask to Resend.",
            gravity: ToastGravity.CENTER);
      }
    }
  }

  Widget _buildMedia(FileResult result) {
    switch (result.type) {
      case FileType.image:
        return Image.file(
          result.file,
          width: 200,
          height: 200,
          fit: BoxFit.cover,
        );
      case FileType.video:
        return SizedBox(
            width: 200, height: 200, child: MediaPlayer.fileVideo(result.file));
      case FileType.custom:
        return ListTile(
            leading: const Icon(Icons.file_present),
            title: Text(result.file.path.split('/').last));
      default:
        return Container();
    }
  }

  void _sendMediaMessage(FileResult result) async {
    showModalBottomSheet(
      isScrollControlled: true,
      context: context,
      builder: (context) {
        return SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
            ),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: _buildMedia(result),
                ),
                Row(
                  children: [
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: TextField(
                          controller: _captionController,
                          decoration: const InputDecoration(
                            hintText: 'Enter caption...',
                          ),
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.send),
                      onPressed: () async {
                        String caption = _captionController.text.trim();
                        _captionController.clear();
                        Navigator.pop(context);
                        String mediaUrl = await FirebaseService.uploadFile(
                          result.file,
                          'media_${DateTime.now().millisecondsSinceEpoch}.${result.extension}',
                          "chat_media",
                        );
                        Message message = Message(
                          senderId: widget.uid,
                          message: caption,
                          timestamp: DateTime.now(),
                          type: result.type == FileType.image
                              ? MessageType.image
                              : result.type == FileType.video
                                  ? MessageType.video
                                  : MessageType.document,
                          mediaUrl: mediaUrl,
                          mediaName: result.type == FileType.custom
                              ? result.file.path.split('/').last
                              : '',
                        );
                        _sendMessage(message);
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
