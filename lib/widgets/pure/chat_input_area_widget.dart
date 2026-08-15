import 'package:money/helpers/app_l10n_service.dart';
import 'package:money/helpers/app_translation_keys.dart';
import 'package:money/helpers/color_helper.dart';
import 'package:money/helpers/shared_strings_helper.dart';

const double _inputPadding = 16.0;
const double _inputSpacing = 8.0;
const int _outlineAlpha = 100;
const double _inputRadius = 24.0;
const double _inputHorizontalPadding = 16.0;
const double _inputVerticalPadding = 12.0;
const double _accountsDropdownVerticalPadding = 10.0;

/// A stateful widget for chat input area.
class ChatInputArea extends StatefulWidget {
  const ChatInputArea({
    super.key,

    required this.onSendPrompt,
    required this.isProcessing,
    required this.onCancel,
    required this.inputController,
    required this.accountGroupsByLabel,
    required this.selectedAccountIds,
    required this.selectAllAccounts,
    required this.onToggleAccountSelection,
    required this.onToggleSelectAllAccounts,
  });

  /// Available account options grouped by account type label.
  ///
  /// Key: group label, value: map of account id to account label.
  final Map<String, Map<int, String>> accountGroupsByLabel;

  /// Controls the text input for the prompt.
  final TextEditingController inputController;

  /// Whether the AI is currently processing a request.
  final bool isProcessing;

  /// Called to cancel the current request.
  final VoidCallback onCancel;

  /// Called when the user sends a prompt.
  final ValueChanged<String> onSendPrompt;

  /// Called when a specific account selection is toggled.
  final ValueChanged<int> onToggleAccountSelection;

  /// Called when the "All" option is selected.
  final VoidCallback onToggleSelectAllAccounts;

  /// True when all accounts are selected.
  final bool selectAllAccounts;

  /// Selected account ids when [selectAllAccounts] is false.
  final Set<int> selectedAccountIds;

  /// Creates state for the chat input area.
  @override
  State<ChatInputArea> createState() => _ChatInputAreaState();
}

/// Special keyword to indicate transaction-related prompts.
const String chatKeywordTransaction = '#transaction';
const String _menuSelectAllValue = '__all_accounts__';

