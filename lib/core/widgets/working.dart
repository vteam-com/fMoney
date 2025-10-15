import 'package:flutter/cupertino.dart';

class WorkingIndicator extends StatelessWidget {
  const WorkingIndicator({super.key, this.size = 40});

  final double size;

  @override
  Widget build(BuildContext context) {
    // The CupertinoActivityIndicator radius should be size/4 to fit within the bounds
    // since the indicator has some padding around it
    return Center(
      child: SizedBox(
        height: size,
        width: size,
        child: CupertinoActivityIndicator(radius: size / 2),
      ),
    );
  }
}
