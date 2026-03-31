import 'package:money/helpers/json_helper.dart';
import 'package:money/helpers/shared_strings.dart';
import 'package:money/shared/domain/data_abstract.dart';
import 'package:money/shared/domain/event.dart';
import 'package:money/shared/domain/money_objects.dart';

/// Represents events.
class Events extends MoneyObjects<Event> {
  Events() {
    collectionName = SharedDomainStrings.domainString084;
  }
  late DataAbstract data;

  @override
  void loadFromJson(final List<MyJson> rows) {
    clear();
    for (final MyJson row in rows) {
      appendMoneyObject(Event.fromJson(row, data));
    }
  }

  @override
  void onAllDataLoaded() {}

  @override
  String toCSV() {
    return MoneyObjects.getCsvFromList(getListSortedById());
  }

  /// Creates and adds a new event with default values.
  Event addNewEvent() {
    // add a new Category
    final Event event = Event(
      id: -1,
      name: 'New event',
      dateBegin: DateTime.now(),
      dateEnd: DateTime.now(),
      people: '',
      memo: '',
      data: data,
    );

    appendNewMoneyObject(event);
    return event;
  }
}
