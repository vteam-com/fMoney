import 'package:flutter/material.dart';
import 'package:money/helpers/app_l10n_service.dart';
import 'package:money/helpers/app_translation_keys.dart';
import 'package:money/helpers/string_helper.dart';
import 'package:money/widgets/components/text_title_widget.dart';
import 'package:money/widgets/pure/gaps_helper.dart';
import 'package:money/widgets/pure/my_svg_widget.dart';

const double _headerPadding = 8.0;
const double _headerSpacing = 16.0;
const double _modelMenuMinWidth = 400.0;
const double _modelItemPadding = 8.0;
const int _modelSelectedAlpha = 100;
const double _modelSelectedRadius = 4.0;
const double _modelItemSpacing = 4.0;
const double _modelSelectedIconSize = 16.0;
const double _modelSizeFont = 10.0;
const int _modelSizeAlpha = 200;
const double _modelIconSize = 20.0;
const double _dropdownIconSize = 16.0;
const double _footerFontSize = 12.0;

/// A stateless widget for view ai header.
class ViewAiHeader extends StatelessWidget {
  const ViewAiHeader({
    required this.availableModels,
    required this.selectedModel,
    required this.onModelSelected,
    required this.onClearChat,
    required this.questionCount,
    required this.contextTokensCount,
    super.key,
  });

  final List<Map<String, dynamic>> availableModels;

  final int contextTokensCount;

  final VoidCallback onClearChat;

  final ValueChanged<String> onModelSelected;

  final int questionCount;

  final String selectedModel;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(_headerPadding),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: <Widget>[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            spacing: _headerSpacing,
            children: <Widget>[
              TextTitle(AppL10n.tr(AppTranslationKeys.aiAssistant)),
              if (availableModels.isNotEmpty)
                PopupMenuButton<String>(
                  constraints: const BoxConstraints(minWidth: _modelMenuMinWidth),
                  onSelected: onModelSelected,
                  itemBuilder: (BuildContext context) => availableModels.map<PopupMenuEntry<String>>((
                    Map<String, dynamic> model,
                  ) {
                    final String modelName = model['name'] as String;
                    final String size = formatByteSize(model['size'] as int);

                    final bool isSelected = modelName == selectedModel;
                    return PopupMenuItem<String>(
                      value: modelName,
                      child: Container(
                        padding: const EdgeInsets.all(_modelItemPadding),
                        decoration: isSelected
                            ? BoxDecoration(
                                color: Theme.of(context).colorScheme.primaryContainer.withAlpha(_modelSelectedAlpha),
                                borderRadius: BorderRadius.circular(_modelSelectedRadius),
                              )
                            : null,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          spacing: _modelItemSpacing,
                          children: <Widget>[
                            Expanded(
                              child: FittedBox(
                                fit: BoxFit.scaleDown,
                                alignment: Alignment.centerLeft,
                                child: Text(
                                  modelName,
                                  textAlign: TextAlign.left,
                                  style: TextStyle(
                                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                    color: isSelected
                                        ? Theme.of(context).colorScheme.primary
                                        : Theme.of(context).colorScheme.onSurface,
                                  ),
                                ),
                              ),
                            ),
                            if (isSelected)
                              Icon(
                                Icons.check,
                                size: _modelSelectedIconSize,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                            Padding(
                              padding: const EdgeInsets.only(left: _modelItemPadding),
                              child: Chip(
                                padding: const EdgeInsets.all(0),
                                backgroundColor: Theme.of(context).colorScheme.surfaceContainerHigh,
                                label: Text(
                                  size,
                                  style: TextStyle(
                                    fontSize: _modelSizeFont,
                                    color: Theme.of(context).colorScheme.onSurfaceVariant.withAlpha(_modelSizeAlpha),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      MySvg(
                        assetName: 'ollama.svg',
                        size: _modelIconSize,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      gapSmall(),
                      Text(
                        selectedModel,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                      Icon(
                        Icons.arrow_drop_down,
                        color: Theme.of(context).colorScheme.primary,
                        size: _dropdownIconSize,
                      ),
                    ],
                  ),
                ),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: <Widget>[
              IconButton(
                onPressed: onClearChat,
                icon: const Icon(Icons.delete_sweep_outlined),
              ),
              if (questionCount > 0 || contextTokensCount > 0)
                Text(
                  AppL10n.tr(
                    AppTranslationKeys.questionsQuestioncountTokensTokencount,
                    params: <String, String>{
                      'questionCount': questionCount.toString(),
                      'tokenCount': formatByteSize(contextTokensCount),
                    },
                  ),
                  style: TextStyle(
                    fontSize: _footerFontSize,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
