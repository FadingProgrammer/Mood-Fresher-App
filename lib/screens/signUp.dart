import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:mood_fresher/firebase/firebase.dart';
import 'package:mood_fresher/screens/profileSetup.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  SignUpScreenState createState() => SignUpScreenState();
}

class SignUpScreenState extends State<SignUpScreen> {
  final GlobalKey<FormState> key = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();

  bool _isPasswordVisible = false;
  bool _isSigningUp = false;
  String _errorText = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Center(child: Text('Sign Up')),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Form(
              key: key,
              child: Column(
                children: [
                  textField('Email', _emailController, (value) {
                    final emailRegex =
                        RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
                    if (value == null ||
                        value.isEmpty ||
                        !emailRegex.hasMatch(value)) {
                      return 'Invalid Email';
                    }
                    return null;
                  }),
                  const SizedBox(height: 16),
                  textField('Password', _passwordController, isPassword: true,
                      (value) {
                    if (value == null || value.isEmpty) {
                      return 'Enter Password';
                    } else if (value.length < 6) {
                      return 'Password should be at least 6 characters';
                    }
                    return null;
                  }),
                  const SizedBox(height: 16),
                  textField('Confirm Password', _confirmPasswordController,
                      isPassword: true, (value) {
                    if (value == null || value.isEmpty) {
                      return 'Confirm Password';
                    } else if (value != _passwordController.text.trim()) {
                      return 'Password Mismatch';
                    }
                    return null;
                  }),
                  if (_errorText.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Text(
                        _errorText,
                        style: const TextStyle(color: Colors.red),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: _isSigningUp ? null : _performSignUp,
              child: SizedBox(
                width: double.infinity,
                child: _isSigningUp
                    ? const Center(child: CircularProgressIndicator())
                    : const Center(child: Text('Sign Up')),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _performSignUp() async {
    if (key.currentState!.validate()) {
      setState(() {
        _isSigningUp = true;
        _errorText = '';
      });
      await FirebaseService.signUp(
              _emailController.text.trim(), _passwordController.text.trim())
          .then((value) {
        if (value) {
          User? currentUser = FirebaseAuth.instance.currentUser;
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) =>
                  ProfileSetupScreen(currentUser: currentUser!),
            ),
          );
        } else {
          setState(() {
            _errorText = 'Failed to Sign Up';
          });
        }
      });
      setState(() {
        _isSigningUp = false;
      });
    }
  }

  Widget textField(String label, TextEditingController controller,
      String? Function(String?) validator,
      {bool isPassword = false}) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        suffixIcon: isPassword
            ? IconButton(
                icon: Icon(
                  _isPasswordVisible ? Icons.visibility : Icons.visibility_off,
                ),
                onPressed: () {
                  setState(() {
                    _isPasswordVisible = !_isPasswordVisible;
                  });
                },
              )
            : null,
      ),
      obscureText: isPassword && !_isPasswordVisible,
      validator: validator,
    );
  }
}
