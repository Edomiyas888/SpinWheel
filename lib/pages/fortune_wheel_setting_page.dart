import 'dart:async';
import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_fortune_wheel/flutter_fortune_wheel.dart';
import 'package:flutter_fortune_wheel_example/common/constants.dart';
import 'package:flutter_fortune_wheel_example/widgets/SignUp.dart';
import 'package:flutter_fortune_wheel_example/widgets/custom_form_fortune_add_edit.dart';
import 'package:flutter_fortune_wheel_example/widgets/dropdown.dart';
import 'package:flutter_fortune_wheel_example/widgets/fortune_item.dart';
import 'package:flutter_fortune_wheel_example/widgets/fortune_template.dart';
import 'package:flutter_fortune_wheel_example/widgets/login.dart';
import 'package:flutter_fortune_wheel_example/widgets/percentDropdown.dart';
import 'package:shared_preferences/shared_preferences.dart';

typedef void WheelUpdateCallback(int newLength);

class FortuneWheelSettingPage extends StatefulWidget {
  const FortuneWheelSettingPage(
      {Key? key, required this.wheel, required this.localPoints})
      : super(key: key);

  final Wheel wheel;
  final int localPoints;

  @override
  _FortuneWheelSettingPageState createState() =>
      _FortuneWheelSettingPageState();
}

class _FortuneWheelSettingPageState extends State<FortuneWheelSettingPage> {
  late Wheel _wheel;

  final TextEditingController _durationWheelController =
      TextEditingController();

  late final StreamController<bool> _fortuneValuesController;

  final TextEditingController _titleSpinButtonController =
      TextEditingController();
  String _userRole = '';
  String _userId = '';
  int _totalPoints = 0;

  @override
  void initState() {
    super.initState();
    _wheel = widget.wheel;
    _durationWheelController.text = _wheel.duration.inSeconds.toString();
    _titleSpinButtonController.text = _wheel.titleSpinButton ?? '';
    _fortuneValuesController = StreamController<bool>.broadcast();
    _loadUserRole();
    _initializeData();
  }

  Future<void> _initializeData() async {
    await _loadUserId();
    await _fetchAwardedPoints();
    setState(() {}); // Trigger rebuild after data is fetched
  }

