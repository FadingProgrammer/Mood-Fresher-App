import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:mood_fresher/screens/chat.dart';
import 'package:mood_fresher/screens/chatSearch.dart';

class InboxScreen extends StatelessWidget {
  final String uid;
  final String username;
  final String photoURL;
  const InboxScreen(
      {super.key,
      required this.uid,
      required this.username,
      required this.photoURL});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: false,
          title: const Center(child: Text('Inbox')),
        ),
        body: GestureDetector(
          onHorizontalDragUpdate: (details) {
            if (details.primaryDelta! > 0) {
              Navigator.of(context).pop();
            }
          },
          child: StreamBuilder(
            stream: FirebaseFirestore.instance
                .collection('chats')
                .where('participants.$uid', isNull: false)
                .snapshots(),
            builder: (context,
                AsyncSnapshot<QuerySnapshot<Map<String, dynamic>>> snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              final userChats = snapshot.data!.docs;
              return ListView.builder(
                itemCount: userChats.length,
                itemBuilder: (ctx, index) {
                  final chat = userChats[index];
                  final participants =
                      chat['participants'] as Map<String, dynamic>;
                  final otherParticipantId = participants.keys.firstWhere(
                    (id) => id != uid,
                    orElse: () => '',
                  );
                  final otherParticipant = participants[otherParticipantId];
                  return Card(
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundImage:
                            NetworkImage(otherParticipant['Image']),
                      ),
                      title: Text(otherParticipant['Name']),
                      subtitle: Text(
                          chat['messages'].isNotEmpty
                              ? chat['messages'].last['message']
                              : '',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis),
                      onTap: () => Navigator.of(context).push(MaterialPageRoute(
                          builder: (context) => ChatScreen(
                              chatId: chat.id,
                              uid: uid,
                              username: username,
                              userImage: photoURL,
                              recipientId: otherParticipantId,
                              recipient: otherParticipant['Name'],
                              recipientImage: otherParticipant['Image'],
                              recipientToken: otherParticipant['Token']))),
                    ),
                  );
                },
              );
            },
          ),
        ),
        floatingActionButton: ElevatedButton(
          onPressed: () {
            Navigator.of(context).push(MaterialPageRoute(
                builder: (context) => ChatSearchScreen(
                    uid: uid, username: username, photoURL: photoURL)));
          },
          style: ElevatedButton.styleFrom(shape: const CircleBorder()),
          child: const Icon(Icons.add),
        ));
  }
}
