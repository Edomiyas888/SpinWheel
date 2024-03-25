import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_fortune_wheel/flutter_fortune_wheel.dart';
import 'package:flutter_fortune_wheel_example/widgets/fortune_template.dart';

class CircleButtons extends StatefulWidget {
  const CircleButtons({Key? key, required this.wheel}) : super(key: key);

  final Wheel wheel;

  @override
  _CircleButtonsState createState() => _CircleButtonsState();
}

class _CircleButtonsState extends State<CircleButtons> {
  late Wheel _wheel;
  List<bool> _isClicked = List.generate(100, (index) => false);
  late final StreamController<bool> _fortuneValuesController;

  @override
  void initState() {
    super.initState();
    _fortuneValuesController = StreamController<bool>.broadcast();

    _wheel = widget.wheel;
    print(_wheel);
  }

  @override
  void dispose() {
    super.dispose();
    _fortuneValuesController.close();
  }

  List<Fortune> selectedNumbers = <Fortune>[];

  @override
  Widget build(BuildContext context) {
    double screenHeight = MediaQuery.of(context).size.height;
    double buttonSize =
        screenHeight * 0.05; // Adjust button size based on screen width

    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Center(
          child: Container(
            height: screenHeight / 0.5,
            width: MediaQuery.of(context).size.width / 2.7,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFFE8EAF6), Color(0xFFC5CAE9)],
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: GridView.builder(
                    shrinkWrap: true,
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 10,
                      mainAxisSpacing: 8.0,
                      crossAxisSpacing: 8.0,
                    ),
                    itemCount: 100,
                    itemBuilder: (context, index) {
                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            _isClicked[index] = !_isClicked[index];
                            if (_isClicked[index]) {
                              selectedNumbers.add(
                                Fortune(
                                  id: index + 1,
                                  titleName: '${index + 1}',
                                  backgroundColor: Colors
                                      .red, // Adjust the background color as needed
                                  priority: 10, // Adjust the priority as needed
                                ),
                              );
                            } else {
                              selectedNumbers.removeWhere(
                                  (fortune) => fortune.id == index + 1);
                            }
                          });
                        },
                        child: Container(
                          width: buttonSize,
                          height: buttonSize,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: _isClicked[index]
                                ? LinearGradient(
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                    colors: [Colors.redAccent, Colors.red],
                                  )
                                : LinearGradient(
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                    colors: [Colors.black54, Colors.black87],
                                  ),
                          ),
                          child: Center(
                            child: Text(
                              '${index + 1}',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: buttonSize *
                                    0.4, // Adjust font size based on button size
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {
                    for (int i = 0; i < _isClicked.length; i++) {
                      if (_isClicked[i]) {
                        setState(() {
                          selectedNumbers.add(
                            Fortune(
                              id: i + 1,
                              titleName: '${i + 1}',
                              backgroundColor: Colors
                                  .red, // Adjust the background color as needed
                              priority: 10, // Adjust the priority as needed
                            ),
                          );
                        });
                      }
                    }
                    _wheel = _wheel.copyWith(items: selectedNumbers);
                    _fortuneValuesController.sink.add(true);
                    setState(() {
                      _wheel;
                    });
                    // Handle submission logic here
                  },
                  child: Text('Submit'),
                ),
                FortuneTemplate(
                  title: 'd',
                  fortuneValues: selectedNumbers,
                  onPressed: (() {
                    _wheel = _wheel.copyWith(items: selectedNumbers);
                    _fortuneValuesController.sink.add(true);
                    Navigator.pop(context, _wheel);
                  }),
                ),
                StreamBuilder<bool>(
                  stream: _fortuneValuesController.stream,
                  builder: (context, snapshot) {
                    // Rebuild UI based on stream values
                    return Text('Stream Value: ${snapshot.data}');
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
