import 'package:flutter/material.dart';
import 'package:mood_fresher/firebase/notification.dart';
import 'package:mood_fresher/screens/feed.dart';
import 'package:mood_fresher/screens/profile.dart';
import 'package:mood_fresher/screens/reels.dart';
import 'package:mood_fresher/screens/search.dart';
import 'package:mood_fresher/screens/uploadPost.dart';

class HomeScreen extends StatefulWidget {
  final String uid;
  final String username;
  final String photoURL;

  const HomeScreen(
      {super.key,
      required this.uid,
      required this.username,
      required this.photoURL});
  @override
  HomeScreenState createState() => HomeScreenState();
}

class HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    NotificationServices().initialize(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _buildBody(),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        type: BottomNavigationBarType.fixed,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        showSelectedLabels: false,
        showUnselectedLabels: false,
        items: [
          BottomNavigationBarItem(
            icon: _currentIndex == 0
                ? const Icon(Icons.home)
                : const Icon(Icons.home_outlined),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: _currentIndex == 1
                ? const Icon(Icons.search)
                : const Icon(Icons.search_outlined),
            label: 'Search',
          ),
          BottomNavigationBarItem(
            icon: _currentIndex == 2
                ? const Icon(Icons.add_box)
                : const Icon(Icons.add_box_outlined),
            label: 'Upload Post',
          ),
          BottomNavigationBarItem(
            icon: _currentIndex == 3
                ? const Icon(Icons.movie_creation)
                : const Icon(Icons.movie_creation_outlined),
            label: 'Reels',
          ),
          BottomNavigationBarItem(
            icon: Container(
              decoration: _currentIndex == 4
                  ? BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    )
                  : null,
              child: CircleAvatar(
                radius: _currentIndex == 4 ? 12 : 14,
                backgroundImage: NetworkImage(
                  widget.photoURL,
                ),
              ),
            ),
            label: 'Profile',
          ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    switch (_currentIndex) {
      case 0:
        return FeedScreen(
            uid: widget.uid,
            username: widget.username,
            photoURL: widget.photoURL);
      case 1:
        return const SearchScreen();
      case 2:
        return UploadPostScreen(
            uid: widget.uid,
            username: widget.username,
            photoURL: widget.photoURL);
      case 3:
        return const ReelsScreen();
      case 4:
        return ProfileScreen(
            uid: widget.uid,
            username: widget.username,
            photoURL: widget.photoURL);
      default:
        return Container();
    }
  }
}
