// ignore_for_file: unnecessary_this
import 'package:money/data/models/field_type.dart';
import 'package:money/helpers/app_l10n.dart';
import 'package:money/helpers/app_translation_keys.dart';
import 'package:money/helpers/constants.dart';
import 'package:money/helpers/json_helper.dart';
import 'package:money/helpers/list_helper.dart';
import 'package:money/helpers/ranges.dart';
import 'package:money/providers/data_abstract.dart';
import 'package:money/providers/field_definition_cache.dart';
import 'package:money/widgets/adaptive_list/list_item_card.dart';
import 'package:money/widgets/picker_category.dart';
import 'package:money/widgets/picker_edit_box_date.dart';
import 'package:money/widgets/pure/mutation_types.dart';
import 'package:money/widgets/token_text.dart';
import 'package:money/widgets/widgets_domain/data_interface.dart';
import 'package:money/widgets/widgets_domain/data_object.dart';
import 'package:money/widgets/widgets_domain/field.dart';

/// Represents event.
class Event extends DataObject {
  /// Private constructor for static fields only
  Event._static({
    required final int id,
    required final String name,
    final int categoryId = -1,
    required final DateTime? dateBegin,
    required final DateTime? dateEnd,
    required final String people,
    required final String memo,
  }) : data = null {
    this.fieldId.value = id;
    this.fieldName.value = name;
    this.fieldCategoryId.value = categoryId;
    this.fieldDateBegin.value = dateBegin;
    this.fieldDateEnd.value = dateEnd;
    this.fieldPeople.value = people;
    this.fieldMemo.value = memo;
  }

  Event({
    required final int id,
    required final String name,
    final int categoryId = -1,
    required final DateTime? dateBegin,
    required final DateTime? dateEnd,
    required final String people,
    required final String memo,
    required this.data,
  }) {
    this.fieldId.value = id;
    this.fieldName.value = name;
    this.fieldCategoryId.value = categoryId;
    this.fieldDateBegin.value = dateBegin;
    this.fieldDateEnd.value = dateEnd;
    this.fieldPeople.value = people;
    this.fieldMemo.value = memo;
  }

  /// Constructor from a SQLite row
  factory Event.fromJson(final MyJson row, final DataAbstract data) {
    return Event(
      id: row.getInt('Id', -1),
      name: row.getString('Name'),
      categoryId: row.getInt('Category', -1),
      dateBegin: row.getDate('Begin'),
      dateEnd: row.getDate('End'),
      people: row.getString('People'),
      memo: row.getString('Memo'),
      data: data,
    );
  }

  /// Category Id
  FieldInt fieldCategoryId = FieldInt(
    type: FieldType.widget,
    align: TextAlign.left,
    footer: FooterType.count,
    name: 'Category',
    serializeName: 'Category',
    defaultValue: -1,
    getValueForDisplay: (final DataInterface instance) {
      final Event event = instance as Event;
      return event.data!.getCategoryWidget(event.fieldCategoryId.value);
    },

    sort: (final DataInterface a, final DataInterface b, final bool ascending) => sortByString(
      (a as Event).categoryName,
      (b as Event).categoryName,
      ascending,
    ),

    getValueForReading: (final DataInterface instance) => (instance as Event).categoryName,
    getValueForSerialization: (final DataInterface instance) => (instance as Event).fieldCategoryId.value,
    setValue: (final DataInterface instance, dynamic newValue) =>
        (instance as Event).fieldCategoryId.value = newValue as int,
    getEditWidget:
        (
          final DataInterface instance,
          void Function(bool /* wasModified */) onEdited,
        ) {
          final Event event = instance as Event;
          return pickerCategory(
            key: const Key('key_pick_category'),
            categoryNames: event.data!.getCategoriesAsStrings(),
            selectedName: event.data!.getCategoryNameFromId(event.fieldCategoryId.value),
            onSelected: (String? name) {
              final int? newId = event.data!.getCategoryIdFromName(name!);
              if (newId != null) {
                instance.fieldCategoryId.value = newId;
                // notify container
                onEdited(true);
              }
            },
          );
        },
  );

