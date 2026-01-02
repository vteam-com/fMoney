import 'package:money/controller/data_controller.dart';
import 'package:money/data/data.dart';
import 'package:money/helpers/string_helper.dart';
import 'package:money/views/dialog/dialog.dart';
import 'package:money/views/dialog/dialog_button.dart';
import 'package:money/widgets/gaps.dart';
import 'package:money/widgets/my_segment.dart';
import 'package:money/widgets/working.dart';

/// Displays a dialog showing pending changes (added, modified, deleted items).
///
/// This dialog allows users to review changes before saving them to SQL or CSV.
/// It presents the changes grouped by type (inserted, changed, deleted) and
/// further categorized by the type of data affected (e.g., accounts, transactions).
class PendingChangesDialog extends StatefulWidget {
  /// Creates a new instance of the [PendingChangesDialog].
  const PendingChangesDialog({super.key});

  @override
  State<PendingChangesDialog> createState() => _PendingChangesDialogState();

  /// Shows the pending changes dialog.
  ///
  /// [context] The build context to use.
  static void show(final BuildContext context) {
    adaptiveScreenSizeDialog(
      context: context,
      title: 'Pending Changes',
      captionForClose: 'Close',
      child: const SizedBox(
        width: 600,
        height: 900,
        child: PendingChangesDialog(),
      ),
      actionButtons: <Widget>[
        DialogActionButton(
          text: 'Save to SQL',
          onPressed: () {
            DataController.to.onSaveToSql();
            Navigator.of(context).pop(true);
          },
        ),
        DialogActionButton(
          text: 'Save to CSV',
          onPressed: () {
            DataController.to.onSaveToCsv();
            Navigator.of(context).pop(true);
          },
        ),
      ],
    );
  }
}

class _PendingChangesDialogState extends State<PendingChangesDialog> {
  /// List of mutation types to display.
  final List<Mutations> _data = <Mutations>[
    Mutations(
      typeOfMutation: MutationType.inserted,
      title: 'added',
      color: Colors.green,
    ),
    Mutations(
      typeOfMutation: MutationType.changed,
      title: 'modified',
      color: Colors.orange,
    ),
    Mutations(
      typeOfMutation: MutationType.deleted,
      title: 'deleted',
      color: Colors.red,
    ),
  ];

  /// Currently selected mutation type index.
  int _displayMutationType = 0;

  /// Indicates whether data is being loaded.
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const WorkingIndicator();
    }
    final Mutations selectedMutationType = _data[_displayMutationType];
    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        _buildColumnSelection(),
        gapLarge(),
        _buildSubSegmentsButtons(selectedMutationType),
        gapLarge(),
        Expanded(
          child: _buildListOfDetailsOfSelectedGroup(selectedMutationType),
        ),
      ],
    );
  }

  /// Builds the segment selection for mutation types (added, modified, deleted).
  Widget _buildColumnSelection() {
    return Center(
      child: mySegmentSelector(
        context: context,
        segments: <ButtonSegment<int>>[
          _buildSegment(0, _data[0]),
          _buildSegment(1, _data[1]),
          _buildSegment(2, _data[2]),
        ],
        selectedId: _displayMutationType,
        onSelectionChanged: (final int newSelection) {
          setState(() {
            _displayMutationType = newSelection;
          });
        },
      ),
    );
  }

  /// Builds the list of details for the selected mutation group.
  Widget _buildListOfDetailsOfSelectedGroup(Mutations mutations) {
    if (mutations.selectedGroup >= mutations.mutationGroups.length) {
      return Center(child: Text('No items were ${mutations.title}'));
    }

    final MutationGroup g = mutations.mutationGroups[mutations.selectedGroup];

    return ListView.separated(
      itemCount: g.whatWasMutated.length,
      itemBuilder: (BuildContext context, int index) {
        return g.whatWasMutated[index];
      },
      separatorBuilder: (BuildContext context, int index) {
        return const Divider();
      },
    );
  }

  /// Builds a segment button for a specific mutation type.
  ButtonSegment<int> _buildSegment(final int id, Mutations mutations) {
    return ButtonSegment<int>(
      value: id,
      label: SizedBox(
        width: 120,
        child: Text(
          mutations.fullTitle,
          textAlign: TextAlign.center,
          style: TextStyle(color: mutations.color),
        ),
      ),
    );
  }

  /// Builds the sub-segment buttons for selecting specific data groups within a mutation type.
  Widget _buildSubSegmentsButtons(Mutations mutations) {
    final List<Widget> groupSelectors = <Widget>[];

    for (int i = 0; i < mutations.mutationGroups.length; i++) {
      final MutationGroup group = mutations.mutationGroups[i];
      final Container w = Container(
        padding: const EdgeInsets.only(bottom: 4),
        child: Badge(
          backgroundColor: mutations.color,
          label: Text(getIntAsText(group.whatWasMutated.length)),
          child: InputChip(
            label: Text(group.title),
            selected: i == mutations.selectedGroup,
            onSelected: (bool value) {
              setState(() {
                mutations.selectedGroup = i;
              });
            },
          ),
        ),
      );

      groupSelectors.add(w);
    }

    return Wrap(spacing: 10, runSpacing: 10, children: groupSelectors);
  }

  /// Loads the mutation data.
  void _load() {
    for (final Mutations m in _data) {
      m.initMutationList();
    }
    setState(() {
      _isLoading = false;

      // default to the first segment that has a count
      for (int i = 0; i < _data.length; i++) {
        if (_data[i].count > 0) {
          _displayMutationType = i;
          break;
        }
      }
    });
  }
}

/// Represents a group of mutations of a specific type (e.g., added accounts, modified transactions).
class Mutations {
  /// Constructs a new instance of the [Mutations] class.

  Mutations({
    required this.typeOfMutation,
    required this.title,
    required this.color,
  });

  /// The color associated with this mutation type.
  final Color color;

  /// The number of mutations in this group.
  int count = 0;

  /// The list of mutation groups within this type.
  List<MutationGroup> mutationGroups = <MutationGroup>[];

  /// The currently selected group within this type.
  int selectedGroup = 0;

  /// The title of this mutation type (e.g., "added", "modified").
  final String title;

  /// The type of mutation (inserted, changed, deleted).
  final MutationType typeOfMutation;

  /// Returns a formatted title including the count of mutations.
  String get fullTitle {
    if (count == 0) {
      return 'None $title';
    }
    return '${getIntAsText(count)} $title';
  }

  /// Initializes the list of mutations.
  void initMutationList() {
    count = 0;
    mutationGroups = Data().getMutationGroups(typeOfMutation);

    for (final MutationGroup m in mutationGroups) {
      count += m.whatWasMutated.length;
    }
  }
}
