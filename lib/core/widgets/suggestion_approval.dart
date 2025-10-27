import 'package:money/core/widgets/icon_button.dart';
import 'package:money/core/widgets/working.dart';

class SuggestionApproval extends StatefulWidget {
  const SuggestionApproval({
    super.key,
    required this.onApproved,
    required this.onChooseCategory,
    required this.onShowSplit,
    required this.child,
  });

  final Widget child;

  /// Optional - Approval button will show if there's a callback function
  final void Function()? onApproved;

  /// Optional - Dropdown button
  final void Function(BuildContext)? onChooseCategory;

  /// Optional - for Split Transaction
  final void Function()? onShowSplit;

  @override
  SuggestionApprovalState createState() => SuggestionApprovalState();
}

class SuggestionApprovalState extends State<SuggestionApproval> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;

  late Animation<double> _opacityAnimation;

  bool approved = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );

    _opacityAnimation = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 1.0, curve: Curves.ease),
      ),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.onShowSplit != null) {
      return InkWell(
        onTap: () => widget.onShowSplit?.call(),
        child: widget.child,
      );
    }

    final double opacity = widget.onApproved == null ? 1 : 0.6;

    if (approved) {
      return const WorkingIndicator(size: 10);
    }
    return FadeTransition(
      opacity: _opacityAnimation,
      child: Opacity(
        opacity: opacity,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: <Widget>[
            Expanded(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: IntrinsicWidth(child: widget.child),
              ),
            ),

            /// Optional Accept Suggestion
            if (widget.onApproved != null)
              MyIconButton(
                icon: Icons.thumb_up,
                tooltip: 'Approve category',
                hoverColor: Colors.green,
                onPressed: _fadeOutAndApproved,
              ),

            // Optional Dropdown button
            if (widget.onChooseCategory != null)
              MyIconButton(
                icon: Icons.arrow_drop_down,
                tooltip: 'Select a category',
                hoverColor: Colors.blue,
                onPressed: () {
                  if (context.mounted) {
                    widget.onChooseCategory?.call(context);
                  }
                },
              ),
          ],
        ),
      ),
    );
  }

  void _fadeOutAndApproved() {
    _animationController.forward().then((_) {
      setState(() {
        approved = true;
      });
      if (widget.onApproved != null) {
        Future<void>.delayed(
          const Duration(milliseconds: 10),
          () => widget.onApproved!(),
        );
      }
    });
  }
}