  /// Date Begin
  FieldDate fieldDateBegin = _createDateField(
    'Begins',
    'Begin',
    (Event event) => event.fieldDateBegin,
  );

  /// Date End
  FieldDate fieldDateEnd = _createDateField(
    'Ends',
    'End',
    (Event event) => event.fieldDateEnd,
  );

  FieldString fieldDuration = FieldString(
    name: 'Duration',
    align: TextAlign.center,
    columnWidth: ColumnWidth.small,
    getValueForDisplay: (final DataInterface instance) => (instance as Event).durationAsString,
    sort: (final DataInterface a, final DataInterface b, final bool ascending) => sortByValue(
      (a as Event).durationInDays,
      (b as Event).durationInDays,
      ascending,
    ),
  );

  /// ID
  FieldId fieldId = FieldId(
    getValueForSerialization: (final DataInterface instance) => (instance as Event).uniqueId,
  );

  /// Memo
  FieldString fieldMemo = FieldString(
    name: 'Memo',
    serializeName: 'Memo',
    columnWidth: ColumnWidth.large,
    getValueForDisplay: (final DataInterface instance) => (instance as Event).fieldMemo.value,
    getValueForSerialization: (final DataInterface instance) => (instance as Event).fieldMemo.value,
  );

  /// Name
  FieldString fieldName = FieldString(
    name: 'Name',
    serializeName: 'Name',
    type: FieldType.widget,
    getValueForDisplay: (final DataInterface instance) => TokenText((instance as Event).eventName),
    getValueForSerialization: (final DataInterface instance) => (instance as Event).fieldName.value,
    setValue: (final DataInterface instance, dynamic value) => (instance as Event).fieldName.value = value as String,
    sort: (final DataInterface a, final DataInterface b, final bool ascending) => sortByString(
      (a as Event).fieldName.value,
      (b as Event).fieldName.value,
      ascending,
    ),
  );

  /// People
  FieldString fieldPeople = FieldString(
    name: 'People',
    serializeName: 'People',
    getValueForDisplay: (final DataInterface instance) => (instance as Event).fieldPeople.value,
    getValueForSerialization: (final DataInterface instance) => (instance as Event).fieldPeople.value,
  );

  int possibleMatchingCategoryId = -1;

  final DataAbstract? data;

  @override
  Widget buildFieldsAsWidgetForSmallScreen() {
    return MyListItemAsCard(
      leftTopAsString: AppL10n.tr(AppTranslationKeys.begin),
      rightTopAsString: AppL10n.tr(AppTranslationKeys.end),
      rightBottomAsString: AppL10n.tr(AppTranslationKeys.memo),
    );
  }

  // Fields for this instance
  @override
  FieldDefinitions get fieldDefinitions => fields.definitions;

  @override
  String getRepresentation() {
    return eventName;
  }

  @override
  int get uniqueId => fieldId.value;

  @override
  set uniqueId(final int value) => fieldId.value = value;

  static final Fields<Event> _fields = Fields<Event>();
  static final Fields<Event> _fieldsForColumnView = Fields<Event>();
  static final List<FieldBlueprint<Event>> _fieldBlueprints = <FieldBlueprint<Event>>[
    FieldBlueprint<Event>(selector: (Event tmpInstance) => tmpInstance.fieldId),
    FieldBlueprint<Event>(
      selector: (Event tmpInstance) => tmpInstance.fieldName,
      includeInColumnView: true,
    ),
    FieldBlueprint<Event>(
      selector: (Event tmpInstance) => tmpInstance.fieldCategoryId,
      includeInColumnView: true,
    ),
    FieldBlueprint<Event>(
      selector: (Event tmpInstance) => tmpInstance.fieldDateBegin,
      includeInColumnView: true,
    ),
    FieldBlueprint<Event>(
      selector: (Event tmpInstance) => tmpInstance.fieldDateEnd,
      includeInColumnView: true,
    ),
    FieldBlueprint<Event>(
      selector: (Event tmpInstance) => tmpInstance.fieldDuration,
      includeInColumnView: true,
    ),
    FieldBlueprint<Event>(
      selector: (Event tmpInstance) => tmpInstance.fieldPeople,
      includeInColumnView: true,
    ),
    FieldBlueprint<Event>(
      selector: (Event tmpInstance) => tmpInstance.fieldMemo,
      includeInColumnView: true,
    ),
  ];

