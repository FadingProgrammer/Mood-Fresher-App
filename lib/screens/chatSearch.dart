import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:mood_fresher/screens/chat.dart';

class ChatSearchScreen extends StatefulWidget {
  final String uid;
  final String username;
  final String photoURL;
  const ChatSearchScreen(
      {super.key,
      required this.uid,
      required this.username,
      required this.photoURL});

  @override
  State<ChatSearchScreen> createState() => _ChatSearchScreenState();
}

class _ChatSearchScreenState extends State<ChatSearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<QueryDocumentSnapshot<Map<String, dynamic>>> _users = [];
  List<QueryDocumentSnapshot<Map<String, dynamic>>> _filteredUsers = [];

  @override
  void initState() {
    super.initState();
    getUsers();
  }

  Future<void> getUsers() async {
    _users = (await FirebaseFirestore.instance
            .collection('users')
            .where(FieldPath.documentId, isNotEqualTo: widget.uid)
            .get())
        .docs;
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: TextField(
          controller: _searchController,
          decoration: const InputDecoration(
            hintText: 'Search',
            prefixIcon: Icon(Icons.search),
          ),
          onChanged: (value) {
            setState(() {
              _filteredUsers = _users
                  .where((user) => user['Name']
                      .toString()
                      .toLowerCase()
                      .contains(value.toLowerCase()))
                  .toList();
            });
          },
        ),
      ),
      body: ListView.builder(
        itemCount:
            _filteredUsers.isNotEmpty ? _filteredUsers.length : _users.length,
        itemBuilder: (context, index) {
          var user =
              _filteredUsers.isNotEmpty ? _filteredUsers[index] : _users[index];
          var userData = user.data();
          return ListTile(
            title: Text(userData['Name']),
            leading: CircleAvatar(
              backgroundImage: NetworkImage(userData['Image']),
            ),
            onTap: () => createChatWithUser(
                user.id, userData['Name'], userData['Image']),
          );
        },
      ),
    );
  }

  Future<void> createChatWithUser(
      String userId, String username, String photoURL) async {
    await FirebaseFirestore.instance
        .collection('chats')
        .get()
        .then((value) async {
      QueryDocumentSnapshot? chat;
      for (var doc in value.docs) {
        var participants = doc.data()['participants'];
        if (participants.containsKey(userId) &&
            participants.containsKey(widget.uid)) {
          chat = doc;
          break;
        }
      }
      if (chat != null) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ChatScreen(
                chatId: chat!.id,
                uid: widget.uid,
                recipient: username,
                recipientImage: photoURL),
          ),
        );
      } else {
        await FirebaseFirestore.instance.collection('chats').add({
          'participants': {
            widget.uid: {'Name': widget.username, 'Image': widget.photoURL},
            userId: {'Name': username, 'Image': photoURL},
          },
          'messages': [],
        }).then((value) => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ChatScreen(
                    chatId: value.id,
                    uid: widget.uid,
                    recipient: username,
                    recipientImage: photoURL),
              ),
            ));
      }
    });
  }
}
