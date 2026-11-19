import 'package:money/data/models/data_object_model.dart';
import 'package:money/helpers/app_l10n_service.dart';
import 'package:money/helpers/app_translation_keys.dart';
import 'package:money/helpers/color_helper.dart';
import 'package:money/helpers/constants_helper.dart';
import 'package:money/shared/domain/data_abstract_interface.dart';
import 'package:money/shared/domain/transfer_entity.dart';
import 'package:money/widgets/dialogs/dialog_button.dart';

const double _sheetMaxHeightFactor = 0.7;
const double _sheetMaxWidth = 1000;
const double _sheetBorderAlpha = 0.3;
const double _sheetBorderWidth = 1;
const double _suggestionGap = 8;

/// Opens the bottom sheet that proposes linking disconnected transactions as transfers.
///
/// [builder] fills the sheet and receives a setter that rebuilds it. The returned future completes when
/// the sheet closes.
Future<void> showPotentialTransferSheet({
  required BuildContext context,
  required StatefulWidgetBuilder builder,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    constraints: const BoxConstraints(maxWidth: _sheetMaxWidth),
    shape: RoundedRectangleBorder(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(SizeForRadius.normal)),
      side: BorderSide(
        color: getColorTheme(context).primary.withValues(alpha: _sheetBorderAlpha),
        width: _sheetBorderWidth,
      ),
    ),
    clipBehavior: Clip.antiAlias,
    builder: (BuildContext sheetContext) {
      final double maxHeight = MediaQuery.of(sheetContext).size.height * _sheetMaxHeightFactor;
      return StatefulBuilder(
        builder: (BuildContext stateContext, StateSetter setSheetState) => SafeArea(
          child: SizedBox(
            height: maxHeight,
            child: Padding(
              padding: const EdgeInsets.all(SizeForPadding.normal),
              child: builder(stateContext, setSheetState),
            ),
          ),
        ),
      );
    },
  );
}

/// Builds one transfer suggestion: a button that links the two legs of [preview] as a transfer, above
/// [previewWidget] showing them. [onConverted] runs once the legs are linked.
Widget buildPotentialTransferCard({
  required Transfer preview,
  required Widget previewWidget,
  required VoidCallback onConverted,
}) {
  return Card(
    child: Padding(
      padding: const EdgeInsets.all(SizeForPadding.medium),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: _suggestionGap,
        children: <Widget>[
          DialogActionButton(
            text: AppL10n.tr(AppTranslationKeys.recordATransferBetweenTwoAccounts),
            onPressed: () {
              final bool didConvert = DataAbstract.instance.convertDisconnectedTransactionsToTransfer(
                transaction: preview.source as DataObject,
                relatedTransaction: preview.relatedTransaction as DataObject,
              );
              if (didConvert) {
                onConverted();
              }
            },
          ),
          previewWidget,
        ],
      ),
    ),
  );
}
