import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_fortune_wheel_example/Firebase_auth/firebae_auth_services.dart';
import 'package:flutter_fortune_wheel_example/main.dart';
import 'package:flutter_fortune_wheel_example/pages/adminHomepage.dart';
import 'package:flutter_fortune_wheel_example/widgets/SignUp.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Login extends StatefulWidget {
  const Login({Key? key}) : super(key: key);

  @override
  State<Login> createState() => _LoginState();
}

class _LoginState extends State<Login> {
  @override
  void initState() {
    // TODO: implement initState
    super.initState();
  }

  final FirebaseAuthServices _auth = FirebaseAuthServices();
  TextEditingController _emailController = TextEditingController();
  TextEditingController _passwordController = TextEditingController();
  TextEditingController _confirmPasswordController = TextEditingController();
  bool isLoading = false;
  String userRole = "";
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Container(
        decoration: BoxDecoration(
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
            const Text(
              'Login',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            Container(
              padding: EdgeInsets.only(left: 40, right: 40),
              child: Column(
                children: [
                  TextField(
                    controller: _emailController,
                    maxLines: 1,
                    decoration: InputDecoration(hintText: 'Email'),
                  ),
                  SizedBox(
                    height: 12,
                  ),
                  TextField(
                    controller: _passwordController,
                    maxLines: 1,
                    decoration: InputDecoration(hintText: 'Password'),
                  ),
                  SizedBox(
                    height: 18,
                  ),
                ],
              ),
            ),
            ElevatedButton(
              onPressed: isLoading ? null : _signIn,
              child: isLoading ? CircularProgressIndicator() : Text('Login'),
            ),
          ],
        ),
      ),
    );
  }

  void _signIn() async {
    setState(() {
      isLoading = true;
    });

    String email = _emailController.text;
    String password = _passwordController.text;

    User? user =
        await _auth.signInWithEmailAndPassword(email, password, context);

    if (user != null) {
      await _auth.getUserRole(user.uid); // Retrieve user role
      await _storeUserIdInSharedPreferences(user.uid);

      await _loadUserRole(); // Load user role after it's fetched
      print(userRole);
      setState(() {
        isLoading = false;
      });

      final snackBar = SnackBar(
        content: const Text('Successful Login!'),
        backgroundColor: Colors.green,
        action: SnackBarAction(
          label: 'Ok',
          onPressed: () {
            // Some code to undo the change.
          },
        ),
      );
      ScaffoldMessenger.of(context).showSnackBar(snackBar);
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => userRole == "admin" ? Dashboard() : MyApp(),
        ),
      );
    } else {
      setState(() {
        isLoading = false;
      });
      // Handle login failure
    }
  }

  Future<void> _storeUserIdInSharedPreferences(String userId) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('userId', userId);
  }

  Future<void> _loadUserRole() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    userRole = prefs.getString('userRole') ?? '';
    setState(() {}); // This will trigger a rebuild with the updated userRole
  }
}
