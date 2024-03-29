import 'package:flutter/material.dart';

class PrizeCircle extends StatefulWidget {
  final double prizeAmount;

  const PrizeCircle({Key? key, required this.prizeAmount}) : super(key: key);

  @override
  _PrizeCircleState createState() => _PrizeCircleState();
}

class _PrizeCircleState extends State<PrizeCircle>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  late double _currentPrizeAmount; // Track the current prize amount

  @override
  void initState() {
    super.initState();
    _currentPrizeAmount = widget.prizeAmount; // Initialize current prize amount
    _controller =
        AnimationController(vsync: this, duration: Duration(seconds: 2));
    _animation = Tween<double>(begin: 0, end: widget.prizeAmount)
        .animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut))
      ..addListener(() {
        setState(() {});
      });

    _controller.forward();
  }

  @override
  void didUpdateWidget(covariant PrizeCircle oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Check if the prize amount has changed
    if (widget.prizeAmount != _currentPrizeAmount) {
      _currentPrizeAmount =
          widget.prizeAmount; // Update the current prize amount
      // Restart the animation with the new prize amount
      _controller.reset();
      _controller.forward();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 200,
        height: 200,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [
              Color(0xFF00FF00),
              Color(0xFF00AA00),
            ],
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 10,
              spreadRadius: 5,
            ),
          ],
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  "Prize Money",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    Text(
                      "\ ${_animation.value.toStringAsFixed(2)} ",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 30,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}
