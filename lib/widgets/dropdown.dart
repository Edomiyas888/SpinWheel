import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class UserDropdown extends StatefulWidget {
  @override
  _UserDropdownState createState() => _UserDropdownState();
}

class _UserDropdownState extends State<UserDropdown> {
  String? _selectedUserId;
  int _awardedPoints = 0;
  List<DocumentSnapshot> _users = [];
  TextEditingController _pointsController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchUsers();
    _pointsController.addListener(_updateAwardedPoints);
  }

  void _updateAwardedPoints() {
    final newPoints = int.tryParse(_pointsController.text) ?? 0;
    setState(() {
      _awardedPoints = newPoints;
    });
  }

  Future<void> _fetchUsers() async {
    final QuerySnapshot usersSnapshot =
        await FirebaseFirestore.instance.collection('users').get();
    setState(() {
      _users = usersSnapshot.docs;
    });
  }

  Future<void> _fetchAwardedPoints(String userId) async {
    final QuerySnapshot pointsSnapshot = await FirebaseFirestore.instance
        .collection('points')
        .where('userId', isEqualTo: userId)
        .get();
    int totalPoints = 0;
    pointsSnapshot.docs.forEach((DocumentSnapshot doc) {
      totalPoints += (doc['points'] as int? ??
          0); // Explicitly cast and handle null values
    });
    setState(() {
      _awardedPoints = totalPoints;
      _pointsController.text =
          _awardedPoints.toString(); // Set points in TextField
    });
  }

  void _submitPoints() {
    if (_selectedUserId != null && _pointsController.text.isNotEmpty) {
      int points = int.tryParse(_pointsController.text) ?? 0;

      // Check if a document already exists for the selected user
      FirebaseFirestore.instance
          .collection('points')
          .where('userId', isEqualTo: _selectedUserId)
          .get()
          .then((QuerySnapshot querySnapshot) {
        if (querySnapshot.docs.isNotEmpty) {
          // Update the existing document
          FirebaseFirestore.instance
              .collection('points')
              .doc(querySnapshot
                  .docs.first.id) // Access the ID of the first document
              .update({
            'points': points,
            'timestamp': Timestamp.now(),
          }).then((_) {
            _pointsController.clear();
            showDialog(
              context: context,
              builder: (BuildContext context) {
                return AlertDialog(
                  title: Text('Points Updated'),
                  content: Text('Points updated successfully.'),
                  actions: <Widget>[
                    TextButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                      },
                      child: Text('OK'),
                    ),
                  ],
                );
              },
            );
          }).catchError((error) {
            print('Error updating points: $error');
          });
        } else {
          // Add a new document if no document exists for the user
          FirebaseFirestore.instance.collection('points').add({
            'userId': _selectedUserId,
            'points': points,
            'timestamp': Timestamp.now(),
          }).then((_) {
            _pointsController.clear();
            showDialog(
              context: context,
              builder: (BuildContext context) {
                return AlertDialog(
                  title: Text('Points Awarded'),
                  content: Text('Points awarded successfully.'),
                  actions: <Widget>[
                    TextButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                      },
                      child: Text('OK'),
                    ),
                  ],
                );
              },
            );
          }).catchError((error) {
            print('Error adding points: $error');
          });
        }
      }).catchError((error) {
        print('Error fetching points: $error');
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: MediaQuery.of(context).size.width,
      child: Row(
        children: [
          Expanded(
            child: DropdownButtonFormField<String>(
              value: _selectedUserId,
              onChanged: (String? userId) {
                setState(() {
                  _selectedUserId = userId;
                  _fetchAwardedPoints(
                      userId!); // Fetch awarded points when user is selected
                });
              },
              items:
                  _users.map<DropdownMenuItem<String>>((DocumentSnapshot user) {
                return DropdownMenuItem<String>(
                  value: user.id,
                  child: Text(user['username']),
                );
              }).toList(),
              hint: Text('Select a user'),
            ),
          ),
          SizedBox(width: 10),
          Expanded(
            child: TextField(
              controller: _pointsController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Points',
                border: OutlineInputBorder(),
              ),
            ),
          ),
          SizedBox(width: 10),
          ElevatedButton(
            onPressed: _submitPoints,
            child: Text('Submit'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _pointsController.dispose();
    super.dispose();
  }
}
