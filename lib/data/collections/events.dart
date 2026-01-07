import 'package:money/data/entities/data_abstract.dart';
import 'package:money/data/entities/event.dart';
import 'package:money/helpers/json_helper.dart';
import 'package:money/models/money_objects.dart';

class Events extends MoneyObjects<Event> {
  Events() {
    collectionName = 'LoanPayments';
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

    data.events.appendNewMoneyObject(event);
    return event;
  }
}