  /// Returns the category name for this event.
  String get categoryName => data!.getCategoryNameFromId(this.fieldCategoryId.value);

  /// Updates the category for an event and notifies listeners.
  static void changeCategory(Event item, final int categoryId) {
    // record the change
    item.stashValueBeforeEditing();

    // Make change
    item.fieldCategoryId.value = categoryId;
    item.possibleMatchingCategoryId = -1;

    // inform of changes
    item.data!.notifyMutationChanged(
      mutation: MutationType.changed,
      moneyObject: item,
      recalculateBalances: true,
    );
  }

  /// Returns the event duration as a [DateRange].
  DateRange get durationInDateRange => DateRange(
    min: fieldDateBegin.value,
    max: fieldDateEnd.value ?? DateTime.now(),
  );

  /// Returns the event duration in days.
  int get durationInDays => durationInDateRange.durationInDays;

  /// Returns the event duration as a display string.
  String get durationAsString => durationInDateRange.toStringDuration();

  /// Returns the event name or a generated fallback.
  String get eventName => fieldName.value.isEmpty ? 'Event $uniqueId' : fieldName.value;

  /// Creates a lightweight static [Event] used only for field definition wiring.
  static Event _createStaticFieldInstance() {
    return Event._static(
      id: -1,
      name: '',
      dateBegin: null,
      dateEnd: null,
      people: '',
      memo: '',
    );
  }

  /// Returns the field definitions for Event entities.
  static Fields<Event> get fields => ensureCachedFieldDefinitionsFromBlueprints<Event>(
    cache: _fields,
    instanceFactory: _createStaticFieldInstance,
    blueprints: _fieldBlueprints,
    forColumnView: false,
  );

  /// Returns the field definitions for Event column view.
  static Fields<Event> get fieldsForColumnView => ensureCachedFieldDefinitionsFromBlueprints<Event>(
    cache: _fieldsForColumnView,
    instanceFactory: _createStaticFieldInstance,
    blueprints: _fieldBlueprints,
    forColumnView: true,
  );

  /// Creates a date field definition with picker/editor and serialization behavior.
  static FieldDate _createDateField(
    String name,
    String serializeName,
    FieldDate Function(Event) getField,
  ) {
    return FieldDate(
      name: name,
      serializeName: serializeName,
      columnWidth: ColumnWidth.small,
      getValueForDisplay: (final DataInterface instance) => getField(instance as Event).value,
      getEditWidget:
          (
            final DataInterface instance,
            void Function(bool /* wasModified */) onEdited,
          ) {
            return PickerEditBoxDate(
              key: Constants.keyDatePicker,
              initialValue: dateToDateTimeString(getField(instance as Event).value),
              onChanged: (String? newDateSelected) {
                if (newDateSelected != null) {
                  getField(instance).value = attemptToGetDateFromText(
                    newDateSelected,
                  );
                  onEdited(true);
                }
              },
            );
          },
      setValue: (DataInterface instance, dynamic newValue) =>
          getField(instance as Event).value = attemptToGetDateFromText(
            newValue as String,
          ),
      getValueForSerialization: (final DataInterface instance) =>
          dateToIso8601OrDefaultString(getField(instance as Event).value),
    );
  }
}
