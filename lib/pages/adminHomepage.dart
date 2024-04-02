import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_fortune_wheel_example/pages/userDetails.dart';
import 'package:flutter_fortune_wheel_example/widgets/SignUp.dart';
import 'package:flutter_fortune_wheel_example/widgets/dropdown.dart';
import 'package:flutter_fortune_wheel_example/widgets/login.dart';
import 'package:intl/intl.dart'; // For date formatting
import 'package:csv/csv.dart';
import 'dart:io';

import 'package:flutter_fortune_wheel_example/widgets/percentDropdown.dart';

class Dashboard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Admin Dashboard'),
        actions: [],
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
                  child: UserDropdown(
                    onDetailPressed: (selectedUserId) {
                      Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) =>
                                  UserDetailsPage(userId: selectedUserId)));
                    },
                  ),
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
                  child: Text('Shop Creation'),
                ),
                SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () {
                    Navigator.push(context,
                        MaterialPageRoute(builder: (context) => Login()));
                  },
                  child: Text('Log Out'),
                ),
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

  Future<void> _showUserHistory(BuildContext context, String userId) async {
    // Variables to store selected start and end dates
    DateTime? startDate;
    DateTime? endDate;

    // Function to filter history based on selected dates
    List<Map<String, dynamic>> filterHistory(
        List<Map<String, dynamic>> userHistory) {
      if (startDate != null && endDate != null) {
        return userHistory.where((historyItem) {
          DateTime timestamp = DateTime.parse(historyItem['timestamp']);
          return timestamp.isAfter(startDate!) && timestamp.isBefore(endDate!);
        }).toList();
      } else {
        return userHistory;
      }
    }

    final userHistorySnapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('history')
        .get();

    // Convert the QuerySnapshot to a list of history items
    final userHistory =
        userHistorySnapshot.docs.map((doc) => doc.data()).toList();

    // Show the user history in a dialog
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('User History'),
        content: StatefulBuilder(
          builder: (context, setState) {
            return SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text('Start Date:'),
                      SizedBox(width: 10),
                      DropdownButton<DateTime>(
                        value: startDate,
                        onChanged: (DateTime? newValue) {
                          setState(() {
                            startDate = newValue;
                          });
                        },
                        items: userHistory.map((historyItem) {
                          DateTime timestamp =
                              DateTime.parse(historyItem['timestamp']);
                          return DropdownMenuItem<DateTime>(
                            value: timestamp,
                            child: Text(
                                DateFormat('yyyy-MM-dd').format(timestamp)),
                          );
                        }).toList(),
                      ),
                      SizedBox(width: 20),
                      Text('End Date:'),
                      SizedBox(width: 10),
                      DropdownButton<DateTime>(
                        value: endDate,
                        onChanged: (DateTime? newValue) {
                          setState(() {
                            endDate = newValue;
                          });
                        },
                        items: userHistory.map((historyItem) {
                          DateTime timestamp =
                              DateTime.parse(historyItem['timestamp']);
                          return DropdownMenuItem<DateTime>(
                            value: timestamp,
                            child: Text(
                                DateFormat('yyyy-MM-dd').format(timestamp)),
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                  SizedBox(height: 20),
                  ...filterHistory(userHistory).map((historyItem) {
                    // Customize the display of each history item as needed
                    return ListTile(
                      title:
                          Text('Prize Amount: ${historyItem['prizeAmount']}'),
                      subtitle: Text('Timestamp: ${historyItem['timestamp']}'),
                    );
                  }).toList(),
                ],
              ),
            );
          },
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: Text('Close'),
          ),
          TextButton(
            onPressed: () async {
              // Export filtered history to Excel
              // await _exportToExcel(filterHistory(userHistory));
            },
            child: Text('Export to Excel'),
          ),
        ],
      ),
    );
  }

  // Future<void> _exportToExcel(List<Map<String, dynamic>> data) async {
  //   try {
  //     // Generate a list of lists representing the CSV data
  //     List<List<dynamic>> csvData = [
  //       ['Prize Amount', 'Timestamp']
  //     ];
  //     for (var historyItem in data) {
  //       csvData.add([
  //         historyItem['prizeAmount'].toString(),
  //         historyItem['timestamp'].toString(),
  //       ]);
  //     }

  //     // Convert CSV data to String
  //     String csv = const ListToCsvConverter().convert(csvData);

  //     // Get directory where the CSV file will be saved
  //     final Directory directory = await getExternalStorageDirectory();
  //     final String path = directory.path;

  //     // Write CSV data to a file
  //     final File file = File('$path/user_history.csv');
  //     await file.writeAsString(csv);

  //     // Show a message indicating successful export
  //     showDialog(
  //       context: context,
  //       builder: (context) => AlertDialog(
  //         title: Text('Export Successful'),
  //         content: Text('User history has been exported to CSV file.'),
  //         actions: [
  //           TextButton(
  //             onPressed: () {
  //               Navigator.of(context).pop();
  //             },
  //             child: Text('Close'),
  //           ),
  //         ],
  //       ),
  //     );
  //   } catch (e) {
  //     // Show an error message if export fails
  //     showDialog(
  //       context: context,
  //       builder: (context) => AlertDialog(
  //         title: Text('Export Failed'),
  //         content: Text('Failed to export user history.'),
  //         actions: [
  //           TextButton(
  //             onPressed: () {
  //               Navigator.of(context).pop();
  //             },
  //             child: Text('Close'),
  //           ),
  //         ],
  //       ),
  //     );
  //   }
  // }
}
