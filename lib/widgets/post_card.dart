import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:timeago/timeago.dart' as timeago;

class PostCard extends StatefulWidget {
  final DocumentSnapshot<Map<String, dynamic>> snap;
  final String uid;
  final String username;
  final String photoURL;
  const PostCard(
      {super.key,
      required this.snap,
      required this.uid,
      required this.username,
      required this.photoURL});

  @override
  PostCardState createState() => PostCardState();
}

class PostCardState extends State<PostCard>
    with SingleTickerProviderStateMixin {
  bool isLiked = false;
  bool isBookmarked = false;
  bool showHeart = false;
  int likeCount = 0;
  final TextEditingController _commentController = TextEditingController();
  late AnimationController _animationController;
  late Animation<double> _animation;
  // final FocusNode _commentFocusNode = FocusNode();

  // @override
  // void dispose() {
  //   _commentController.dispose();
  //   _commentFocusNode.dispose();
  //   super.dispose();
  // }

  @override
  void initState() {
    super.initState();
    likeCount = widget.snap['likeCount'];
    isLiked = List<Map<String, dynamic>>.from(widget.snap['likedBy'])
        .any((item) => item['uid'] == widget.uid);
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    );
    _animation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 5),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 18,
                      backgroundImage: NetworkImage(widget.snap['Image']),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(left: 10),
                      child: Text(
                        widget.snap['username'],
                        style: const TextStyle(
                          fontSize: 16,
                        ),
                      ),
                    )
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.more_vert),
                  onPressed: () {},
                ),
              ],
            ),
          ),
          GestureDetector(
            onDoubleTap: () {
              setState(() {
                isLiked = !isLiked;
                showHeart = true;
              });
              updateLikes();
              _animationController.forward().then((value) {
                _animationController.reverse();
                setState(() {
                  showHeart = false;
                });
              });
            },
            child: Stack(
              children: [
                SizedBox(
                  height: MediaQuery.of(context).size.height * 0.35,
                  width: double.infinity,
                  child: Image.network(
                    widget.snap['Image'],
                    fit: BoxFit.cover,
                  ),
                ),
                if (showHeart)
                  Positioned(
                    top: MediaQuery.of(context).size.height * 0.175 - 30,
                    left: MediaQuery.of(context).size.width * 0.5 - 30,
                    child: AnimatedBuilder(
                      animation: _animation,
                      builder: (context, child) {
                        return Transform.scale(
                          scale: Tween<double>(begin: 1.0, end: 1.5)
                              .evaluate(_animation),
                          child: Opacity(
                            opacity: 1 - _animation.value,
                            child: child,
                          ),
                        );
                      },
                      child: const Icon(
                        Icons.favorite,
                        color: Colors.red,
                        size: 60,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    IconButton(
                      icon: Icon(
                        isLiked ? Icons.favorite : Icons.favorite_border,
                        color: isLiked ? Colors.red : Colors.white,
                      ),
                      onPressed: () {
                        setState(() {
                          isLiked = !isLiked;
                        });
                        updateLikes();
                      },
                    ),
                    IconButton(
                      icon: const Icon(
                        Icons.comment,
                        color: Colors.white,
                      ),
                      onPressed: () {},
                    ),
                    IconButton(
                      icon: const Icon(
                        Icons.send_outlined,
                        color: Colors.white,
                      ),
                      onPressed: () {},
                    ),
                  ],
                ),
                IconButton(
                  icon: Icon(
                    isBookmarked
                        ? Icons.bookmark_sharp
                        : Icons.bookmark_border_sharp,
                    color: Colors.white,
                  ),
                  onPressed: () async {
                    setState(() {
                      isBookmarked = !isBookmarked;
                    });
                    updateSaved();
                    // FirebaseService.uploadPost(
                    //     imageFile: widget.snap['Image'], username: "Random");
                  },
                ),
              ],
            ),
          ),
          if (likeCount > 0) buildLikedByText(),
          RichText(
            text: TextSpan(
              style: DefaultTextStyle.of(context).style,
              children: [
                TextSpan(
                  text: widget.snap['username'],
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const TextSpan(text: '  caption'),
              ],
            ),
          ),
          if (widget.snap['comments'].isNotEmpty)
            Text.rich(
              TextSpan(
                children: [
                  TextSpan(
                    text:
                        '${widget.snap['comments'].last['username'].toString()}: ',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  TextSpan(
                    text: widget.snap['comments'].last['comment'].toString(),
                  ),
                ],
              ),
            ),
          if (widget.snap['comments'].length > 1)
            GestureDetector(
                onTap: () =>
                    _showBottomSheet(widget.snap['comments'], isComment: true),
                child: Text(
                  "View all ${widget.snap['comments'].length} comments",
                  style: const TextStyle(color: Colors.grey, fontSize: 12),
                )),
          commentRow(() {
            addComment();
          }),
          Text(
            timeago.format(widget.snap['timestamp'].toDate(),
                locale: 'en_short'),
            style: const TextStyle(color: Colors.grey, fontSize: 12),
          ),
        ],
      ),
    );
  }

  void updateLikes() async {
    try {
      var likedByList = List<Map<String, dynamic>>.from(widget.snap['likedBy']);
      DocumentReference userDocRef =
          FirebaseFirestore.instance.collection('users').doc(widget.uid);
      if (isLiked) {
        likedByList.add({
          'uid': widget.uid,
          'username': widget.username,
          'userImage': widget.photoURL
        });
        await userDocRef.update({
          'likedPosts': FieldValue.arrayUnion([widget.snap.reference.id]),
        });
      } else {
        likedByList.removeWhere((item) => item['uid'] == widget.uid);
        await userDocRef.update({
          'likedPosts': FieldValue.arrayRemove([widget.snap.reference.id]),
        });
      }
      await widget.snap.reference.update({
        'likedBy': likedByList,
        'likeCount': isLiked ? likeCount + 1 : likeCount - 1,
      });
      setState(() {
        likeCount = isLiked ? likeCount + 1 : likeCount - 1;
      });
    } catch (e) {
      Fluttertoast.showToast(
          msg: 'Error updating likes: ${e.toString()}',
          gravity: ToastGravity.CENTER);
    }
  }

  void updateSaved() async {
    try {
      DocumentReference userDocRef =
          FirebaseFirestore.instance.collection('users').doc(widget.uid);
      if (isBookmarked) {
        await userDocRef.update({
          'savedPosts': FieldValue.arrayUnion([widget.snap.reference.id]),
        });
      } else {
        await userDocRef.update({
          'savedPosts': FieldValue.arrayRemove([widget.snap.reference.id]),
        });
      }
    } catch (e) {
      Fluttertoast.showToast(
          msg: 'Error updating likes: ${e.toString()}',
          gravity: ToastGravity.CENTER);
    }
  }

  Widget buildLikedByText() {
    var likedByList = List<Map<String, dynamic>>.from(widget.snap['likedBy']);
    if (likedByList.isEmpty) {
      setState(() {
        likeCount = 0;
      });
    }
    return RichText(
      text: TextSpan(
        children: [
          const TextSpan(text: 'Liked by '),
          TextSpan(
              text: likedByList[0]['username'],
              style: const TextStyle(fontWeight: FontWeight.bold)),
          if (likedByList.length > 1) ...[
            const TextSpan(text: ' and '),
            TextSpan(
              text: '${likedByList.length - 1} others',
              style: const TextStyle(fontWeight: FontWeight.bold),
              recognizer: TapGestureRecognizer()
                ..onTap = () => _showBottomSheet(widget.snap['likedBy']),
            ),
          ],
        ],
      ),
    );
  }

  Widget commentRow(void Function()? onPressed) {
    return Row(
      children: [
        CircleAvatar(
          radius: 18,
          backgroundImage: NetworkImage(widget.photoURL),
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: TextFormField(
              controller: _commentController,
              style: const TextStyle(fontSize: 14),
              decoration: const InputDecoration(
                hintText: 'Add a comment...',
                border: InputBorder.none,
              ),
            ),
          ),
        ),
        IconButton(
          icon: const Icon(
            Icons.send_outlined,
            color: Colors.white,
          ),
          onPressed: onPressed,
        ),
      ],
    );
  }

  Future<void> addComment() async {
    String comment = _commentController.text.trim();
    _commentController.clear();
    if (comment.isNotEmpty) {
      try {
        var commentsList =
            List<Map<String, dynamic>>.from(widget.snap['comments']);
        commentsList.add({
          'uid': widget.uid,
          'username': widget.username,
          'userImage': widget.photoURL,
          'comment': comment,
          'timestamp': DateTime.now()
        });
        await widget.snap.reference.update({
          'comments': commentsList,
        });
      } catch (e) {
        Fluttertoast.showToast(
            msg: 'Error adding comment: ${e.toString()}',
            gravity: ToastGravity.CENTER);
      }
    } else {
      Fluttertoast.showToast(
          msg: 'Please enter a comment', gravity: ToastGravity.CENTER);
    }
  }

  void _showBottomSheet(List<dynamic> map, {bool isComment = false}) {
    List<Map<String, dynamic>> data = List<Map<String, dynamic>>.from(map);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (BuildContext context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: SingleChildScrollView(
            child: Column(
              children: [
                SizedBox(
                  height: MediaQuery.of(context).size.height *
                      (isComment ? 0.45 : 0.5),
                  child: ListView.builder(
                    itemCount: data.length,
                    itemBuilder: (context, index) {
                      var item = data[index];
                      return ListTile(
                        leading: CircleAvatar(
                          radius: 18,
                          backgroundImage: NetworkImage(item['userImage']),
                        ),
                        title: Row(
                          children: [
                            Text(item['username']),
                            if (isComment) ...[
                              const SizedBox(width: 15),
                              Text(
                                  timeago.format(item['timestamp'].toDate(),
                                      locale: 'en_short'),
                                  style: const TextStyle(
                                      color: Colors.grey, fontSize: 12))
                            ]
                          ],
                        ),
                        subtitle: isComment ? Text(item['comment']) : null,
                      );
                    },
                  ),
                ),
                if (isComment)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8.0),
                    child: commentRow(() {
                      addComment().then((value) {
                        Navigator.of(context).pop();
                        _showBottomSheet(widget.snap['comments'],
                            isComment: true);
                      });
                    }),
                  )
              ],
            ),
          ),
        );
      },
    );
  }
}
