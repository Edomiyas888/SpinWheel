import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_fortune_wheel_example/Firebase_auth/firebae_auth_services.dart';
import 'package:flutter_fortune_wheel_example/main.dart';
import 'package:flutter_fortune_wheel_example/widgets/login.dart';

class SignUp extends StatefulWidget {
  const SignUp({Key? key}) : super(key: key);

  @override
  State<SignUp> createState() => _SignUpState();
}

class _SignUpState extends State<SignUp> {
  final FirebaseAuthServices _auth = FirebaseAuthServices();
  TextEditingController _emailController = TextEditingController();
  TextEditingController _passwordController = TextEditingController();
  TextEditingController _confirmPasswordController = TextEditingController();
  TextEditingController _usernameController =
      TextEditingController(); // New username controller

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.green, Colors.white],
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            Image.asset(
              'assets/images/prime_logo.png',
              width: 150,
              height: 150,
              fit: BoxFit.contain,
            ),
            const Text(
              'SignUp',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            Container(
              padding: EdgeInsets.only(left: 40, right: 40),
              child: Column(
                children: [
                  TextField(
                    controller: _emailController,
                    maxLines: 1,
                    decoration: const InputDecoration(hintText: 'Email'),
                  ),
                  TextField(
                    controller: _passwordController,
                    maxLines: 1,
                    decoration: const InputDecoration(hintText: 'Password'),
                  ),
                  TextField(
                    controller: _confirmPasswordController,
                    maxLines: 1,
                    decoration:
                        const InputDecoration(hintText: 'Confirm password'),
                  ),
                  TextField(
                    controller: _usernameController, // Added username field
                    maxLines: 1,
                    decoration: const InputDecoration(
                        hintText: 'Username'), // Placeholder for username
                  ),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('Already have an account? '),
                      GestureDetector(
                        child: const Text(
                          'Login',
                          style: TextStyle(fontWeight: FontWeight.w900),
                        ),
                        onTap: () {
                          Navigator.push(context,
                              MaterialPageRoute(builder: (context) => Login()));
                        },
                      )
                    ],
                  )
                ],
              ),
            ),
            ElevatedButton(onPressed: () => _signUp(), child: Text('Sign Up'))
          ],
        ),
      ),
    );
  }

  void _signUp() async {
    String email = _emailController.text;
    String password = _passwordController.text;
    String confirmPassword = _confirmPasswordController.text;
    String username = _usernameController.text; // Retrieve username

    User? user =
        await _auth.signUpWithEmailAndPassword(email, password, context);
    if (user != null) {
      // Save user data to Firestore
      await saveUserData(user.uid, email,
          username); // Pass UID, email, and username to saveUserData function

      final snackBar = SnackBar(
        content: const Text('Successful Sign up!'),
        backgroundColor: Colors.green,
        action: SnackBarAction(
          label: 'Ok',
          onPressed: () {
            // Some code to undo the change.
          },
        ),
      );
      ScaffoldMessenger.of(context).showSnackBar(snackBar);
      Navigator.push(context, MaterialPageRoute(builder: (context) => MyApp()));
    }
  }

  Future<void> saveUserData(String uid, String email, String username) async {
    try {
      // Get reference to the 'users' collection
      final CollectionReference users =
          FirebaseFirestore.instance.collection('users');

      // Add a new document with a generated ID
      await users.doc(uid).set({
        'email': email,
        'username': username,
        'role': 'admin'
        // Add more user data as needed
      });
    } catch (e) {
      print('Error saving user data: $e');
    }
  }
}
