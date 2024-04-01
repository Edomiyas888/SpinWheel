import 'dart:async';
import 'dart:html' as html; // Import dart:html

import 'dart:math';
import 'package:audioplayers/audioplayers.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:confetti/confetti.dart';
import 'package:connectivity/connectivity.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_fortune_wheel/flutter_fortune_wheel.dart';
import 'package:flutter_fortune_wheel_example/common/constants.dart';
import 'package:flutter_fortune_wheel_example/common/theme.dart';
import 'package:flutter_fortune_wheel_example/pages/adminHomepage.dart';
import 'package:flutter_fortune_wheel_example/pages/chooseNumber.dart';
import 'package:flutter_fortune_wheel_example/pages/fortune_wheel_history_page.dart';
import 'package:flutter_fortune_wheel_example/pages/fortune_wheel_setting_page.dart';
import 'package:flutter_fortune_wheel_example/pages/spinHistory.dart';
import 'package:flutter_fortune_wheel_example/widgets/fortune_wheel_background.dart';
import 'package:flutter_fortune_wheel_example/widgets/login.dart';
import 'package:flutter_fortune_wheel_example/widgets/prizeCircle.dart';
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
      home: MyApp(),
      title: 'Spin to win',
    ),
  );
}

class MyApp extends StatefulWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late AudioPlayer player = AudioPlayer();

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
    items: Constants.list36Item,
    isSpinByPriority: true,
    duration: const Duration(seconds: 10),
  );
  int winningValue = 0;
  @override
  double totalPlayers = 0.0;
  double _awardedPercent = 0;
  double _awardedPoints = 0;
  String _userId = "";
  bool _pointChecker = false;
  ValueNotifier<bool> _pointCheckerNotifier = ValueNotifier<bool>(false);
  int _totalPoints = 0;
  int _localPoints = 0;
  late Timer _connectionTimer;
  late bool _hasConnection; // Initially assuming there's a connection

  void initState() {
    super.initState();
    _totalPoints = _awardedPoints as int;
    _loadTotalPoints();
    _timer = Timer.periodic(Duration(seconds: 10), (timer) {
      setState(() {
        _pointCheckerNotifier;
      });
    });
    _hasConnection = true; // Assume there's a connection initially
    _startConnectionCheck();
    _totalPlayersController.text = "10";
    _painterController.playAnimation();
    _confettiController =
        ConfettiController(duration: const Duration(seconds: 10));
    _initializeData();
    player = AudioPlayer();

    // Set the release mode to keep the source after playback has completed.
    player.setReleaseMode(ReleaseMode.stop);

    // Start the player as soon as the app is displayed.
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await player.setSource(
          AssetSource('assets/Sounds/bike-back-wheel-coasting-74816.mp3'));
      await player.resume();
    });
    // Call a new method to ensure everything is properly initialized
  }

  late Timer _timer;
  PlayerState? _playerState;
  Future<void> _startConnectionCheck() async {
    var connectivityResult = await Connectivity().checkConnectivity();
    _updateConnectionStatus(
        connectivityResult); // Update connection status based on initial check

    Connectivity().onConnectivityChanged.listen((ConnectivityResult result) {
      _updateConnectionStatus(
          result); // Update connection status when connectivity changes
    });
  }

  void _updateConnectionStatus(ConnectivityResult result) {
    setState(() {
      _hasConnection = result != ConnectivityResult.none;
    });
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
    _pointCheckerNotifier.value = _pointChecker; // Update the ValueNotifier
    print("purew$_pointChecker");

    setState(() {
      // Call setState to trigger a rebuild after updating _pointChecker
    });
  }

  Future<void> _loadUserId() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? userId = prefs.getString('userId');
    setState(() {
      _userId = userId ?? ''; // Update userRole state variable
    });
  }

  final AudioPlayer _audioPlayer = AudioPlayer();

  Future<void> _loadTotalPoints() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    int? totalPoints = prefs.getInt('totalPoints');
    setState(() {
      _totalPoints = totalPoints ?? 0;
      _localPoints = totalPoints ?? 0;
    });
  }

  @override
  void dispose() {
    super.dispose();
    _resultWheelController.close();
    _fortuneWheelController.close();
    _totalPlayersController.dispose();
    _timer.cancel();
    _confettiController.dispose();
  }

  Future<int> loadItemCount() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getInt('itemCount') ?? 0; // Return 0 if itemCount is not found
  }

  @override
  Widget build(BuildContext context) {
    print("connection: $_hasConnection");
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
                Column(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    Container(
                        height: 250,
                        width: 300,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(20),
                          color: Color.fromARGB(255, 205, 15, 15),
                          boxShadow: [
                            BoxShadow(
                              color: const Color.fromARGB(255, 158, 158, 158)
                                  .withOpacity(0.5), // shadow color
                              spreadRadius: 5, // spread radius
                              blurRadius: 7, // blur radius
                              offset:
                                  Offset(0, 3), // changes position of shadow
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
                                    if (second > 10) {
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
                                    border: Border.all(
                                        color: Colors.blue, width: 1),
                                  ),
                                  child: TextField(
                                    controller: _totalPlayersController,
                                    keyboardType: TextInputType.number,
                                    inputFormatters: <TextInputFormatter>[
                                      FilteringTextInputFormatter
                                          .digitsOnly // Allow only digits
                                    ],
                                    textAlign: TextAlign.center,
                                    decoration: const InputDecoration.collapsed(
                                        hintText: 'Enter Stake'),
                                    onChanged: (String? value) {
                                      if (value == '') {
                                        _totalPlayersController.text =
                                            '10'; // Set default value to 10 if empty
                                      } else {
                                        int? second = int.tryParse(value!);
                                        if (second != null && second <= 10) {
                                          // If entered value is less than or equal to 10, set it to 11
                                          _totalPlayersController.text = '11';
                                        }
                                      }
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
                                          color: Color.fromARGB(
                                              255, 255, 255, 255),
                                        ),
                                      ),
                                      StreamBuilder<bool>(
                                        stream: _fortuneWheelController.stream,
                                        builder: (context, snapshot) {
                                          totalPlayers = _wheel.items.length *
                                              (double.tryParse(
                                                      _totalPlayersController
                                                          .text) ??
                                                  0.0);

                                          if (snapshot.hasData &&
                                              snapshot.data == true) {
                                            return Text(
                                              _wheel.items.length.toString(),
                                              style: const TextStyle(
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
                                  // Row(
                                  //   mainAxisAlignment:
                                  //       MainAxisAlignment.spaceBetween,
                                  //   children: [
                                  //     Text(
                                  //       'Total Pay Out',
                                  //       style: TextStyle(
                                  //         fontSize: 15,
                                  //         color: Colors.white,
                                  //       ),
                                  //     ),
                                  //     StreamBuilder<bool>(
                                  //       stream: _fortuneWheelController.stream,
                                  //       builder: (context, snapshot) {
                                  //         var totalPlayers = _wheel
                                  //                     .items.length *
                                  //                 (double.tryParse(
                                  //                         _totalPlayersController
                                  //                             .text) ??
                                  //                     0.0) -
                                  //             (_wheel.items.length *
                                  //                 (double.tryParse(
                                  //                         _totalPlayersController
                                  //                             .text) ??
                                  //                     0.0) *
                                  //                 _awardedPercent /
                                  //                 100);

                                  //         if (snapshot.hasData &&
                                  //             snapshot.data == true) {
                                  //           print(_awardedPercent / 100);
                                  //           return Text(
                                  //             totalPlayers
                                  //                 .toStringAsFixed(2)
                                  //                 .toString(),
                                  //             style: TextStyle(
                                  //               fontWeight: FontWeight.bold,
                                  //               fontSize: 28,
                                  //               color: Colors.white,
                                  //             ),
                                  //           );
                                  //         } else {
                                  //           return const SizedBox.shrink();
                                  //         }
                                  //       },
                                  //     ),
                                  //   ],
                                  // ),
                                ],
                              ),
                            ),
                          ],
                        )),
                    StreamBuilder<bool>(
                        stream: _fortuneWheelController.stream,
                        builder: (context, snapshot) {
                          var totalPlayers = _wheel.items.length *
                                  (double.tryParse(
                                          _totalPlayersController.text) ??
                                      0.0) -
                              (_wheel.items.length *
                                  (double.tryParse(
                                          _totalPlayersController.text) ??
                                      0.0) *
                                  _awardedPercent /
                                  100);
                          print("Snapshot Data: ${snapshot.data}");
                          print("Prize Amount: $totalPlayers");

                          if (snapshot.hasData && snapshot.data == true) {
                            print(_awardedPercent / 100);
                            return PrizeCircle(
                                prizeAmount: _wheel.items.length *
                                        (double.tryParse(
                                                _totalPlayersController.text) ??
                                            0.0) -
                                    (_wheel.items.length *
                                        (double.tryParse(
                                                _totalPlayersController.text) ??
                                            0.0) *
                                        _awardedPercent /
                                        100));
                          } else {
                            return const SizedBox.shrink();
                          }
                        })
                  ],
                ),
                ValueListenableBuilder<bool>(
                  valueListenable: _pointCheckerNotifier,
                  builder: (context, _pointChecker, _) {
                    print("Local Points:$_localPoints");

                    return _pointChecker
                        ? _buildFortuneWheel()
                        : const Text(
                            'Oops You are out of Points or check Connection',
                            style: TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                                color: Colors.white),
                          );
                  },
                ),
                //Text(winningValue),
                Container(
                  width: 250, // Adjust the width as needed
                  height: 250, // Adjust the height as needed
                  decoration: BoxDecoration(
                    boxShadow: [
                      BoxShadow(
                        color: const Color.fromARGB(255, 158, 158, 158)
                            .withOpacity(0.5), // shadow color
                        spreadRadius: 5, // spread radius
                        blurRadius: 7, // blur radius
                        offset: Offset(0, 3), // changes position of shadow
                      ),
                    ],
                    shape: BoxShape.circle,
                    color: Color.fromARGB(255, 0, 0, 0).withOpacity(
                        1), // Change the background color as needed
                  ),
                  child: Center(child: _buildResultIsChange()),
                ),
              ],
            )),
          ),
          Align(
            alignment: Alignment.topLeft,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildHeader(),
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

    int totalPercent = 0;

    pointsSnapshot.docs.forEach((DocumentSnapshot doc) {
      final dynamic percent = doc['percent'];
      print("as$percent");
      if (percent != null) {
        totalPercent += percent as int ?? 0;
      }
    });

    print("de$totalPercent"); // Add this line to check the totalPoints value

    setState(() {
      _awardedPercent = totalPercent.toDouble();
    });
  }

  Future<void> _showMyDialog() async {
    TextEditingController _textFieldController = TextEditingController();

    return showDialog<void>(
      context: context,
      barrierDismissible: false, // user must tap button!
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Spin to win'),
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
              'Spin to win',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
              ),
            ),
            const Spacer(),
            IconButton(
              onPressed: () async {
                _fortuneWheelController.add(false);
                final Wheel? result = await Navigator.push(
                  context,
                  MaterialPageRoute<Wheel>(
                    builder: (context) => CircleButtons(wheel: _wheel),
                  ),
                );
                if (result != null) {
                  _wheel = result;
                  _painterController.playAnimation();
                }
                _resultWheelController.sink.add(_wheel.items[0]);
                _fortuneWheelController.add(true);
              },
              icon: const Icon(Icons.add, color: Colors.white),
            ),
            IconButton(
              splashRadius: 28,
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => SpinHistoryPage(),
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
                    builder: (context) => FortuneWheelSettingPage(
                      wheel: _wheel,
                      localPoints: _localPoints,
                    ),
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
    return Center(
      child: StreamBuilder<ConnectivityResult>(
        stream: Connectivity().onConnectivityChanged,
        builder: (context, snapshot) {
          if (snapshot.data == ConnectivityResult.none) {
            // Hide the page content if there's no network connectivity
            return SizedBox.shrink();
          } else {
            // Render the fortune wheel if there's network connectivity
            return _totalPoints > 0 &&
                    _localPoints > 0 &&
                    _awardedPercent != 0 &&
                    _hasConnection
                ? FortuneWheel(
                    key: const ValueKey<String>('ValueKeyFortunerWheel'),
                    wheel: _wheel,
                    onChanged: (Fortune item) {
                      _resultWheelController.sink.add(item);
                      winningValue = int.parse(
                          item.titleName?.replaceAll('\n', '') ?? '0');
                    },
                    onResult: _onResult,
                  )
                : _checkNetworkConnectivity();
          }
        },
      ),
    );
  }

  Widget _checkNetworkConnectivity() {
    return StreamBuilder<ConnectivityResult>(
      stream: Connectivity().onConnectivityChanged,
      builder: (context, snapshot) {
        if (snapshot.data == ConnectivityResult.none) {
          return SizedBox
              .shrink(); // This will make the wheel disappear when there's no network connection
        } else {
          return Text(
            'No Network!',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          );
        }
      },
    );
  }

  Future<void> _onResult(Fortune item) async {
    // Check connectivity
    var connectivityResult = await Connectivity().checkConnectivity();

    // Your existing logic for processing the spin result
    print("Local Points:$_localPoints");
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? userId = prefs.getString('userId');
    double pointsToDeduct = _wheel.items.length *
        (double.tryParse(_totalPlayersController.text) ?? 0.0) *
        _awardedPercent /
        100;
    QuerySnapshot querySnapshot = await FirebaseFirestore.instance
        .collection('points')
        .where('userId', isEqualTo: userId)
        .get();
    SharedPreferences pref = await SharedPreferences.getInstance();
    int? totalPoints = prefs.getInt('totalPoints');
    int newTotalPoints = (totalPoints ?? 0) - pointsToDeduct.toInt();
    await prefs.setInt('totalPoints', newTotalPoints);
    if (querySnapshot.docs.isNotEmpty && _localPoints > 0) {
      DocumentSnapshot documentSnapshot = querySnapshot.docs.first;
      int currentPoints = documentSnapshot['points'] as int;
      int newPoints = (currentPoints - pointsToDeduct).toInt();
      await documentSnapshot.reference.update({'points': newPoints});
      print('Points updated successfully. New points: $newPoints');
      setState(() {
        _totalPoints = newPoints;
      });
      Timestamp timestamp = Timestamp.now();
      await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('history')
          .add({
        'prizeAmount': totalPlayers * _awardedPercent / 100,
        'timestamp': timestamp,
      });
    }
    //  else if (querySnapshot.docs.isNotEmpty && _localPoints < 0) {
    //   DocumentSnapshot documentSnapshot = querySnapshot.docs.first;
    //   await documentSnapshot.reference.update({'points': _localPoints});
    // }
    else {
      setState(() {
        _localPoints = -1;
        _play;
      });
      print('Zmblesh nwe');
    }
    setState(() {});
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
  Future<void> _play() async {
    await player.resume();
    setState(() => _playerState = PlayerState.playing);
  }

  Widget _buildResultIsChange() {
    return StreamBuilder<Fortune>(
      stream: _resultWheelController.stream,
      builder: (context, snapshot) {
        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Flexible(
              child: Text(
                snapshot.data != null
                    ? snapshot.data!.titleName?.replaceAll('\n', '') ?? ''
                    : _wheel.items[0].titleName?.replaceAll('\n', '') ?? '',
                style: TextStyle(
                  fontSize: 80,
                  color: Color.fromARGB(255, 255, 255, 255),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            snapshot.data != null
                ? snapshot.data!.icon ?? const SizedBox()
                : _wheel.items[0].icon ?? const SizedBox(),
          ],
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
