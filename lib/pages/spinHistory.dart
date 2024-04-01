import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SpinHistoryPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Spin History'),
      ),
      body: SpinHistoryList(),
    );
  }
}

class SpinHistoryList extends StatefulWidget {
  @override
  _SpinHistoryListState createState() => _SpinHistoryListState();
}

class _SpinHistoryListState extends State<SpinHistoryList> {
  DateTime? _selectedDate;
  List<DateTime> _dropdownItems = [];
  bool _dropdownEnabled = true;

  int _totalGamesPlayed = 0;
  double _totalRevenue = 0;

  @override
  void initState() {
    super.initState();
    _loadDropdownItems();
    _fetchStats();
  }

  void _loadDropdownItems() {
    DateTime currentDate = DateTime.now();
    for (int i = 0; i < 7; i++) {
      _dropdownItems.add(currentDate.subtract(Duration(days: i)));
    }
    if (_dropdownItems.length == 1) {
      _dropdownEnabled = false;
      _selectedDate = _dropdownItems[0];
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String>(
      future: _loadUserId(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        } else {
          return Column(
            children: [
              _buildStats(),
              _buildDateFilterDropdown(),
              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream: _selectedDate == null
                      ? FirebaseFirestore.instance
                          .collection('users')
                          .doc(snapshot.data)
                          .collection('history')
                          .orderBy('timestamp', descending: true)
                          .snapshots()
                      : FirebaseFirestore.instance
                          .collection('users')
                          .doc(snapshot.data)
                          .collection('history')
                          .where('timestamp',
                              isGreaterThanOrEqualTo: Timestamp.fromDate(
                                  DateTime(
                                      _selectedDate!.year,
                                      _selectedDate!.month,
                                      _selectedDate!.day)))
                          .orderBy('timestamp', descending: true)
                          .snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return Center(child: CircularProgressIndicator());
                    } else if (snapshot.hasError) {
                      return Center(child: Text('Error: ${snapshot.error}'));
                    } else {
                      return ListView.builder(
                        itemCount: snapshot.data!.docs.length,
                        itemBuilder: (context, index) {
                          var data = snapshot.data!.docs[index].data()
                              as Map<String, dynamic>;
                          return ListTile(
                            title: Text('Prize Amount: ${data['prizeAmount']}'),
                            subtitle: Text(
                                'Time: ${_formatTimestamp(data['timestamp'])}'),
                          );
                        },
                      );
                    }
                  },
                ),
              ),
            ],
          );
        }
      },
    );
  }

  Widget _buildStats() {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Total Games Played: $_totalGamesPlayed'),
          Text('Total Revenue: $_totalRevenue'),
          Divider(),
        ],
      ),
    );
  }

  Widget _buildDateFilterDropdown() {
    return DropdownButton<DateTime>(
      hint: Text('Filter by Date'),
      value: _selectedDate,
      onChanged: _dropdownEnabled
          ? (DateTime? newValue) {
              setState(() {
                _selectedDate = newValue;
              });
            }
          : null,
      items: _dropdownItems.map((date) {
        return DropdownMenuItem<DateTime>(
          value: date,
          child: Text(DateFormat('yyyy-MM-dd').format(date)),
        );
      }).toList(),
    );
  }

  String _formatTimestamp(Timestamp timestamp) {
    DateTime dateTime = timestamp.toDate();
    return DateFormat('yyyy-MM-dd HH:mm').format(dateTime);
  }

  Future<String> _loadUserId() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? userId = prefs.getString('userId');
    return userId ?? '';
  }

  Future<void> _fetchStats() async {
    final String userId = await _loadUserId();
    final QuerySnapshot snapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('history')
        .get();

    double totalRevenue = 0;
    for (var doc in snapshot.docs) {
      totalRevenue += (doc['prizeAmount'] as num).toDouble();
    }

    setState(() {
      _totalGamesPlayed = snapshot.docs.length;
      _totalRevenue = totalRevenue;
    });
  }
}
