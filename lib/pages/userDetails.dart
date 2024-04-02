import 'dart:html' as html;
import 'dart:io';
import 'dart:typed_data';

import 'package:csv/csv.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class UserDetailsPage extends StatefulWidget {
  final String userId;

  UserDetailsPage({required this.userId});

  @override
  _UserDetailsPageState createState() => _UserDetailsPageState();
}

class _UserDetailsPageState extends State<UserDetailsPage> {
  DateTime? _startDate;
  DateTime? _endDate;
  List<DateTime> _dropdownItems = [];
  List<Map<String, dynamic>> userHistory = [];

  bool _dropdownEnabled = true;

  int _totalGamesPlayed = 0;
  double _totalRevenue = 0;

  @override
  void initState() {
    super.initState();
    _loadDropdownItems();
  }

  void _loadDropdownItems() {
    DateTime currentDate = DateTime.now();
    for (int i = 0; i < 7; i++) {
      _dropdownItems.add(currentDate.subtract(Duration(days: i)));
    }
    if (_dropdownItems.length == 1) {
      _dropdownEnabled = false;
      _startDate = _endDate = _dropdownItems[0];
    } else {
      _startDate = _dropdownItems[0];
      _endDate =
          endOfDay(currentDate); // Set today's date as the default end date
    }
    _fetchStats(); // Call fetchStats whenever dropdown values are changed
  }

  DateTime endOfDay(DateTime dateTime) {
    return DateTime(
        dateTime.year, dateTime.month, dateTime.day, 23, 59, 59, 999);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('User Details'),
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDateFilterDropdown(),
            SizedBox(height: 20),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('users')
                    .doc(widget.userId)
                    .collection('history')
                    .where('timestamp',
                        isGreaterThanOrEqualTo: Timestamp.fromDate(DateTime(
                            _startDate!.year,
                            _startDate!.month,
                            _startDate!.day)),
                        isLessThanOrEqualTo:
                            Timestamp.fromDate(endOfDay(_endDate!)))
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Center(child: CircularProgressIndicator());
                  } else if (snapshot.hasError) {
                    return Center(child: Text('Error: ${snapshot.error}'));
                  } else if (snapshot.data!.docs.isEmpty) {
                    return Center(child: Text('No data available'));
                  } else {
                    return SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ...snapshot.data!.docs.map((document) {
                            final data =
                                document.data() as Map<String, dynamic>;
                            return ListTile(
                              title:
                                  Text('Prize Amount: ${data['prizeAmount']}'),
                              subtitle: Text(
                                  'Timestamp: ${_formatTimestamp(data['timestamp'])}'),
                            );
                          }).toList(),
                        ],
                      ),
                    );
                  }
                },
              ),
            ),
            SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton(
                  onPressed: () async {
                    _exportToExcel();
                    // Export to Excel functionality
                  },
                  child: Text('Export to Excel'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  List<Map<String, dynamic>> _filterHistory(
      List<Map<String, dynamic>> userHistory) {
    if (_startDate != null && _endDate != null) {
      return userHistory.where((historyItem) {
        DateTime timestamp = (historyItem['timestamp'] as Timestamp).toDate();
        return timestamp.isAfter(_startDate!) &&
            timestamp.isBefore(_endDate!.add(Duration(days: 1)));
      }).toList();
    } else {
      return userHistory;
    }
  }

  Widget _buildDateFilterDropdown() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        DropdownButton<String>(
          hint: Text('Start Date'),
          value: _startDate != null
              ? DateFormat('yyyy-MM-dd').format(_startDate!)
              : null,
          onChanged: _dropdownEnabled
              ? (String? newValue) {
                  setState(() {
                    _startDate =
                        newValue != null ? DateTime.parse(newValue) : null;
                    if (_endDate != null && _startDate!.isAfter(_endDate!)) {
                      _endDate = _startDate;
                    }
                  });
                  _fetchStats();
                }
              : null,
          items: _dropdownItems.map((date) {
            return DropdownMenuItem<String>(
              value: DateFormat('yyyy-MM-dd').format(date),
              child: Text(DateFormat('yyyy-MM-dd').format(date)),
            );
          }).toList(),
        ),
        DropdownButton<String>(
          hint: Text('End Date'),
          value: _endDate != null
              ? DateFormat('yyyy-MM-dd').format(_endDate!)
              : null,
          onChanged: _dropdownEnabled
              ? (String? newValue) {
                  setState(() {
                    _endDate =
                        newValue != null ? DateTime.parse(newValue) : null;
                    if (_startDate != null && _endDate!.isBefore(_startDate!)) {
                      _startDate = _endDate;
                    }
                  });
                  _fetchStats();
                }
              : null,
          items: _dropdownItems.map((date) {
            return DropdownMenuItem<String>(
              value: DateFormat('yyyy-MM-dd').format(date),
              child: Text(DateFormat('yyyy-MM-dd').format(date)),
            );
          }).toList(),
        ),
      ],
    );
  }

  String _formatTimestamp(Timestamp timestamp) {
    DateTime dateTime = timestamp.toDate();
    return DateFormat('yyyy-MM-dd HH:mm').format(dateTime);
  }

  Future<void> _fetchStats() async {
    // Implement fetching stats based on selected dates
  }

  Future<void> _exportToExcel() async {
    List<List<dynamic>> csvData = [
      ['Prize Amount', 'Timestamp'],
      ..._filterHistory(userHistory).map((historyItem) {
        return [
          historyItem['prizeAmount'],
          historyItem['timestamp'],
        ];
      }).toList(),
    ];

    String csvString = const ListToCsvConverter().convert(csvData);

    final blob = html.Blob([csvString], 'text/csv');
    final url = html.Url.createObjectUrlFromBlob(blob);

    final anchor = html.AnchorElement(href: url)
      ..setAttribute('download', 'user_details.csv')
      ..click();

    html.Url.revokeObjectUrl(url);

    print('User details exported to CSV');
  }
}
