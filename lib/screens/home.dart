import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:mood_fresher/screens/feed.dart';
import 'package:mood_fresher/screens/profile.dart';
import 'package:mood_fresher/screens/reels.dart';
import 'package:mood_fresher/screens/search.dart';
import 'package:mood_fresher/screens/uploadPost.dart';
import 'package:mood_fresher/utils/constants.dart';

class HomeScreen extends StatefulWidget {
  final User currentUser;

  const HomeScreen({super.key, required this.currentUser});
  @override
  HomeScreenState createState() => HomeScreenState();
}

class HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;
  String username = '';
  String profileImage = '';

  @override
  void initState() {
    super.initState();
    getUserProfilePictureUrl(widget.currentUser.uid);
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
            icon: CircleAvatar(
              radius: 14,
              backgroundImage: NetworkImage(
                profileImage.isEmpty ? profilePlaceholder : profileImage,
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
            uid: widget.currentUser.uid,
            username: username,
            photoURL: profileImage.isEmpty ? profilePlaceholder : profileImage);
      case 1:
        return const SearchScreen();
      case 2:
        return const UploadPostScreen();
      case 3:
        return const ReelsScreen();
      case 4:
        return const ProfileScreen();
      default:
        return Container();
    }
  }

  Future<void> getUserProfilePictureUrl(String userId) async {
    DocumentSnapshot<Map<String, dynamic>> snapshot =
        await FirebaseFirestore.instance.collection('users').doc(userId).get();
    setState(() {
      username = snapshot.data()?['Name'];
      profileImage = snapshot.data()?['Image'];
    });
  }
}
