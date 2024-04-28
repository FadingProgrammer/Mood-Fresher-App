import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:cloud_firestore/cloud_firestore.dart';

class ChatScreen extends StatefulWidget {
  final String chatId;
  final String uid;
  final String recipient;
  final String recipientImage;

  const ChatScreen({
    super.key,
    required this.chatId,
    required this.uid,
    required this.recipient,
    required this.recipientImage,
  });

  @override
  ChatScreenState createState() => ChatScreenState();
}

class ChatScreenState extends State<ChatScreen> {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _messageController = TextEditingController();

  void _sendMessage(String message) async {
    await FirebaseFirestore.instance
        .collection('chats')
        .doc(widget.chatId)
        .update({
      'messages': FieldValue.arrayUnion([
        {
          'message': message,
          'senderId': widget.uid,
          'timestamp': DateTime.now()
        }
      ])
    });
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
                          snapshot.data!.get('messages'))
                      .reversed
                      .toList();
                  return ListView.builder(
                    reverse: true,
                    itemCount: messages.length,
                    controller: _scrollController,
                    itemBuilder: (context, index) {
                      var message = messages[index];
                      bool isCurrentUser = message['senderId'] == widget.uid;
                      return Padding(
                        padding: const EdgeInsets.symmetric(
                            vertical: 4.0, horizontal: 8.0),
                        child: Column(
                          crossAxisAlignment: isCurrentUser
                              ? CrossAxisAlignment.end
                              : CrossAxisAlignment.start,
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
                              child: RichText(
                                text: TextSpan(
                                  children: [
                                    TextSpan(
                                      text: message['message'] ?? '',
                                      style: const TextStyle(fontSize: 14),
                                    ),
                                    TextSpan(
                                      text:
                                          '\n${timeago.format(message['timestamp'].toDate(), locale: 'en_short')}',
                                      style: const TextStyle(fontSize: 10),
                                    ),
                                  ],
                                ),
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
                  icon: const Icon(Icons.send),
                  onPressed: () {
                    String message = _messageController.text.trim();
                    _messageController.clear();
                    if (message.isNotEmpty) {
                      _sendMessage(message);
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
}
