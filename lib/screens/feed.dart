import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
// import 'package:mood_fresher/screens/chat.dart';
import 'package:mood_fresher/screens/inbox.dart';
// import 'package:mood_fresher/screens/inbox.dart';
import 'package:mood_fresher/widgets/post_card.dart';

class FeedScreen extends StatelessWidget {
  final String uid;
  final String username;
  final String photoURL;
  const FeedScreen(
      {super.key,
      required this.uid,
      required this.username,
      required this.photoURL});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Center(
          child: Text("Mood Fresher"),
        ),
      ),
      body: GestureDetector(
        onHorizontalDragUpdate: (details) {
          if (details.primaryDelta! < 0) {
            Navigator.of(context).push(_createRoute());
          }
        },
        child: StreamBuilder(
          stream: FirebaseFirestore.instance.collection('posts').snapshots(),
          builder: (context,
              AsyncSnapshot<QuerySnapshot<Map<String, dynamic>>> snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: CircularProgressIndicator(),
              );
            }
            return ListView.builder(
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              itemCount: snapshot.data!.docs.length,
              itemBuilder: (ctx, index) => PostCard(
                snap: snapshot.data!.docs[index],
                uid: uid,
                username: username,
                photoURL: photoURL,
              ),
            );
          },
        ),
      ),
    );
  }

  Route _createRoute() {
    return PageRouteBuilder(
      pageBuilder: (context, animation, secondaryAnimation) =>
          InboxScreen(uid: uid, username: username, photoURL: photoURL),
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        const begin = Offset(1.0, 0.0);
        const end = Offset.zero;
        const curve = Curves.ease;
        var tween =
            Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
        var offsetAnimation = animation.drive(tween);
        return SlideTransition(
          position: offsetAnimation,
          child: child,
        );
      },
    );
  }
}
