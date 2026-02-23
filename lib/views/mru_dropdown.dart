import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:money/helpers/constants.dart';
import 'package:money/helpers/date_helper.dart';
import 'package:money/helpers/file_systems.dart';
import 'package:money/views/data_file_controller.dart';
import 'package:money/widgets/data_source.dart';
import 'package:money/widgets/picker_panel.dart';
import 'package:money/widgets/preferences_controller.dart';
import 'package:money/widgets/token_text.dart';

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
    final PreferenceController preferenceController = Get.find();
    final DataFileController dataController = Get.find();

    return SingleChildScrollView(
      reverse: true,
      scrollDirection: Axis.horizontal,
      child: Obx(() {
        return Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: <Widget>[
            InkWell(
              key: Constants.keyMruButton,
              onTap: () {
                showPopupSelection(
                  context: context,
                  title: 'Recent files',
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
                        Get.offAllNamed<dynamic>(Constants.routeHomePage);
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
      }),
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
