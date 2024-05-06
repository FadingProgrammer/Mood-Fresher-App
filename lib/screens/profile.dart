import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flick_video_player/flick_video_player.dart';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

class ProfileScreen extends StatefulWidget {
  final String uid;
  final String username;
  final String photoURL;
  const ProfileScreen(
      {super.key,
      required this.uid,
      required this.username,
      required this.photoURL});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  int postCount = 2;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.username)),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                CircleAvatar(
                    radius: 40, backgroundImage: NetworkImage(widget.photoURL)),
                infoItem(postCount, "posts"),
                infoItem(233, "followers"),
                infoItem(237, "following")
              ],
            ),
            const SizedBox(height: 6),
            Text(widget.username,
                style:
                    const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            const Text("Bio"),
            const Divider(),
            Expanded(
              child: DefaultTabController(
                length: 2,
                child: Column(
                  children: [
                    const TabBar(
                      dividerHeight: 0,
                      tabs: [
                        Tab(text: 'Posts'),
                        Tab(text: 'Saved Items'),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Expanded(
                      child: TabBarView(
                        children: [
                          buildTabContent(widget.uid, 'posts'),
                          buildTabContent(widget.uid, 'savedPosts'),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget buildTabContent(String userId, String field) {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final List<String> postIds =
            List<String>.from(snapshot.data![field] ?? []);
        return GridView.builder(
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: 4.0,
            mainAxisSpacing: 4.0,
          ),
          itemCount: postIds.length,
          itemBuilder: (context, index) {
            final postId = postIds[index];
            return FutureBuilder<DocumentSnapshot>(
              future: FirebaseFirestore.instance
                  .collection('posts')
                  .doc(postId)
                  .get(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                final post = snapshot.data!;
                final fileType = post['fileType'];
                final fileUrl = post['fileUrl'];
                if (fileType == 'FileType.image') {
                  return Image.network(fileUrl, fit: BoxFit.cover);
                } else if (fileType == 'FileType.video') {
                  return _buildVideoPlayer(fileUrl);
                } else {
                  return Container(color: Colors.grey);
                }
              },
            );
          },
        );
      },
    );
  }

  Widget _buildVideoPlayer(String videoUrl) {
    final flickManager = FlickManager(
        videoPlayerController:
            VideoPlayerController.networkUrl(Uri.parse(videoUrl)));
    return GestureDetector(
      onTap: () {
        if (flickManager.flickControlManager != null) {
          flickManager.flickControlManager!.enterFullscreen();
          flickManager.flickControlManager!.play();
        }
      },
      child: FlickVideoPlayer(
        flickManager: flickManager,
        flickVideoWithControls: const FlickVideoWithControls(
          videoFit: BoxFit.contain,
        ),
        flickVideoWithControlsFullscreen:
            const FlickVideoWithControls(controls: FlickLandscapeControls()),
      ),
    );
  }

  Widget infoItem(int count, String label) {
    return Column(
      children: [
        Text(count.toString(),
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 6),
        Text(label)
      ],
    );
  }

  Future<void> getPostsCount(String userId) async {
    DocumentSnapshot<Map<String, dynamic>> snapshot =
        await FirebaseFirestore.instance.collection('users').doc(userId).get();
    postCount = snapshot.data()?['posts'].length();
  }
}
