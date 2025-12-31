import 'package:dotted_border/dotted_border.dart';
import 'package:money/helpers/color_helper.dart';
import 'package:money/widgets/gaps.dart';

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
class ColorPalette extends StatelessWidget {
  const ColorPalette({super.key});

  @override
  Widget build(final BuildContext context) {
    return Column(
      children: <Widget>[
        const Divider(),
        const Text('Helper for debugging'),
        _buildColorBar(context, Colors.white, Colors.black, 'white', 'black'),
        _buildColorBar(context, Colors.black, Colors.white, 'black', 'white'),
        _buildColorBar(
          context,
          getColorTheme(context).onSurface,
          getColorTheme(context).surface,
          'onSurface',
          'surface',
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
          'onPrimary',
          'primary',
        ),
        _buildColorBar(
          context,
          getColorTheme(context).onSecondary,
          getColorTheme(context).secondary,
          'onSecondary',
          'secondary',
        ),
        _buildColorBar(
          context,
          getColorTheme(context).onTertiary,
          getColorTheme(context).tertiary,
          'onTertiary',
          'tertiary',
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

  Widget _buildColorBar(
    final BuildContext context,
    final Color foreground,
    final Color background,
    final String colorNameForeground,
    final String colorNameBackground,
  ) {
    return Container(
      margin: const EdgeInsets.all(2),
      child: DottedBorder(
        options: RoundedRectDottedBorderOptions(
          radius: const Radius.circular(3),
          color: Colors.grey.withValues(alpha: 0.5),
        ),

        child: SizedBox(
          width: 300,
          height: 70,
          child: Container(
            margin: const EdgeInsets.all(4),
            color: background,
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: <Widget>[
                      Expanded(child: Container(height: 10, color: foreground)),
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
