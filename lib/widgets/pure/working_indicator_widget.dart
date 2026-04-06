import 'package:flutter/cupertino.dart';

const double _defaultIndicatorSize = 40;
const double _radiusScale = 0.5;

/// A stateless widget for working indicator.
class WorkingIndicator extends StatelessWidget {
  const WorkingIndicator({super.key, this.size = _defaultIndicatorSize});

  final double size;

  @override
  Widget build(BuildContext context) {
    // The CupertinoActivityIndicator radius should be size/4 to fit within the bounds
    // since the indicator has some padding around it
    return Center(
      child: SizedBox(
        height: size,
        width: size,
        child: CupertinoActivityIndicator(radius: size * _radiusScale),
      ),
    );
  }
}
