import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:mood_fresher/firebase/firebase.dart';
import 'package:mood_fresher/screens/home.dart';
import 'package:mood_fresher/screens/profileSetup.dart';
import 'package:mood_fresher/screens/signUp.dart';

class SignInScreen extends StatefulWidget {
  const SignInScreen({super.key});

  @override
  SignInScreenState createState() => SignInScreenState();
}

class SignInScreenState extends State<SignInScreen> {
  final GlobalKey<FormState> key = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isPasswordVisible = false;
  bool _isLogingIn = false;
  bool _isLogingWithGoogle = false;
  String _errorText = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: AppBar(title: const Center(child: Text('Sign In'))),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Form(
              key: key,
              child: Column(
                children: [
                  TextFormField(
                    controller: _emailController,
                    decoration: const InputDecoration(labelText: 'Email'),
                    keyboardType: TextInputType.emailAddress,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Enter Email';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _passwordController,
                    decoration: InputDecoration(
                      labelText: 'Password',
                      suffixIcon: IconButton(
                        icon: Icon(
                          _isPasswordVisible
                              ? Icons.visibility
                              : Icons.visibility_off,
                        ),
                        onPressed: () {
                          setState(() {
                            _isPasswordVisible = !_isPasswordVisible;
                          });
                        },
                      ),
                    ),
                    obscureText: !_isPasswordVisible,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Enter Password';
                      }
                      return null;
                    },
                  ),
                  if (_errorText.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                      child: Text(
                        _errorText,
                        style: const TextStyle(color: Colors.red),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () {},
                child: const Text('Forgot Password?'),
              ),
            ),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: _isLogingIn ? null : _performLogin,
              child: SizedBox(
                width: double.infinity,
                child: _isLogingIn
                    ? const Center(child: CircularProgressIndicator())
                    : const Center(
                        child: Text('Login'),
                      ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 16),
                    child: const Divider(
                      color: Colors.grey,
                    ),
                  ),
                ),
                const Text('or'),
                Expanded(
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 16),
                    child: const Divider(
                      color: Colors.grey,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () async {
                setState(() {
                  _isLogingWithGoogle = true;
                });
                await FirebaseService.loginWithGoogle().then((value) async {
                  setState(() {
                    _isLogingWithGoogle = false;
                  });
                  if (value != null) {
                    User? currentUser = FirebaseAuth.instance.currentUser;
                    if (currentUser != null) {
                      if (value.additionalUserInfo?.isNewUser ?? false) {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                ProfileSetupScreen(currentUser: currentUser),
                          ),
                        );
                      } else {
                        login(currentUser);
                      }
                    }
                  } else {
                    setState(() {
                      _errorText = 'Failed to Login';
                    });
                  }
                });
              },
              child: SizedBox(
                width: double.infinity,
                child: _isLogingWithGoogle
                    ? const Center(child: CircularProgressIndicator())
                    : const Center(
                        child: Text('Login with Google'),
                      ),
              ),
            ),
            const SizedBox(height: 16),
            const Divider(color: Colors.grey),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text("Don't have an account?"),
                TextButton(
                  onPressed: () {
                    Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                            builder: (context) => const SignUpScreen()));
                  },
                  child: const Text("Sign Up"),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }

  Future<void> _performLogin() async {
    if (key.currentState!.validate()) {
      setState(() {
        _isLogingIn = true;
        _errorText = '';
      });
      await FirebaseService.signIn(
              _emailController.text.trim(), _passwordController.text.trim())
          .then((value) {
        if (value) {
          User? currentUser = FirebaseAuth.instance.currentUser;
          if (currentUser != null) login(currentUser);
        } else {
          setState(() {
            _errorText = 'Failed to Login';
          });
        }
      });
      setState(() {
        _isLogingIn = false;
      });
    }
  }

  Future<void> login(User currentUser) async {
    if (currentUser.displayName == null || currentUser.photoURL == null) {
      await getUserProfilePictureUrl(currentUser.uid)
          .then((value) => Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) => HomeScreen(
                      uid: currentUser.uid,
                      username: value[0],
                      photoURL: value[1]),
                ),
              ));
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => HomeScreen(
              uid: currentUser.uid,
              username: currentUser.displayName!,
              photoURL: currentUser.photoURL!),
        ),
      );
    }
  }

  Future<List<String>> getUserProfilePictureUrl(String userId) async {
    DocumentSnapshot<Map<String, dynamic>> snapshot =
        await FirebaseFirestore.instance.collection('users').doc(userId).get();
    return [snapshot.data()?['Name'], snapshot.data()?['Image']];
  }
}
