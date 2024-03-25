import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FirebaseAuthServices {
  FirebaseAuth _auth = FirebaseAuth.instance;

  Future<User?> signUpWithEmailAndPassword(
      String email, String password, BuildContext context) async {
    try {
      UserCredential credential = await _auth.createUserWithEmailAndPassword(
          email: email, password: password);
      return credential.user;
    } catch (e) {
      final snackBar = SnackBar(
        content: Text(e.toString().substring(e.toString().indexOf("]") + 2)),
        backgroundColor: const Color.fromARGB(255, 168, 78, 72),
        action: SnackBarAction(
          label: 'ok',
          onPressed: () {
            // Some code to undo the change.
          },
        ),
      );
      ScaffoldMessenger.of(context).showSnackBar(snackBar);

      print('Some error Occured $e');
    }
    return null;
  }

  Future<User?> signInWithEmailAndPassword(
      String email, String password, BuildContext context) async {
    try {
      UserCredential credential = await _auth.signInWithEmailAndPassword(
          email: email, password: password);
      return credential.user;
    } catch (e) {
      final snackBar = SnackBar(
        content: Text(e.toString().substring(e.toString().indexOf("]") + 2)),
        backgroundColor: const Color.fromARGB(255, 168, 78, 72),
        action: SnackBarAction(
          label: 'ok',
          onPressed: () {
            // Some code to undo the change.
          },
        ),
      );
      ScaffoldMessenger.of(context).showSnackBar(snackBar);

      print('Some error Occured $e');
    }
    return null;
  }
 Future<String?> getUserRole(String uid) async {
    try {
      // Reference to the "users" collection
      CollectionReference users =
          FirebaseFirestore.instance.collection('users');

      // Query the collection to get the user document by UID
      DocumentSnapshot userSnapshot = await users.doc(uid).get();

      // Check if the user document exists
      if (userSnapshot.exists) {
        // Get the user data from the document
        Map<String, dynamic> userData =
            userSnapshot.data() as Map<String, dynamic>;

        // Extract and return the user role
        String? userRole = userData['role'];
        if (userRole != null) {
          // Save user role into SharedPreferences
          SharedPreferences prefs = await SharedPreferences.getInstance();
          await prefs.setString('userRole', userRole);
          return userRole;
        } else {
          return null; // or handle the case where role is not found
        }
      } else {
        // User document not found
        return null; // or handle the case where user document does not exist
      }
    } catch (e) {
      // Handle any errors
      print('Error fetching user role: $e');
      return null; // or handle the error as per your requirement
    }
  }
}