class _ChatInputAreaState extends State<ChatInputArea> {
  /// Builds the input area with quick prompts and send/cancel actions.
  @override
  Widget build(BuildContext context) {
    final List<MapEntry<String, Map<int, String>>> nonEmptyAccountGroups = widget.accountGroupsByLabel.entries
        .where((MapEntry<String, Map<int, String>> group) => group.value.isNotEmpty)
        .toList();
    final Set<int> availableAccountIds = nonEmptyAccountGroups
        .expand((MapEntry<String, Map<int, String>> group) => group.value.keys)
        .toSet();
    final int totalAccountCount = availableAccountIds.length;
    final int selectedAccountCount = widget.selectAllAccounts
        ? totalAccountCount
        : widget.selectedAccountIds.where(availableAccountIds.contains).length;
    final String accountLabel = selectedAccountCount == 1
        ? AppL10n.tr(AppTranslationKeys.account).toLowerCase()
        : AppL10n.tr(AppTranslationKeys.accounts).toLowerCase();
    final String accountsCaption = widget.selectAllAccounts
        ? '${AppL10n.tr(AppTranslationKeys.allLabel)} ${AppL10n.tr(AppTranslationKeys.accounts).toLowerCase()}'
        : '$selectedAccountCount $accountLabel';

    return Container(
      padding: const EdgeInsets.all(_inputPadding),
      decoration: BoxDecoration(
        color: getColorTheme(context).surfaceContainer,
        border: Border(
          top: BorderSide(color: getColorTheme(context).outline.withAlpha(_outlineAlpha)),
        ),
      ),
      child: Column(
        spacing: _inputSpacing,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Wrap(
            spacing: _inputSpacing,
            runSpacing: _inputSpacing,
            children: <Widget>[
              ElevatedButton(
                onPressed: () {
                  widget.onSendPrompt(AppL10n.tr(AppTranslationKeys.accountNames));
                },
                child: Text(AppL10n.tr(AppTranslationKeys.accountNames)),
              ),
              ElevatedButton(
                onPressed: () {
                  widget.onSendPrompt(AppL10n.tr(AppTranslationKeys.largestTransactions));
                },
                child: Text(AppL10n.tr(AppTranslationKeys.largestTransactions)),
              ),
              ElevatedButton(
                onPressed: () => widget.onSendPrompt(AppL10n.tr(AppTranslationKeys.analyzeSpending)),
                child: Text(AppL10n.tr(AppTranslationKeys.analyzeSpending)),
              ),
              ElevatedButton(
                onPressed: () => widget.onSendPrompt(AppL10n.tr(AppTranslationKeys.expensePredictions)),
                child: Text(AppL10n.tr(AppTranslationKeys.expensePredictions)),
              ),
            ],
          ),
          Row(
            spacing: _inputSpacing,
            children: <Widget>[
              PopupMenuButton<String>(
                onSelected: (String selectedValue) {
                  if (selectedValue == _menuSelectAllValue) {
                    widget.onToggleSelectAllAccounts();
                    return;
                  }

                  final int? accountId = int.tryParse(selectedValue);
                  if (accountId != null) {
                    widget.onToggleAccountSelection(accountId);
                  }
                },
                itemBuilder: (BuildContext _) {
                  final List<PopupMenuEntry<String>> items = <PopupMenuEntry<String>>[
                    CheckedPopupMenuItem<String>(
                      value: _menuSelectAllValue,
                      checked: widget.selectAllAccounts,
                      child: Text(AppL10n.tr(AppTranslationKeys.allLabel)),
                    ),
                    const PopupMenuDivider(),
                  ];

                  if (nonEmptyAccountGroups.isEmpty) {
                    items.add(
                      PopupMenuItem<String>(
                        enabled: false,
                        child: Text(AppL10n.tr(AppTranslationKeys.noAccountSelectedPeriod)),
                      ),
                    );
                    return items;
                  }

                  for (int groupIndex = 0; groupIndex < nonEmptyAccountGroups.length; groupIndex++) {
                    final MapEntry<String, Map<int, String>> group = nonEmptyAccountGroups[groupIndex];
                    items.add(
                      PopupMenuItem<String>(
                        enabled: false,
                        child: Text(group.key),
                      ),
                    );

                    items.addAll(
                      group.value.entries.map(
                        (MapEntry<int, String> option) => CheckedPopupMenuItem<String>(
                          value: option.key.toString(),
                          checked: widget.selectAllAccounts || widget.selectedAccountIds.contains(option.key),
                          child: Text(option.value),
                        ),
                      ),
                    );

                    final bool isLastGroup = groupIndex == nonEmptyAccountGroups.length - 1;
                    if (!isLastGroup) {
                      items.add(const PopupMenuDivider());
                    }
                  }

                  return items;
                },
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    border: Border.all(color: getColorTheme(context).outline),
                    borderRadius: BorderRadius.circular(_inputRadius),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: _inputHorizontalPadding,
                      vertical: _accountsDropdownVerticalPadding,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        Text(accountsCaption),
                        const Icon(Icons.arrow_drop_down),
                      ],
                    ),
                  ),
                ),
              ),
              Expanded(
                child: TextField(
                  controller: widget.inputController,
                  decoration: InputDecoration(
                    hintText: SharedStrings.aiAssistantHint,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(_inputRadius),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: _inputHorizontalPadding,
                      vertical: _inputVerticalPadding,
                    ),
                    filled: true,
                    fillColor: getColorTheme(context).surface,
                  ),
                  onSubmitted: widget.onSendPrompt,
                ),
              ),

              if (widget.isProcessing)
                IconButton(
                  onPressed: widget.onCancel,
                  icon: Icon(Icons.cancel, color: getColorTheme(context).primary),
                )
              else
                IconButton(
                  onPressed: () {
                    final String text = widget.inputController.text;
                    if (text.isNotEmpty) {
                      widget.onSendPrompt(text);
                    }
                  },
                  icon: Icon(Icons.send, color: getColorTheme(context).primary),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
