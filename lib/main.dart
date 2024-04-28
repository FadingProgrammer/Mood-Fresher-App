import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:mood_fresher/screens/signIn.dart';
import 'package:mood_fresher/utils/colors.dart';
import 'firebase/firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Mood Fresher',
      theme: ThemeData.dark()
          .copyWith(scaffoldBackgroundColor: mobileBackgroundColor),
      home: const SignInScreen(),
    );
  }
}
