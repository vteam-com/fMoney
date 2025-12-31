import 'package:money/constants.dart';
import 'package:money/helpers/color_helper.dart';
import 'package:money/widgets/icon_button.dart';

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
    this.padding = 8,
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
          constraints: BoxConstraints(
            minWidth: width ?? 500,
            maxWidth: width ?? 500,
          ),
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.rectangle,
            borderRadius: BorderRadius.circular(8.0), // Bor
            border: Border.all(
              width: 1,
              color: Colors.grey.withValues(alpha: 0.5),
            ),
          ),
          child: child,
        ),
        if (title.isNotEmpty || header != null) _buildBoxHeader(context),
        if (copyToClipboard != null) Positioned(top: -10, right: 0, child: _buildCopyToClipboardButton()),
        if (footer != null) Positioned(bottom: -5, right: 10, child: footer!),
      ],
    );
  }

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

Widget buildHeaderTitleAndCounter(
  final BuildContext context,
  final String title,
  final String badgeText,
) {
  final Widget boxHeader = Badge(
    isLabelVisible: badgeText.isNotEmpty,
    backgroundColor: Theme.of(context).colorScheme.primary,
    offset: const Offset(20.0, 0),
    label: getBadgeText(badgeText),
    child: Text(title),
  );
  return boxHeader;
}

Widget getBadgeText(final String text) => Padding(
  padding: const EdgeInsets.symmetric(horizontal: SizeForPadding.small),
  child: Text(text, style: const TextStyle(fontSize: SizeForText.small)),
);

class BoxWithScrollingContent extends StatelessWidget {
  const BoxWithScrollingContent({
    super.key,
    required this.children,
    this.height,
  });

  final List<Widget> children;
  final double? height;

  @override
  Widget build(final BuildContext context) => Box(
    color: getColorTheme(context).surface,
    width: 300,
    height: height,
    // height: 300,
    margin: 10,
    child: SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: children,
      ),
    ),
  );
}

Widget headerText(
  final BuildContext context,
  final String title, {
  final bool large = false,
}) => SelectableText(
  title,
  style: large ? getTextTheme(context).titleLarge : getTextTheme(context).titleSmall,
  textAlign: TextAlign.center,
);
