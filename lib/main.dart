import 'dart:async';
import 'dart:math';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:confetti/confetti.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_fortune_wheel/flutter_fortune_wheel.dart';
import 'package:flutter_fortune_wheel_example/common/constants.dart';
import 'package:flutter_fortune_wheel_example/common/theme.dart';
import 'package:flutter_fortune_wheel_example/pages/chooseNumber.dart';
import 'package:flutter_fortune_wheel_example/pages/fortune_wheel_history_page.dart';
import 'package:flutter_fortune_wheel_example/pages/fortune_wheel_setting_page.dart';
import 'package:flutter_fortune_wheel_example/widgets/fortune_wheel_background.dart';
import 'package:flutter_fortune_wheel_example/widgets/login.dart';
import 'package:flutter_svg/svg.dart';
import 'package:lottie/lottie.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations(
      [DeviceOrientation.portraitUp, DeviceOrientation.portraitDown]);
  await Firebase.initializeApp(
      options: const FirebaseOptions(
    apiKey: "AIzaSyAOjzOtXeYctkzukPtG5dpe3hBLBoLmjnU",
    projectId: "spin-web-a33fd",
    messagingSenderId: "112722772582",
    appId: "1:112722772582:web:07ea9a2dbad0308afb23a7",
  ));
  runApp(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: appTheme,
      home: const MyApp(),
      title: 'Wheel of Fortune',
    ),
  );
}