  Future<void> _loadUserRole() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? userRole = prefs.getString('userRole');
    setState(() {
      _userRole = userRole ?? ''; // Update userRole state variable
    });
  }

  Future<void> _loadUserId() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? userId = prefs.getString('userId');
    setState(() {
      _userId = userId ?? ''; // Update userRole state variable
    });
  }

  Future<void> _fetchAwardedPoints() async {
    final QuerySnapshot pointsSnapshot = await FirebaseFirestore.instance
        .collection('points')
        .where('userId', isEqualTo: _userId)
        .get();
    int totalPoints = 0;

    pointsSnapshot.docs.forEach((DocumentSnapshot doc) {
      totalPoints += (doc['points'] as int? ??
          0); // Explicitly cast and handle null values
    });
    setState(() {
      _totalPoints = totalPoints;
      // Set points in TextField
    });

    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setInt('totalPoints', totalPoints);
  }

  @override
  void dispose() {
    super.dispose();
    _durationWheelController.dispose();
    _fortuneValuesController.close();
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        _handleConfirmBack();
        return false;
      },
      child: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: Scaffold(
          backgroundColor: const Color(0xFFC8E6C9),
          appBar: AppBar(
            title: const Text('Settings'),
            actions: [
              IconButton(
                splashRadius: 28,
                tooltip: 'Save',
                onPressed: () async {
                  // Pop the current page and pass the updated _wheel as the result
                  setState(() {
                    _wheel;
                  });
                  Navigator.pop(context, _wheel);
                },
                icon: const Icon(Icons.save),
              ),
            ],
          ),
          body: _buildBody(),
        ),
      ),
    );
  }

  Widget _buildBody() {
    print(_totalPoints);
    return SafeArea(
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              _buildGameMode(),
              _buildDuration(),
              Padding(
                padding: const EdgeInsets.all(18.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Remaining Points',
                      style:
                          TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                    ),
                    Text(
                      _totalPoints.toString(),
                      style:
                          TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                    ),
                  ],
                ),
              ),
              _buildEditTitle(),
              _buildExpansionFortuneValues(),
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
        ),
      ),
    );
  }

  void _handleConfirmBack() {
    Widget cancelButton = TextButton(
      child: const Text('Cancel'),
      onPressed: () {
        Navigator.pop(context);
      },
      style: TextButton.styleFrom(
        foregroundColor: Colors.red,
      ),
    );
    Widget okButton = TextButton(
      child: const Text('Confirm'),
      onPressed: () {
        Navigator.pop(context);
        Navigator.pop(context);
      },
      style: TextButton.styleFrom(
        foregroundColor: Colors.blue,
      ),
    );

    AlertDialog alert = AlertDialog(
      title: const Text('Warning'),
      content: const Text(
          'Are you sure you want to go back without saving the changed configuration?'),
      actions: [
        cancelButton,
        okButton,
      ],
    );

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return alert;
      },
    );
  }

  Widget _buildGameMode() {
    return ListTile(
      title: const Text(
        'Spin Mode',
        style: TextStyle(fontWeight: FontWeight.bold),
      ),
      subtitle: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 8),
          ListTile(
            contentPadding: EdgeInsets.zero,
            horizontalTitleGap: 0.0,
            visualDensity: const VisualDensity(vertical: -4, horizontal: 0),
            onTap: () {
              setState(() {
                _wheel = _wheel.copyWith(isSpinByPriority: true);
              });
            },
            title: const Text('The priority mode'),
            leading: Radio<bool>(
              value: true,
              groupValue: _wheel.isSpinByPriority,
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              onChanged: (_) {
                setState(() {
                  _wheel = _wheel.copyWith(isSpinByPriority: true);
                });
              },
            ),
          ),
          ListTile(
            contentPadding: EdgeInsets.zero,
            horizontalTitleGap: 0.0,
            visualDensity: const VisualDensity(vertical: -4, horizontal: 0),
            title: const Text('Random mode'),
            onTap: () {
              setState(() {
                _wheel = _wheel.copyWith(isSpinByPriority: false);
              });
            },
            leading: Radio<bool>(
              value: false,
              groupValue: _wheel.isSpinByPriority,
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              onChanged: (_) {
                setState(() {
                  _wheel = _wheel.copyWith(isSpinByPriority: false);
                });
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDuration() {
    return ListTile(
      title: Row(
        children: [
          const Text(
            'Spin time (s)',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          const Spacer(),
          InkWell(
            onTap: () {
              FocusScope.of(context).unfocus();
              int second = int.tryParse(_durationWheelController.text) ?? 0;
              if (second > 1) {
                second--;
                _wheel = _wheel.copyWith(duration: Duration(seconds: second));
                _durationWheelController.text = second.toString();
                setState(() {});
              }
            },
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                  color: Colors.blue, borderRadius: BorderRadius.circular(8)),
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
              border: Border.all(color: Colors.blue, width: 1),
            ),
            child: TextField(
              controller: _durationWheelController,
              keyboardType: TextInputType.number,
              textAlign: TextAlign.center,
              decoration:
                  const InputDecoration.collapsed(hintText: 'Enter spin time'),
              onChanged: (String? value) {
                if (value == '') {
                  _durationWheelController.text = '1';
                }
                int? second = int.tryParse(_durationWheelController.text);
                if (second != null) {
                  _wheel = _wheel.copyWith(duration: Duration(seconds: second));
                }
              },
            ),
          ),
          const SizedBox(width: 8),
          InkWell(
            onTap: () {
              FocusScope.of(context).unfocus();
              int second = int.tryParse(_durationWheelController.text) ?? 0;
              second++;
              _wheel = _wheel.copyWith(duration: Duration(seconds: second));
              _durationWheelController.text = second.toString();
              setState(() {});
            },
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                  color: Colors.blue, borderRadius: BorderRadius.circular(8)),
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
    );
  }

  Widget _buildEditTitle() {
    return ListTile(
      title: const Text(
        'Spin button title',
        style: TextStyle(fontWeight: FontWeight.bold),
      ),
      subtitle: Padding(
        padding: const EdgeInsets.only(right: 8.0, left: 16),
        child: TextFormField(
          controller: _titleSpinButtonController,
          keyboardType: TextInputType.text,
          onChanged: (value) {
            _wheel = _wheel.copyWith(
              titleSpinButton: _titleSpinButtonController.text,
            );
          },
          decoration: const InputDecoration(
            hintText: 'Enter spin button title',
            hintStyle: TextStyle(color: Colors.grey),
          ),
        ),
      ),
    );
  }

  Widget _buildExpansionFortuneValues() {
    return ExpansionTile(
      initiallyExpanded: true,
      title: const Text(
        'Spin Value',
        style: TextStyle(fontWeight: FontWeight.bold),
      ),
      childrenPadding: const EdgeInsets.only(left: 16),
      children: [
        Row(
          children: [
            Align(
                alignment: Alignment.centerLeft,
                child: ElevatedButton(
                    onPressed: _handleInsertItem,
                    child: const Text('+ Add new'))),
            const SizedBox(width: 16),
            Align(
                alignment: Alignment.centerLeft,
                child: ElevatedButton(
                    onPressed: _handleGetDefaultTemplate,
                    child: const Text('Choose default template'))),
          ],
        ),
        _buildFortuneValues(),
      ],
    );
  }

  Future<void> saveItemCount(int itemCount) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setInt('itemCount', itemCount);
  }

  Future<int> loadItemCount() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getInt('itemCount') ?? 0; // Return 0 if itemCount is not found
  }

  Widget _buildFortuneValues() {
    return StreamBuilder<bool>(
      stream: _fortuneValuesController.stream,
      builder: (context, snapshot) {
        return ListView.separated(
          key: const ValueKey<String>('FortuneValues'),
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _wheel.items.length,
          padding: const EdgeInsets.all(16),
          itemBuilder: (context, index) => FortuneItem(
            key:
                ValueKey<String>('fortuneWheelItem<${_wheel.items[index].id}>'),
            fortune: _wheel.items[index],
            onEditPressed: () => _handleEditFortuneItemPressed(index),
            onDeletePressed: () => _handleDeleteFortuneItemPressed(index),
          ),
          separatorBuilder: (context, index) => const Divider(),
        );
      },
    );
  }

  void _handleGetDefaultTemplate() {
    List<FortuneTemplate> templates = <FortuneTemplate>[
      // FortuneTemplate(
      //   title: 'Lì xì năm mới',
      //   fortuneValues: Constants.liXiNamMoi,
      //   onPressed: () {
      //     _wheel = _wheel.copyWith(items: Constants.liXiNamMoi);
      //     _fortuneValuesController.sink.add(true);
      //     Navigator.pop(context);
      //   },
      // ),
      // FortuneTemplate(
      //   title: 'Ai sẽ phải uống?',
      //   fortuneValues: Constants.actionDrinkBeerList,
      //   onPressed: () {
      //     _wheel = _wheel.copyWith(items: Constants.actionDrinkBeerList);
      //     _fortuneValuesController.sink.add(true);
      //     Navigator.pop(context);
      //   },
      // ),
      // FortuneTemplate(
      //   title: 'Hôm nay ăn gì?',
      //   fortuneValues: Constants.todayWhatDoEat,
      //   onPressed: () {
      //     _wheel = _wheel.copyWith(items: Constants.todayWhatDoEat);
      //     _fortuneValuesController.sink.add(true);
      //     Navigator.pop(context);
      //   },
      // ),
      // FortuneTemplate(
      //   title: 'Yes or No?',
      //   fortuneValues: Constants.yesOrNo,
      //   onPressed: () {
      //     _wheel = _wheel.copyWith(items: Constants.yesOrNo);
      //     _fortuneValuesController.sink.add(true);
      //     Navigator.pop(context);
      //   },
      // ),
      // FortuneTemplate(
      //   title: 'Yêu hoặc không yêu?',
      //   fortuneValues: Constants.loveOrNotLove,
      //   onPressed: () {
      //     _wheel = _wheel.copyWith(items: Constants.loveOrNotLove);
      //     _fortuneValuesController.sink.add(true);
      //     Navigator.pop(context);
      //   },
      // ),
      FortuneTemplate(
        title: 'Random (1- 12)',
        fortuneValues: Constants.list12Item,
        onPressed: () {
          _wheel = _wheel.copyWith(items: Constants.list12Item);
          _fortuneValuesController.sink.add(true);
          Navigator.pop(context);
        },
      ),
      FortuneTemplate(
        title: 'Random number (1- 16)',
        fortuneValues: Constants.numbers,
        onPressed: () {
          _wheel = _wheel.copyWith(items: Constants.numbers);
          _fortuneValuesController.sink.add(true);
          Navigator.pop(context);
        },
      ),
      FortuneTemplate(
        title: 'Random number (1- 100)',
        fortuneValues: Constants.numbers100,
        onPressed: () {
          _wheel = _wheel.copyWith(items: Constants.numbers100);
          _fortuneValuesController.sink.add(true);
          Navigator.pop(context);
        },
      ),
      FortuneTemplate(
        title: 'Random number (1- 160)',
        fortuneValues: Constants.numbers160,
        onPressed: () {
          _wheel = _wheel.copyWith(items: Constants.numbers160);
          _fortuneValuesController.sink.add(true);
          Navigator.pop(context);
        },
      ),
      FortuneTemplate(
        title: 'Select reward (icon)',
        fortuneValues: Constants.icons2,
        onPressed: () {
          _wheel = _wheel.copyWith(items: Constants.icons2);
          _fortuneValuesController.sink.add(true);
          Navigator.pop(context);
        },
      ),
      FortuneTemplate(
        title: 'Icons',
        fortuneValues: Constants.icons,
        onPressed: () {
          _wheel = _wheel.copyWith(items: Constants.icons);
          _fortuneValuesController.sink.add(true);
          Navigator.pop(context);
        },
      ),
    ];
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          title: const Text('Choose default template'),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: templates,
            ),
          ),
          actions: [
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('Cancel'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _handleInsertItem() async {
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          content: CustomFormFortuneAddEdit(
            isInsert: true,
            fortuneItem: Fortune(
              id: _wheel.items.length + 1,
              titleName: '',
              backgroundColor:
                  Colors.primaries[Random().nextInt(Colors.primaries.length)],
            ),
            onChanged: (fortuneItem) {
              _wheel.items.add(fortuneItem);
              _fortuneValuesController.sink.add(true);
              Navigator.pop(context);
            },
          ),
        );
      },
    );
  }

  Future<void> _handleEditFortuneItemPressed(int index) async {
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          content: CustomFormFortuneAddEdit(
            fortuneItem: _wheel.items[index],
            onChanged: (fortuneItem) {
              _wheel.items[index] = fortuneItem;
              _fortuneValuesController.sink.add(true);
              Navigator.pop(context);
            },
          ),
        );
      },
    );
  }

  void _handleDeleteFortuneItemPressed(int index) {
    Widget cancelButton = TextButton(
      child: const Text('Cancel'),
      onPressed: () {
        Navigator.pop(context);
      },
      style: TextButton.styleFrom(
        foregroundColor: Colors.red,
      ),
    );
    Widget okButton = TextButton(
      child: const Text('Confirm'),
      onPressed: () {
        Navigator.pop(context);
        _wheel.items.removeAt(index);
        _fortuneValuesController.sink.add(true);
      },
      style: TextButton.styleFrom(
        foregroundColor: Colors.blue,
      ),
    );

    AlertDialog alert = AlertDialog(
      title: const Text('Warning'),
      content: const Text('Are you sure you want to delete this value?'),
      actions: [
        cancelButton,
        okButton,
      ],
    );

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return alert;
      },
    );
  }
}
