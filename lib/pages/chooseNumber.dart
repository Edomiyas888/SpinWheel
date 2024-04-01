import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_fortune_wheel/flutter_fortune_wheel.dart';
import 'package:flutter_fortune_wheel_example/widgets/custom_form_fortune_add_edit.dart';
import 'package:flutter_fortune_wheel_example/widgets/fortune_item.dart';

class CircleButtons extends StatefulWidget {
  const CircleButtons({Key? key, required this.wheel}) : super(key: key);

  final Wheel wheel;

  @override
  _CircleButtonsState createState() => _CircleButtonsState();
}

class _CircleButtonsState extends State<CircleButtons> {
  late Wheel _wheel = Wheel(items: []);

  List<bool> _isClicked = List.generate(100, (index) => false);
  late final StreamController<bool> _fortuneValuesController;
  List<Fortune> selectedNumbers = <Fortune>[];

  @override
  void initState() {
    super.initState();
    _fortuneValuesController = StreamController<bool>.broadcast();

    // Select and add items 1 and 2 to the wheel initially
    _wheel = widget.wheel;

    // Select items based on their title names from the provided Fortune list
    widget.wheel.items.forEach((fortune) {
      int titleNumber = int.tryParse(fortune.titleName.toString()) ?? 0;
      if (titleNumber > 0 && titleNumber <= 100) {
        _isClicked[titleNumber - 1] = true;
      }
    });
  }

  @override
  void dispose() {
    super.dispose();
    _fortuneValuesController.close();
  }

  @override
  Widget build(BuildContext context) {
    double screenHeight = MediaQuery.of(context).size.height;
    double buttonSize = screenHeight * 0.05;

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
                            // Toggle the clicked state
                            _isClicked[index] = !_isClicked[index];

                            // Determine the background color based on the index and clicked state
                            Color backgroundColor =
                                _isClicked[index] ? Colors.red : Colors.black;

                            // Apply alternating colors
                            if (index % 2 == 1) {
                              backgroundColor =
                                  _isClicked[index] ? Colors.black : Colors.red;
                            }

                            // Handle adding or removing items based on click
                            if (_isClicked[index]) {
                              _handleInsertItem(
                                  Fortune(
                                    id: _wheel.items.length + 1,
                                    titleName: '${index + 1}',
                                    backgroundColor: backgroundColor,
                                    priority: 10,
                                  ), (fortuneItem) {
                                {
                                  setState(() {
                                    _wheel.items.add(fortuneItem);
                                    _fortuneValuesController.sink.add(true);
                                  });
                                }
                              });
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
                                fontSize: buttonSize * 0.4,
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
                  onPressed: () async {
                    int selectedCount =
                        _isClicked.where((clicked) => clicked).length;
                    if (selectedCount >= 2) {
                      List<Fortune> selectedItems = [];
                      bool previousIsRed =
                          false; // Track the color of the previous item

                      // Iterate through the selected numbers
                      for (int i = 0; i < _isClicked.length; i++) {
                        if (_isClicked[i]) {
                          // Convert index to 1-based position
                          int value = i + 1;

                          // Ensure alternating colors for consecutive numbers
                          Color backgroundColor =
                              previousIsRed ? Colors.black : Colors.red;
                          previousIsRed = !previousIsRed;

                          // Add the selected number to the list
                          selectedItems.add(Fortune(
                            id: selectedItems.length + 1,
                            titleName: '$value',
                            backgroundColor: backgroundColor,
                            priority: 10,
                          ));
                        }
                      }

                      // If the number of selected items is odd, make the last item green
                      // If the number of selected items is odd, make the last item green
                      if (selectedCount % 2 == 1) {
                        // Create a new Fortune object with the updated background color
                        Fortune lastItem = selectedItems.last.copyWith(
                          backgroundColor: Colors.green,
                        );
                        // Replace the last item in the list with the updated one
                        selectedItems[selectedItems.length - 1] = lastItem;
                      }

                      // Update the wheel with selected items
                      setState(() {
                        _wheel = Wheel(items: selectedItems);
                      });

                      Navigator.pop(context, _wheel);
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Select at least 2 items')),
                      );
                    }
                  },
                  child: Text('Submit'),
                ),
                StreamBuilder<bool>(
                  stream: _fortuneValuesController.stream,
                  builder: (context, snapshot) {
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

  _handleInsertItem(
      Fortune _fortuneItem, Function(Fortune) onChangedCallback) async {
    setState(() {
      _wheel.items.add(_fortuneItem);
    });
    await CustomFormFortuneAddEdit(
      isInsert: true,
      fortuneItem: _fortuneItem,
      onChanged: (fortuneItem) {
        print('acceptin');
        setState(() {
          _wheel;
        }); // Call the provided onChanged callback
      },
    );

    // Call onChangedCallback immediately after CustomFormFortuneAddEdit
    onChangedCallback(_fortuneItem);
  }
}