class MyApp extends StatefulWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final StreamController<Fortune> _resultWheelController =
      StreamController<Fortune>.broadcast();

  final List<Fortune> _resultsHistory = <Fortune>[];
  final StreamController<bool> _fortuneWheelController =
      StreamController<bool>.broadcast();

  final BackgroundPainterController _painterController =
      BackgroundPainterController();
  final TextEditingController _totalPlayersController = TextEditingController();

  late ConfettiController _confettiController;
  int storedValue = 0;

  Wheel _wheel = Wheel(
    // items: Constants.icons2,
    // items: Constants.liXiNamMoi,
    items: Constants.list12Item,
    isSpinByPriority: true,
    duration: const Duration(seconds: 10),
  );
  String winningValue = "";
  @override
  double totalPlayers = 0.0;
  double _awardedPercent = 0;
  double _awardedPoints = 0;
  String _userId = "";
  bool _pointChecker = false;
  void initState() {
    super.initState();
    _totalPlayersController.text = "10";
    _painterController.playAnimation();
    _confettiController =
        ConfettiController(duration: const Duration(seconds: 10));
    _initializeData(); // Call a new method to ensure everything is properly initialized
  }

  Future<void> _initializeData() async {
    await _loadUserId();
    await _fetchAwardedPercent();
    await _fetchAwardedPoints();
    _pointChecker = _awardedPoints <
        (_wheel.items.length *
            (double.tryParse(_totalPlayersController.text) ?? 0.0) *
            _awardedPoints /
            100);

    setState(() {
      print(_pointChecker);
    }); // Trigger rebuild after data is fetched
  }

  Future<void> _loadUserId() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? userId = prefs.getString('userId');
    setState(() {
      _userId = userId ?? ''; // Update userRole state variable
    });
  }

  @override
  void dispose() {
    super.dispose();
    _resultWheelController.close();
    _fortuneWheelController.close();
    _totalPlayersController.dispose();
    _confettiController.dispose();
  }

  Future<int> loadItemCount() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getInt('itemCount') ?? 0; // Return 0 if itemCount is not found
  }

  @override
  Widget build(BuildContext context) {
    print("Percent: $_awardedPercent");
    print(_pointChecker);

    return Scaffold(
      backgroundColor: const Color(0xFFC3DBF8),
      body: Stack(
        children: [
          Image.asset(
            'assets/images/tablebg.jpg', // Replace 'assets/background_image.jpg' with your image asset path
            fit: BoxFit.cover,
            width: double.infinity,
            height: double.infinity,
          ),
          FortuneWheelBackground(
            painterController: _painterController,
            backgroundColor: Colors.black,
            child: Center(
                child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Container(
                    height: 250,
                    width: 300,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      color: Color.fromARGB(255, 147, 224, 119),
                      boxShadow: [
                        BoxShadow(
                          color: const Color.fromARGB(255, 158, 158, 158)
                              .withOpacity(0.5), // shadow color
                          spreadRadius: 5, // spread radius
                          blurRadius: 7, // blur radius
                          offset: Offset(0, 3), // changes position of shadow
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        const Text(
                          'Stake',
                          style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 28,
                              color: Colors.white),
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            InkWell(
                              onTap: () {
                                FocusScope.of(context).unfocus();
                                int second = int.tryParse(
                                        _totalPlayersController.text) ??
                                    0;
                                if (second > 1) {
                                  second--;

                                  _totalPlayersController.text =
                                      second.toString();
                                  setState(() {});
                                }
                              },
                              child: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                    color: Colors.blue,
                                    borderRadius: BorderRadius.circular(8)),
                                child: Transform.rotate(
                                  angle: pi / 2,
                                  child: const Icon(
                                    Icons.arrow_forward_ios,
                                    color: Colors.white,
                                    size: 20,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              width: 100,
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(8),
                                border:
                                    Border.all(color: Colors.blue, width: 1),
                              ),
                              child: TextField(
                                controller: _totalPlayersController,
                                keyboardType: TextInputType.number,
                                textAlign: TextAlign.center,
                                decoration: const InputDecoration.collapsed(
                                    hintText: 'Enter spin time'),
                                onChanged: (String? value) {
                                  if (value == '') {
                                    _totalPlayersController.text = '1';
                                  }
                                  int? second = int.tryParse(
                                      _totalPlayersController.text);
                                  if (second != null) {}
                                },
                              ),
                            ),
                            const SizedBox(width: 8),
                            InkWell(
                              onTap: () {
                                FocusScope.of(context).unfocus();
                                int second = int.tryParse(
                                        _totalPlayersController.text) ??
                                    0;
                                second++;

                                _totalPlayersController.text =
                                    second.toString();
                                setState(() {});
                              },
                              child: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                    color: Colors.blue,
                                    borderRadius: BorderRadius.circular(8)),
                                child: Transform.rotate(
                                  angle: -pi / 2,
                                  child: const Icon(
                                    Icons.arrow_forward_ios,
                                    color: Colors.white,
                                    size: 20,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text(
                                    "Total Players",
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 18,
                                      color: Color.fromARGB(255, 90, 89, 89),
                                    ),
                                  ),
                                  StreamBuilder<bool>(
                                    stream: _fortuneWheelController.stream,
                                    builder: (context, snapshot) {
                                      var totalPlayers = _wheel.items.length *
                                          (double.tryParse(
                                                  _totalPlayersController
                                                      .text) ??
                                              0.0);

                                      if (snapshot.hasData &&
                                          snapshot.data == true) {
                                        return Text(
                                          _wheel.items.length.toString(),
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 28,
                                            color: Colors.white,
                                          ),
                                        );
                                      } else {
                                        return const SizedBox.shrink();
                                      }
                                    },
                                  ),
                                ],
                              ),
                              const Divider(),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Total Pay Out',
                                    style: TextStyle(
                                      fontSize: 15,
                                      color: Color.fromARGB(255, 122, 121, 121),
                                    ),
                                  ),
                                  StreamBuilder<bool>(
                                    stream: _fortuneWheelController.stream,
                                    builder: (context, snapshot) {
                                      var totalPlayers = _wheel.items.length *
                                              (double.tryParse(
                                                      _totalPlayersController
                                                          .text) ??
                                                  0.0) -
                                          (_wheel.items.length *
                                              (double.tryParse(
                                                      _totalPlayersController
                                                          .text) ??
                                                  0.0) *
                                              _awardedPercent /
                                              100);

                                      if (snapshot.hasData &&
                                          snapshot.data == true) {
                                        return Text(
                                          totalPlayers
                                              .toStringAsFixed(2)
                                              .toString(),
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 28,
                                            color: Colors.white,
                                          ),
                                        );
                                      } else {
                                        return const SizedBox.shrink();
                                      }
                                    },
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    )),
                _buildFortuneWheel(),
                Text(winningValue),
              ],
            )),
          ),
          Align(
            alignment: Alignment.topLeft,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildHeader(),
                _buildResultIsChange(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _fetchAwardedPoints() async {
    final QuerySnapshot pointsSnapshot = await FirebaseFirestore.instance
        .collection('points')
        .where('userId', isEqualTo: _userId)
        .get();
    int totalPoints = 0;
    pointsSnapshot.docs.forEach((DocumentSnapshot doc) {
      totalPoints += (doc['points'] as int? ?? 0);
    });
    print(totalPoints);
    setState(() {
      _awardedPoints = totalPoints as double;
      // Set points in TextField
    });
  }

  Future<void> _fetchAwardedPercent() async {
    final QuerySnapshot pointsSnapshot = await FirebaseFirestore.instance
        .collection('points')
        .where('userId', isEqualTo: _userId)
        .get();
    int totalPoints = 0;
    pointsSnapshot.docs.forEach((DocumentSnapshot doc) {
      totalPoints += (doc['percent'] as int? ?? 0);
    });
    print(totalPoints);
    setState(() {
      _awardedPercent = totalPoints as double;
      // Set points in TextField
    });
  }

  Future<void> _showMyDialog() async {
    TextEditingController _textFieldController = TextEditingController();

    return showDialog<void>(
      context: context,
      barrierDismissible: false, // user must tap button!
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Wheel of Fortune'),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                const Text('Would you like to guess a number?'),
                TextField(
                  controller: _textFieldController,
                )
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Submit'),
              onPressed: () async {
                String enteredNumber = _textFieldController.text;
                // Store the entered number in SharedPreferences
                SharedPreferences prefs = await SharedPreferences.getInstance();
                await prefs.setString('guessedNumber', enteredNumber);
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  Widget _buildHeader() {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.only(right: 8, left: 16),
        child: Row(
          children: [
            SvgPicture.asset(
              'assets/icons/fortune_wheel_icon.svg',
              height: 24,
              width: 24,
            ),
            const SizedBox(width: 16),
            const Text(
              'Wheel of Fortune',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
              ),
            ),
            const Spacer(),
            IconButton(
              splashRadius: 28,
              onPressed: () {
                Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => CircleButtons(wheel: _wheel)));
              },
              icon: const Icon(Icons.add, color: Colors.white),
            ),
            IconButton(
              splashRadius: 28,
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => FortuneWheelHistoryPage(
                      resultsHistory: _resultsHistory,
                    ),
                  ),
                );
              },
              icon: const Icon(Icons.bar_chart, color: Colors.white),
            ),
            IconButton(
              splashRadius: 28,
              onPressed: () async {
                _fortuneWheelController.add(false);
                final Wheel? result = await Navigator.push(
                  context,
                  MaterialPageRoute<Wheel>(
                    builder: (context) =>
                        FortuneWheelSettingPage(wheel: _wheel),
                  ),
                );
                if (result != null) {
                  _wheel = result;
                  _painterController.playAnimation();
                }
                _resultWheelController.sink.add(_wheel.items[0]);
                _fortuneWheelController.add(true);
              },
              icon: const Icon(Icons.settings, color: Colors.white),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFortuneWheel() {
    if (_pointChecker) {
      return Center(
        child: StreamBuilder<bool>(
          stream: _fortuneWheelController.stream,
          builder: (context, snapshot) {
            if (snapshot.data == false) {
              return const SizedBox.shrink();
            }
            return FortuneWheel(
              key: const ValueKey<String>('ValueKeyFortunerWheel'),
              wheel: _wheel,
              onChanged: (Fortune item) {
                _resultWheelController.sink.add(item);
              },
              onResult: _onResult,
            );
          },
        ),
      );
    } else {
      return Text(
        'Oops You are Out of Points !!!!!',
        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
      );
    }
  }

  Future<void> _onResult(Fortune item) async {
    // Retrieve the UID of the user whose points need to be deducted
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? userId = prefs.getString('userId');

    // Calculate the points to deduct
    double pointsToDeduct = _wheel.items.length *
        (double.tryParse(_totalPlayersController.text) ?? 0.0) *
        0.2;

    // Retrieve the user's current balance from Firestore
    QuerySnapshot querySnapshot = await FirebaseFirestore.instance
        .collection('points')
        .where('userId', isEqualTo: userId)
        .get();

    if (querySnapshot.docs.isNotEmpty) {
      // Access the data of the first document in the QuerySnapshot
      DocumentSnapshot documentSnapshot = querySnapshot.docs.first;

      // Access the 'points' field from the document data
      int currentPoints = documentSnapshot['points'] as int;

      // Calculate the new points after deduction
      int newPoints = (currentPoints - pointsToDeduct).toInt();

      // Update the points in Firestore
      await documentSnapshot.reference.update({'points': newPoints});

      // Print the updated points value
      print('Points updated successfully. New points: $newPoints');
    } else {
      print('No documents found for the given query.');
    }
  }

  // Future<void> _onResult(Fortune item) async {
  //   SharedPreferences prefs = await SharedPreferences.getInstance();
  //   String storedValue = prefs.getString('guessedNumber') ?? '';

  //   String message;
  //   setState(() {
  //     winningValue == item.titleName?.replaceAll('\n', '');
  //   });
  //   if (storedValue == item.titleName?.replaceAll('\n', '')) {
  //     message = 'Congratulations! You guessed the correct number!';
  //   } else {
  //     message = 'Oops May be Next Time.';
  //   }

  //   await showDialog(
  //     context: context,
  //     barrierDismissible: false,
  //     builder: (context) {
  //       return AlertDialog(
  //         backgroundColor: Colors.white,
  //         contentPadding: const EdgeInsets.all(8),
  //         content: Column(
  //           mainAxisSize: MainAxisSize.min,
  //           crossAxisAlignment: CrossAxisAlignment.start,
  //           children: [
  //             Align(
  //               alignment: Alignment.center,
  //               child: Text(
  //                 message,
  //                 style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
  //               ),
  //             ),
  //             storedValue == item.titleName?.replaceAll('\n', '')
  //                 ? Container(
  //                     padding: const EdgeInsets.only(top: 20),
  //                     height: 200,
  //                     width: double.infinity,
  //                     child: Lottie.asset(
  //                       'assets/cong_example.json',
  //                       fit: BoxFit.contain,
  //                     ),
  //                   )
  //                 : Align(
  //                     alignment: Alignment.center,
  //                     child: CachedNetworkImage(
  //                       imageUrl:
  //                           'https://media.tenor.com/COXFu_k06msAAAAi/crying-emoji-crying.gif',
  //                       placeholder: (context, url) =>
  //                           CircularProgressIndicator(),
  //                       errorWidget: (context, url, error) => Icon(Icons.error),
  //                       height: 150,
  //                       width: 150,
  //                     ),
  //                   ),
  //             const Padding(
  //               padding: EdgeInsets.only(left: 8.0),
  //               child: Text(
  //                 'Spin value:',
  //                 style: TextStyle(
  //                   fontSize: 18,
  //                   fontWeight: FontWeight.bold,
  //                   color: Color(0xFF1B5E20),
  //                 ),
  //               ),
  //             ),
  //             Align(
  //               alignment: Alignment.center,
  //               child: Container(
  //                 margin: const EdgeInsets.only(top: 16),
  //                 padding:
  //                     const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
  //                 decoration: BoxDecoration(
  //                   color: item.backgroundColor,
  //                   borderRadius: BorderRadius.circular(8),
  //                 ),
  //                 child: Row(
  //                   mainAxisSize: MainAxisSize.min,
  //                   children: [
  //                     Flexible(
  //                       child: Text(
  //                         item.titleName?.replaceAll('\n', '') ?? '',
  //                         style: const TextStyle(
  //                           fontSize: 20,
  //                           color: Colors.white,
  //                         ),
  //                       ),
  //                     ),
  //                     if (item.icon != null)
  //                       Padding(
  //                         padding: const EdgeInsets.only(left: 16),
  //                         child: item.icon,
  //                       ),
  //                   ],
  //                 ),
  //               ),
  //             ),
  //             const SizedBox(height: 16),
  //             Align(
  //               alignment: Alignment.centerRight,
  //               child: TextButton(
  //                 onPressed: () {
  //                   _confettiController.stop();
  //                   Navigator.pop(context);
  //                   _painterController.playAnimation();
  //                 },
  //                 child: const Text(
  //                   'OK',
  //                   style: TextStyle(
  //                     color: Color(0xFF1B5E20),
  //                     fontWeight: FontWeight.bold,
  //                   ),
  //                 ),
  //                 style: ElevatedButton.styleFrom(
  //                   padding: const EdgeInsets.symmetric(horizontal: 16),
  //                 ),
  //               ),
  //             ),

  //             // Display the comparison message
  //           ],
  //         ),
  //       );
  //     },
  //   );
  //   _resultsHistory.add(item);
  // }

  Widget _buildResultIsChange() {
    return StreamBuilder<Fortune>(
      stream: _resultWheelController.stream,
      builder: (context, snapshot) {
        return Padding(
          padding: const EdgeInsets.only(
              top: kIsWeb ? 0 : 16.0, left: 16, right: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Flexible(
                child: Text(
                  snapshot.data != null
                      ? snapshot.data!.titleName?.replaceAll('\n', '') ?? ''
                      : _wheel.items[0].titleName?.replaceAll('\n', '') ?? '',
                  style: TextStyle(
                    fontSize: 24,
                    color: Colors.white.withOpacity(0.7),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(left: 16),
                child: snapshot.data != null
                    ? snapshot.data!.icon ?? const SizedBox()
                    : _wheel.items[0].icon ?? const SizedBox(),
              ),
            ],
          ),
        );
      },
    );
  }

  /// A custom Path to paint stars.
  // Path _drawStar(Size size) {
  //   // Method to convert degree to radians
  //   double degToRad(double deg) => deg * (pi / 180.0);
  //
  //   const numberOfPoints = 5;
  //   final halfWidth = size.width / 2;
  //   final externalRadius = halfWidth;
  //   final internalRadius = halfWidth / 2.5;
  //   final degreesPerStep = degToRad(360 / numberOfPoints);
  //   final halfDegreesPerStep = degreesPerStep / 2;
  //   final path = Path();
  //   final fullAngle = degToRad(360);
  //   path.moveTo(size.width, halfWidth);
  //
  //   for (double step = 0; step < fullAngle; step += degreesPerStep) {
  //     path.lineTo(halfWidth + externalRadius * cos(step),
  //         halfWidth + externalRadius * sin(step));
  //     path.lineTo(halfWidth + internalRadius * cos(step + halfDegreesPerStep),
  //         halfWidth + internalRadius * sin(step + halfDegreesPerStep));
  //   }
  //   path.close();
  //   return path;
  // }
}
