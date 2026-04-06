import 'package:dotted_border/dotted_border.dart';
import 'package:money/helpers/app_l10n_service.dart';
import 'package:money/helpers/app_translation_keys.dart';
import 'package:money/helpers/color_helper.dart';
import 'package:money/helpers/shared_strings_helper.dart';
import 'package:money/widgets/pure/gaps_helper.dart';

const double _colorBarMargin = 2;
const double _colorBarRadius = 3;
const double _colorBarBorderAlpha = 0.5;
const double _colorBarWidth = 300;
const double _colorBarHeight = 70;
const double _colorBarInnerMargin = 4;
const double _colorBarPadding = 8;
const double _colorBarSampleHeight = 10;

/*
    Color? primary,
    Color? onPrimary,
    Color? primaryContainer,
    Color? onPrimaryContainer,
    Color? secondary,
    Color? onSecondary,
    Color? secondaryContainer,
    Color? onSecondaryContainer,
    Color? tertiary,
    Color? onTertiary,
    Color? tertiaryContainer,
    Color? onTertiaryContainer,
    Color? error,
    Color? onError,
    Color? errorContainer,
    Color? onErrorContainer,
    Color? surface,
    Color? onSurface,
    Color? surfaceVariant,
    Color? onSurfaceVariant,
    Color? outline,
    Color? outlineVariant,
    Color? shadow,
    Color? scrim,
    Color? inverseSurface,
    Color? onInverseSurface,
    Color? inversePrimary,
    Color? surfaceTint,
 */
/// A stateless widget for color palette.
class ColorPalette extends StatelessWidget {
  const ColorPalette({super.key});

  @override
  Widget build(final BuildContext context) {
    return Column(
      children: <Widget>[
        const Divider(),
        Text(AppL10n.tr(AppTranslationKeys.helperForDebugging)),
        _buildColorBar(context, Colors.white, Colors.black, SharedStrings.colorWhite, SharedStrings.colorBlack),
        _buildColorBar(context, Colors.black, Colors.white, SharedStrings.colorBlack, SharedStrings.colorWhite),
        _buildColorBar(
          context,
          getColorTheme(context).onSurface,
          getColorTheme(context).surface,
          SharedStrings.colorOnSurface,
          SharedStrings.colorSurface,
        ),
        _buildColorBar(
          context,
          getColorTheme(context).onInverseSurface,
          getColorTheme(context).inverseSurface,
          'onInverseSurface',
          'inverseSurface',
        ),
        _buildColorBar(
          context,
          getColorTheme(context).onPrimary,
          getColorTheme(context).primary,
          SharedStrings.colorOnPrimary,
          SharedStrings.colorPrimary,
        ),
        _buildColorBar(
          context,
          getColorTheme(context).onSecondary,
          getColorTheme(context).secondary,
          SharedStrings.colorOnSecondary,
          SharedStrings.colorSecondary,
        ),
        _buildColorBar(
          context,
          getColorTheme(context).onTertiary,
          getColorTheme(context).tertiary,
          SharedStrings.colorOnTertiary,
          SharedStrings.colorTertiary,
        ),
        _buildColorBar(
          context,
          getColorTheme(context).onPrimaryContainer,
          getColorTheme(context).primaryContainer,
          'onPrimaryContainer',
          'primaryContainer',
        ),
        _buildColorBar(
          context,
          getColorTheme(context).onSecondaryContainer,
          getColorTheme(context).secondaryContainer,
          'onSecondaryContainer',
          'secondaryContainer',
        ),
        _buildColorBar(
          context,
          getColorTheme(context).onTertiaryContainer,
          getColorTheme(context).tertiaryContainer,
          'onTertiaryContainer',
          'tertiaryContainer',
        ),
        _buildColorBar(
          context,
          getColorTheme(context).onErrorContainer,
          getColorTheme(context).errorContainer,
          'onErrorContainer',
          'errorContainer',
        ),
      ],
    );
  }

  /// Builds a single labeled color swatch showing foreground-on-background contrast.
  Widget _buildColorBar(
    final BuildContext context,
    final Color foreground,
    final Color background,
    final String colorNameForeground,
    final String colorNameBackground,
  ) {
    return Container(
      margin: const EdgeInsets.all(_colorBarMargin),
      child: DottedBorder(
        options: RoundedRectDottedBorderOptions(
          radius: const Radius.circular(_colorBarRadius),
          color: Colors.grey.withValues(alpha: _colorBarBorderAlpha),
        ),

        child: SizedBox(
          width: _colorBarWidth,
          height: _colorBarHeight,
          child: Container(
            margin: const EdgeInsets.all(_colorBarInnerMargin),
            color: background,
            child: Padding(
              padding: const EdgeInsets.all(_colorBarPadding),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: <Widget>[
                      Expanded(
                        child: Container(
                          height: _colorBarSampleHeight,
                          color: foreground,
                        ),
                      ),
                      gapSmall(),
                      Text(
                        colorNameForeground,
                        style: getTextTheme(
                          context,
                        ).bodyMedium!.copyWith(color: foreground),
                      ),
                    ],
                  ),
                  Text(
                    colorNameBackground,
                    style: getTextTheme(
                      context,
                    ).bodyMedium!.copyWith(color: foreground),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
