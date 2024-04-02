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
  DateTime? _startDate;
  DateTime? _endDate;
  List<DateTime> _dropdownItems = [];
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
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildDateFilterDropdown(),
                  _buildStatsCard(),
                ],
              ),
              SizedBox(height: 20),
              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream: _startDate == null || _endDate == null
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
                                  DateTime(_startDate!.year, _startDate!.month,
                                      _startDate!.day)),
                              isLessThanOrEqualTo:
                                  Timestamp.fromDate(endOfDay(_endDate!)))
                          .orderBy('timestamp', descending: true)
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
                        scrollDirection: Axis.horizontal,
                        child: DataTable(
                          columns: [
                            DataColumn(label: Text('Prize Amount')),
                            DataColumn(label: Text('Time')),
                          ],
                          rows: snapshot.data!.docs.map((document) {
                            final data =
                                document.data() as Map<String, dynamic>;
                            return DataRow(
                              cells: [
                                DataCell(Text('${data['prizeAmount']}')),
                                DataCell(
                                    Text(_formatTimestamp(data['timestamp']))),
                              ],
                            );
                          }).toList(),
                        ),
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

  Widget _buildStatsCard() {
    return Card(
      margin: EdgeInsets.all(10),
      child: Padding(
        padding: EdgeInsets.all(10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Total Games Played: $_totalGamesPlayed',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            Text(
              'Total Revenue: $_totalRevenue',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDateFilterDropdown() {
    return Column(
      children: [
        Row(
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
                        if (_endDate != null &&
                            _startDate!.isAfter(_endDate!)) {
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
                        if (_startDate != null &&
                            _endDate!.isBefore(_startDate!)) {
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
        ),
        SizedBox(height: 20),
      ],
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
    if (_startDate == null || _endDate == null) return;

    try {
      final String userId = await _loadUserId();
      final QuerySnapshot snapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('history')
          .where('timestamp',
              isGreaterThanOrEqualTo: Timestamp.fromDate(DateTime(
                  _startDate!.year, _startDate!.month, _startDate!.day)),
              isLessThanOrEqualTo: Timestamp.fromDate(endOfDay(_endDate!)))
          .get();

      double totalRevenue = 0;
      for (var doc in snapshot.docs) {
        totalRevenue += (doc['prizeAmount'] as num).toDouble();
      }

      setState(() {
        _totalGamesPlayed = snapshot.docs.length;
        _totalRevenue = totalRevenue;
      });
    } catch (error) {
      print("Error fetching stats: $error");
      // Handle error gracefully, such as showing a snackbar or retry option
    }
  }
}
