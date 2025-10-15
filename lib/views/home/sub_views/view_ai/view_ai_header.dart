import 'package:flutter/material.dart';
import 'package:money/core/helpers/string_helper.dart';
import 'package:money/core/widgets/gaps.dart';
import 'package:money/core/widgets/my_svg.dart';
import 'package:money/core/widgets/text_title.dart';

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
  final String selectedModel;
  final ValueChanged<String> onModelSelected;
  final VoidCallback onClearChat;
  final int questionCount;
  final int contextTokensCount;

  @override
  Widget build(final BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: <Widget>[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            spacing: 16,
            children: <Widget>[
              const TextTitle('AI Assistant'),
              if (availableModels.isNotEmpty)
                PopupMenuButton<String>(
                  constraints: const BoxConstraints(minWidth: 400),
                  onSelected: onModelSelected,
                  itemBuilder: (final BuildContext context) =>
                      availableModels.map<PopupMenuEntry<String>>((final Map<String, dynamic> model) {
                        final String modelName = model['name'] as String;
                        final String size = formatByteSize(model['size'] as int);

                        final bool isSelected = modelName == selectedModel;
                        return PopupMenuItem<String>(
                          value: modelName,
                          child: Container(
                            padding: const EdgeInsets.all(8.0),
                            decoration: isSelected
                                ? BoxDecoration(
                                    color: Theme.of(context).colorScheme.primaryContainer.withAlpha(100),
                                    borderRadius: BorderRadius.circular(4.0),
                                  )
                                : null,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              spacing: 4,
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
                                    size: 16,
                                    color: Theme.of(context).colorScheme.primary,
                                  ),
                                Padding(
                                  padding: const EdgeInsets.only(left: 8.0),
                                  child: Chip(
                                    padding: const EdgeInsets.all(0),
                                    backgroundColor: Theme.of(context).colorScheme.surfaceContainerHigh,
                                    label: Text(
                                      size,
                                      style: TextStyle(
                                        fontSize: 10,
                                        color: Theme.of(context).colorScheme.onSurfaceVariant.withAlpha(200),
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
                        size: 20,
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
                        size: 16,
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
                  'Questions: $questionCount | Tokens: ${formatByteSize(contextTokensCount)}',
                  style: TextStyle(
                    fontSize: 12,
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
