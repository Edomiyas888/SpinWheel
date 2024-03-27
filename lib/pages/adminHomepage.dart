import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_fortune_wheel_example/widgets/SignUp.dart';
import 'package:flutter_fortune_wheel_example/widgets/dropdown.dart';
import 'package:flutter_fortune_wheel_example/widgets/login.dart';
import 'package:flutter_fortune_wheel_example/widgets/percentDropdown.dart';

class Dashboard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Admin Dashboard'),
        actions: [
          // IconButton(
          //   icon: Icon(Icons.notifications),
          //   onPressed: () {},
          // ),
          // IconButton(
          //   icon: Icon(Icons.settings),
          //   onPressed: () {},
          // ),
        ],
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Overview',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                StreamBuilder(
                  stream: FirebaseFirestore.instance
                      .collection('users')
                      .snapshots(),
                  builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
                    if (!snapshot.hasData) {
                      return CircularProgressIndicator();
                    }
                    int userCount = snapshot.data!.docs.length;
                    return _buildCard(
                      icon: Icons.people,
                      label: 'Users',
                      value: userCount.toString(),
                    );
                  },
                ),
                _buildCard(
                  icon: Icons.shopping_cart,
                  label: 'Points Rewarded',
                  value: '800',
                ),
              ],
            ),
            SizedBox(height: 40),
            Text(
              'Control Panel',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 20),
            Column(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                const Text(
                  'Reward Points',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 24),
                ),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: UserDropdown(),
                ),
                const Text(
                  'Share Percentage',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 24),
                ),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: PercentDropdown(),
                ),
                ElevatedButton(
                    onPressed: (() {
                      Navigator.push(context,
                          MaterialPageRoute(builder: (context) => SignUp()));
                    }),
                    child: Text('Shop Creation')),
                SizedBox(
                  height: 20,
                ),
                ElevatedButton(
                    onPressed: () {
                      Navigator.push(context,
                          MaterialPageRoute(builder: (context) => Login()));
                    },
                    child: Text('Log Out'))
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCard(
      {required IconData icon, required String label, required String value}) {
    return Expanded(
      child: Card(
        elevation: 4,
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                icon,
                size: 36,
                color: Colors.blue,
              ),
              SizedBox(height: 10),
              Text(
                label,
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              Text(
                value,
                style: TextStyle(fontSize: 24),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPointsList() {
    return Expanded(
      child: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('points').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Text('Error: ${snapshot.error}');
          }

          switch (snapshot.connectionState) {
            case ConnectionState.waiting:
              return CircularProgressIndicator();
            default:
              return ListView(
                children: snapshot.data!.docs.map((DocumentSnapshot document) {
                  Map<String, dynamic> data =
                      document.data() as Map<String, dynamic>;
                  String userId = data['userId'];
                  int points = data['points'];
                  return ListTile(
                    title: Text('User ID: $userId'),
                    subtitle: Text('Points: $points'),
                  );
                }).toList(),
              );
          }
        },
      ),
    );
  }
}
