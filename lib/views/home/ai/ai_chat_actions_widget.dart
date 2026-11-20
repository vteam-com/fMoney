import 'package:material_ui/material_ui.dart';
import 'package:money/data/models/ai_chat_action_model.dart';
import 'package:money/helpers/constants_helper.dart';
import 'package:money/widgets/state/preferences_controller.dart';

/// Space between the action buttons.
const double _actionSpacing = 8.0;

/// The buttons under an AI answer that open the views it offered; nothing opens until the user clicks.
class AiChatActions extends StatelessWidget {
  /// Creates the buttons for [actions].
  const AiChatActions({super.key, required this.actions});

  /// The views offered, one button each.
  final List<AiChatAction> actions;

  /// Builds one outlined button per action, wrapping onto new lines when narrow.
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: _actionSpacing),
      child: Wrap(
        spacing: _actionSpacing,
        runSpacing: _actionSpacing,
        children: <Widget>[
          for (final AiChatAction action in actions)
            OutlinedButton.icon(
              icon: Icon(action.viewId.getIconData()),
              label: Text(action.label),
              onPressed: () => PreferenceController.to.jumpToView(
                viewId: action.viewId,
                selectedId: action.selectedId,
                textFilter: action.textFilter,
                columnFilters: action.columnFilters,
              ),
            ),
        ],
      ),
    );
  }
}
