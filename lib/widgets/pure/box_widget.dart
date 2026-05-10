import 'package:money/helpers/color_helper.dart';
import 'package:money/helpers/constants_helper.dart';
import 'package:money/widgets/pure/icon_button.dart';

const double _defaultPadding = 8;
const double _defaultBoxWidth = 500;
const double _boxBorderRadius = 8;
const double _boxBorderAlpha = 0.5;
const double _copyButtonTopOffset = -10;
const double _footerBottomOffset = -5;
const double _footerRightOffset = 10;
const double _badgeOffsetX = 20;
const double _badgeOffsetY = 0;

/// A stateless widget for box.
class Box extends StatelessWidget {
  Box({
    super.key,
    this.title = '', // optional
    this.header, // optional
    this.footer, // optional
    this.color,
    this.width,
    this.height,
    this.margin,
    this.padding = _defaultPadding,
    this.copyToClipboard,
    required this.child,
  }) {
    assert(
      title.isNotEmpty && header == null || title.isEmpty && header != null || title.isEmpty && header == null,
    );
  }

  final Widget child;
  final Color? color;
  final void Function()? copyToClipboard;
  final Widget? footer;
  final Widget? header;
  final double? height;
  final double? margin;
  final double padding;
  final String title;
  final double? width;

  @override
  Widget build(BuildContext context) {
    EdgeInsetsGeometry? adjustedMargin = margin == null ? null : EdgeInsets.all(margin!);
    // adjust the margin to account for the title bleeding out of the box
    if (title.isNotEmpty || header != null) {
      const EdgeInsets increaseTopMarginBy = EdgeInsets.only(
        top: SizeForPadding.large,
      );
      if (adjustedMargin == null) {
        adjustedMargin = increaseTopMarginBy;
      } else {
        adjustedMargin.add(increaseTopMarginBy);
      }
    }

    return Stack(
      alignment: AlignmentDirectional.topStart,
      children: <Widget>[
        Container(
          width: width,
          height: height,
          margin: adjustedMargin,
          padding: EdgeInsets.all(padding),
          // When width is double.infinity the box fills its parent;
          // minWidth must not be infinity or Flutter asserts, so clamp to 0.
          constraints: BoxConstraints(
            minWidth: (width != null && !width!.isInfinite) ? width! : 0.0,
            maxWidth: width ?? _defaultBoxWidth,
          ),
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.rectangle,
            borderRadius: BorderRadius.circular(_boxBorderRadius), // Bor
            border: Border.all(
              width: 1,
              color: Colors.grey.withValues(alpha: _boxBorderAlpha),
            ),
          ),
          child: child,
        ),
        if (title.isNotEmpty || header != null) _buildBoxHeader(context),
        if (copyToClipboard != null)
          Positioned(
            top: _copyButtonTopOffset,
            right: 0,
            child: _buildCopyToClipboardButton(),
          ),
        if (footer != null)
          Positioned(
            bottom: _footerBottomOffset,
            right: _footerRightOffset,
            child: footer!,
          ),
      ],
    );
  }

  /// Builds a footer Card with selectable text.
  static Widget buildFooter(final String text) => Card(
    elevation: 1,
    shadowColor: Colors.transparent,
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: SizeForPadding.normal),
      child: SelectableText(text),
    ),
  );

  Widget _buildBoxHeader(final BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: SizeForPadding.normal),
    child: IntrinsicWidth(
      child: Card(
        elevation: 1,
        shadowColor: Colors.transparent,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: SizeForPadding.medium,
          ),
          child: title.isEmpty ? header : headerText(context, title),
        ),
      ),
    ),
  );

  Widget _buildCopyToClipboardButton() => Card(
    elevation: 1,
    shadowColor: Colors.transparent,
    child: MyIconButton(
      icon: Icons.copy_all_outlined,
      onPressed: () {
        copyToClipboard?.call();
      },
    ),
  );
}

/// Builds a header widget with title and optional badge counter.
Widget buildHeaderTitleAndCounter(
  final BuildContext context,
  final String title,
  final String badgeText,
) {
  final Widget boxHeader = Badge(
    isLabelVisible: badgeText.isNotEmpty,
    backgroundColor: Theme.of(context).colorScheme.primary,
    offset: const Offset(_badgeOffsetX, _badgeOffsetY),
    label: getBadgeText(badgeText),
    child: Text(title),
  );
  return boxHeader;
}

/// Builds a selectable title text with optional large size.
Widget headerText(
  final BuildContext context,
  final String title, {
  final bool large = false,
}) => SelectableText(
  title,
  style: large ? getTextTheme(context).titleLarge : getTextTheme(context).titleSmall,
  textAlign: TextAlign.center,
);

/// Builds a padded Text widget for badge content.
Widget getBadgeText(final String text) => Padding(
  padding: const EdgeInsets.symmetric(horizontal: SizeForPadding.small),
  child: Text(text, style: const TextStyle(fontSize: SizeForText.small)),
);
