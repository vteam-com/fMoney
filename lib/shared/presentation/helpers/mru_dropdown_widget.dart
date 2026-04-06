import 'package:flutter/material.dart';
import 'package:money/helpers/app_router_service.dart';
import 'package:money/helpers/constants_helper.dart';
import 'package:money/helpers/date_helper.dart';
import 'package:money/helpers/file_systems_service.dart';
import 'package:money/helpers/shared_strings_helper.dart';
import 'package:money/shared/presentation/providers/data_file_controller_provider.dart';
import 'package:money/shared/presentation/services/app_scope_service.dart';
import 'package:money/widgets/pickers/picker_panel.dart';
import 'package:money/widgets/pickers/token_text_widget.dart';
import 'package:money/widgets/state/preferences_controller.dart';
import 'package:money/widgets/widgets_domain/data_source_model.dart';

const double _mruDropdownWidth = 600.0;
const double _timestampOpacity = 0.5;
const double _timestampFontSize = 12.0;

/// A stateless widget for mru dropdown.
class MruDropdown extends StatelessWidget {
  const MruDropdown({super.key});

  /// Builds the MRU file dropdown and loads the selected file.
  @override
  Widget build(BuildContext context) {
    final TokenTextStyle tokenStyle = TokenTextStyle(
      separator: MyFileSystems.pathSeparator,
      separatorPaddingLeft: SizeForPadding.nano,
      separatorPaddingRight: SizeForPadding.nano,
    );
    final AppServices services = AppScope.of(context);
    final PreferenceController preferenceController = services.preferenceController;
    final DataFileController dataController = DataFileController.to;

    return SingleChildScrollView(
      reverse: true,
      scrollDirection: Axis.horizontal,
      child: ListenableBuilder(
        listenable: Listenable.merge(<Listenable>[
          preferenceController,
          dataController.currentLoadedFileName,
          dataController.currentLoadedFileDateTime,
        ]),
        builder: (BuildContext context, Widget? _) {
          return Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: <Widget>[
              InkWell(
                key: Constants.keyMruButton,
                onTap: () {
                  showPopupSelection(
                    context: context,
                    title: SharedStrings.labelRecentFiles,
                    showLetterPicker: false,
                    tokenTextStyle: tokenStyle,
                    rightAligned: true,
                    width: _mruDropdownWidth,
                    items: preferenceController.mru,
                    selectedItem: '',
                    onSelected:
                        (
                          final String selectedTextRepresentingFileNamePath,
                        ) async {
                          final DataSource dataSource = DataSource(
                            filePath: selectedTextRepresentingFileNamePath,
                          );
                          await DataFileController.to.loadFileFromPath(dataSource);
                          AppRouter.pushNamedAndRemoveUntil<dynamic>(Constants.routeHomePage);
                        },
                  );
                },
                child: Row(
                  children: <Widget>[
                    TokenText(
                      dataController.currentLoadedFileName.value,
                      style: tokenStyle,
                    ),
                    const Icon(Icons.expand_more),
                  ],
                ),
              ),
              _buildTimeStampOfFile(
                dataController.currentLoadedFileDateTime.value,
              ),
            ],
          );
        },
      ),
    );
  }

  /// Builds a relative timestamp label for the currently loaded file.
  Widget _buildTimeStampOfFile(final DateTime? dataSourceTimeStamp) {
    if (dataSourceTimeStamp == null) {
      return const SizedBox();
    } else {
      return Tooltip(
        message: dateToDateTimeString(dataSourceTimeStamp),
        child: Opacity(
          opacity: _timestampOpacity,
          child: Text(
            getElapsedTime(dataSourceTimeStamp),
            textAlign: TextAlign.left,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: _timestampFontSize, fontWeight: FontWeight.bold),
          ),
        ),
      );
    }
  }
}
