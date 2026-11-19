import 'package:material_ui/material_ui.dart';

/// Code unit of 'A', the first letter offered by [ListJumpBar].
const int _firstLetterCodeUnit = 0x41;

/// Number of letters offered by [ListJumpBar], 'A' through 'Z'.
const int _letterCount = 26;

/// Width of the jump bar strip.
const double _barWidth = 20;

/// Font size of each letter before any scale-down to fit a short list.
const double _letterFontSize = 11;

/// Smallest height a letter may get; below it the bar hides itself as unreadable.
const double _minLetterHeight = 9;

/// Opacity of letters that have no matching row.
const double _unavailableLetterAlpha = 0.3;

/// Letters offered by [ListJumpBar], in alphabetical order.
final List<String> _letters = List<String>.generate(
  _letterCount,
  (int i) => String.fromCharCode(_firstLetterCodeUnit + i),
  growable: false,
);

/// Maps each letter 'A'–'Z' to the index of the first of [texts] that starts with it, ignoring case and leading spaces.
///
/// Texts starting with anything else (digits, symbols, accented letters) belong to no letter.
Map<String, int> firstIndexByJumpLetter(Iterable<String> texts) {
  final Map<String, int> firstIndexByLetter = <String, int>{};
  int index = 0;
  for (final String text in texts) {
    final String trimmed = text.trimLeft();
    if (trimmed.isNotEmpty) {
      final int letterOffset = trimmed[0].toUpperCase().codeUnitAt(0) - _firstLetterCodeUnit;
      if (letterOffset >= 0 && letterOffset < _letterCount) {
        firstIndexByLetter.putIfAbsent(_letters[letterOffset], () => index);
        if (firstIndexByLetter.length == _letterCount) {
          break;
        }
      }
    }
    index++;
  }
  return firstIndexByLetter;
}

/// A vertical A–Z strip that jumps a list sorted on a text column to the first row of the tapped letter.
///
/// Letters without any row are grayed out and ignore taps. The strip hides itself when
/// there is not enough height to show every letter legibly.
class ListJumpBar extends StatelessWidget {
  const ListJumpBar({
    super.key,
    required this.firstIndexByLetter,
    required this.onJump,
  });

  /// Index of the first row of each letter that has at least one row, see [firstIndexByJumpLetter].
  final Map<String, int> firstIndexByLetter;

  /// Called with the index of the row to bring into view.
  final void Function(int index) onJump;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;
    return LayoutBuilder(
      builder: (BuildContext _, BoxConstraints constraints) {
        if (constraints.maxHeight < _minLetterHeight * _letterCount) {
          return const SizedBox.shrink();
        }
        return SizedBox(
          width: _barWidth,
          child: Column(
            children: <Widget>[
              for (final String letter in _letters) Expanded(child: _buildLetter(letter, colors)),
            ],
          ),
        );
      },
    );
  }

  /// Builds one letter, tappable in the primary color when it has rows, grayed out otherwise.
  Widget _buildLetter(String letter, ColorScheme colors) {
    final int? rowIndex = firstIndexByLetter[letter];
    final Widget label = Center(
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Text(
          letter,
          style: TextStyle(
            fontSize: _letterFontSize,
            fontWeight: FontWeight.bold,
            color: rowIndex == null ? colors.onSurface.withValues(alpha: _unavailableLetterAlpha) : colors.primary,
          ),
        ),
      ),
    );
    if (rowIndex == null) {
      return label;
    }
    return InkWell(onTap: () => onJump(rowIndex), child: label);
  }
}
