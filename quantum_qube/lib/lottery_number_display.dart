import 'package:flutter/material.dart';

class LotteryNumberDisplay extends StatelessWidget {
  final int number;
  final bool animate;
  final int? digitCount;

  const LotteryNumberDisplay({
    Key? key,
    required this.number,
    this.animate = false,
    this.digitCount,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final digits = number.toString().split('');
    final count = digitCount ?? digits.length;
    final shownDigits = digits.length >= count
        ? digits.sublist(digits.length - count)
        : List.filled(count - digits.length, '0') + digits;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(count, (i) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4.0),
          child: LotteryDigitReel(
            digit: int.parse(shownDigits[i]),
            animate: animate,
            delay: Duration(milliseconds: i * 120),
          ),
        );
      }),
    );
  }
}

class LotteryDigitReel extends StatefulWidget {
  final int digit;
  final bool animate;
  final Duration delay;
  const LotteryDigitReel({Key? key, required this.digit, this.animate = false, this.delay = Duration.zero}) : super(key: key);

  @override
  State<LotteryDigitReel> createState() => _LotteryDigitReelState();
}

class _LotteryDigitReelState extends State<LotteryDigitReel> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _animation = CurvedAnimation(parent: _controller, curve: Curves.easeOutQuart);
    if (widget.animate) {
      Future.delayed(widget.delay, () {
        if (mounted) _controller.forward();
      });
    } else {
      _controller.value = 1.0;
    }
  }

  @override
  void didUpdateWidget(LotteryDigitReel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.digit != widget.digit || oldWidget.animate != widget.animate) {
      _controller.reset();
      if (widget.animate) {
        Future.delayed(widget.delay, () {
          if (mounted) _controller.forward();
        });
      } else {
        _controller.value = 1.0;
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        // Simulate rolling effect by offsetting a column of digits
        final double progress = _animation.value;
        final int start = (10 * progress).floor() % 10;
        final double offset = (progress * 10) % 1.0;
        return ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Container(
            width: 38,
            height: 56,
            color: Colors.black,
            alignment: Alignment.center,
            child: Stack(
              children: [
                Positioned(
                  top: -offset * 56,
                  left: 0,
                  right: 0,
                  child: Column(
                    children: List.generate(11, (i) {
                      int digit = (start + i) % 10;
                      return Container(
                        width: 38,
                        height: 56,
                        alignment: Alignment.center,
                        child: Text(
                          '$digit',
                          style: TextStyle(
                            fontSize: 44,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            shadows: [
                              Shadow(blurRadius: 12, color: Colors.blueAccent, offset: Offset(0, 0)),
                              Shadow(blurRadius: 18, color: Colors.purpleAccent.withOpacity(0.7), offset: Offset(0, 0)),
                            ],
                          ),
                        ),
                      );
                    }),
                  ),
                ),
                // Overlay the final digit when animation is done
                if (progress >= 1.0)
                  Positioned.fill(
                    child: Container(
                      color: Colors.black,
                      alignment: Alignment.center,
                      child: Text(
                        '${widget.digit}',
                        style: TextStyle(
                          fontSize: 44,
                          fontWeight: FontWeight.bold,
                          color: Colors.yellowAccent,
                          shadows: [
                            Shadow(blurRadius: 12, color: Colors.blueAccent, offset: Offset(0, 0)),
                            Shadow(blurRadius: 18, color: Colors.purpleAccent.withOpacity(0.7), offset: Offset(0, 0)),
                          ],
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}
