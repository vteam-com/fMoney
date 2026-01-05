import 'package:money/helpers/json_helper.dart';
import 'package:money/money_objects/events/event.dart';
import 'package:money/views/data/data.dart';
import 'package:money/widgets/money_objects.dart';

class Events extends MoneyObjects<Event> {
  Events() {
    collectionName = 'LoanPayments';
  }

  @override
  void loadFromJson(final List<MyJson> rows) {
    clear();
    for (final MyJson row in rows) {
      appendMoneyObject(Event.fromJson(row));
    }
  }

  @override
  void onAllDataLoaded() {}

  @override
  String toCSV() {
    return MoneyObjects.getCsvFromList(getListSortedById());
  }

  Event addNewEvent() {
    // add a new Category
    final Event event = Event(
      id: -1,
      name: 'New event',
      dateBegin: DateTime.now(),
      dateEnd: DateTime.now(),
      people: '',
      memo: '',
    );

    Data().events.appendNewMoneyObject(event);
    return event;
  }
}
