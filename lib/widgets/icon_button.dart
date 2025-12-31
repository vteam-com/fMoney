import 'package:flutter/material.dart';

// Exports
export 'package:flutter/material.dart';

class MyIconButton extends StatefulWidget {
  const MyIconButton({
    super.key,
    required this.icon,
    required this.onPressed,
    this.hoverColor,
    this.tooltip = '',
    this.size = 18,
  });

  final Color? hoverColor;
  final IconData icon;
  final VoidCallback onPressed;
  final double size;
  final String tooltip;

  @override
  MyIconButtonState createState() => MyIconButtonState();
}

class MyIconButtonState extends State<MyIconButton> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: IconButton(
        padding: EdgeInsets.zero,
        icon: Icon(
          size: widget.size,
          widget.icon,
          color: _isHovered ? widget.hoverColor : null,
        ),
        onPressed: widget.onPressed,
      ),
    );
  }
}
