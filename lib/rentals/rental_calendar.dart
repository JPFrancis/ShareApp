import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:shareapp/main.dart';
import 'package:shareapp/rentals/item_request.dart';
import 'package:shareapp/services/const.dart';
import 'package:table_calendar/table_calendar.dart';

class RentalCalendar extends StatefulWidget {
  static const routeName = '/rentalCalendar';
  final DocumentSnapshot itemDS;

  RentalCalendar({Key key, this.itemDS}) : super(key: key);

  @override
  State<StatefulWidget> createState() {
    return RentalCalendarState();
  }
}

class RentalCalendarState extends State<RentalCalendar>
    with TickerProviderStateMixin {
  DocumentSnapshot itemDS;
  DateTime selectedDay;
  DateTime visibleDay;
  Map<DateTime, List> events;
  Map<DateTime, List> visibleEvents;
  List selectedEvents;
  AnimationController controller;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    itemDS = widget.itemDS;
    events = {};

    DateTime now = DateTime.now();
    DateTime first = DateTime(now.year, now.month, 1);
    DateTime last = DateTime(now.year, now.month + 1, 0);
    getItemAvailability(first, last, true);

    selectedDay = DateTime(now.year, now.month, now.day);
    visibleDay = first;

    controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    controller.forward();
  }

  Future<dynamic> getItemAvailability(
      DateTime first, DateTime last, bool refresh) async {
    if (refresh) {
      setState(() {
        isLoading = true;
      });
    }

    events = {};

    DateTime lowerDateBound = first.subtract(Duration(days: 5));
    DateTime upperDateBound = last.add(Duration(hours: 23));

    DocumentReference itemDR =
        Firestore.instance.collection('items').document(itemDS.documentID);
    var rentalQuerySnaps = await Firestore.instance
        .collection('rentals')
        .where('item', isEqualTo: itemDR)
        .where('pickupStart', isGreaterThanOrEqualTo: lowerDateBound)
        .where('pickupStart', isLessThanOrEqualTo: upperDateBound)
        .getDocuments();

    List<DocumentSnapshot> rentalSnaps = rentalQuerySnaps.documents;

    rentalSnaps.forEach((rentalDS) {
      DateTime pickupStartRaw = rentalDS['pickupStart'].toDate();
      DateTime pickupStart = DateTime(
          pickupStartRaw.year, pickupStartRaw.month, pickupStartRaw.day);
      int duration = rentalDS['duration'];

      for (int i = 0; i <= duration; i++) {
        DateTime dateTime = pickupStart.add(Duration(days: i));

        events.addAll({
          dateTime: ['unavailable']
        });
      }

      selectedEvents = events[selectedDay] ?? [];
      visibleEvents = events;
    });

    if (refresh && events != null) {
      setState(() {
        isLoading = false;
      });
    }
  }

  void onDaySelected(DateTime day, List events) {
    setState(() {
      selectedDay = day;
      selectedEvents = events;
    });
  }

  void onVisibleDaysChanged(
      DateTime first, DateTime last, CalendarFormat format) {
    getItemAvailability(first, last, false).then((_) {
      setState(() {
        visibleDay = first;
        visibleEvents = Map.fromEntries(
          events.entries.where(
            (entry) =>
                entry.key.isAfter(first.subtract(const Duration(days: 1))) &&
                entry.key.isBefore(last.add(const Duration(days: 1))),
          ),
        );
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${itemDS['name']}'),
        actions: <Widget>[
          //todayButton(),
          refreshButton(),
        ],
      ),
      body: isLoading
          ? Center(
              child: CircularProgressIndicator(),
            )
          : showBody(),
    );
  }

  // not working fully
  Widget todayButton() {
    return IconButton(
      icon: Icon(Icons.today),
      tooltip: 'Today',
      onPressed: () {
        DateTime now = DateTime.now();
        DateTime first = DateTime(now.year, now.month, 1);
        selectedDay = DateTime(now.year, now.month, now.day);
        visibleDay = first;

        setState(() {});
      },
    );
  }

  Widget refreshButton() {
    return IconButton(
      icon: Icon(Icons.refresh),
      tooltip: 'Refresh',
      onPressed: () {
        DateTime first = DateTime(visibleDay.year, visibleDay.month, 1);
        DateTime last = DateTime(visibleDay.year, visibleDay.month + 1, 0);
        getItemAvailability(first, last, true);

        if (visibleDay.month != selectedDay.month ||
            visibleDay.year != selectedDay.year) {
          setState(() {
            selectedDay = visibleDay;
          });
        }
      },
    );
  }

  Widget showBody() {
    bool canRequest = !events.containsKey(selectedDay);
    return Column(
      mainAxisSize: MainAxisSize.max,
      children: <Widget>[
        buildCalendar(),
        const SizedBox(height: 8.0),
        canRequest ? requestItemButton() : Container(),
        canRequest
            ? Container()
            : Center(
                child: Text(
                  'Item is unavailable on this day',
                  style: TextStyle(fontSize: 20),
                ),
              ),
        //Expanded(child: buildEventList()),
      ],
    );
  }

  Widget buildCalendar() {
    return TableCalendar(
      startDay: DateTime.now().subtract(Duration(days: 1)),
      selectedDay: selectedDay,
      locale: 'en_US',
      events: visibleEvents,
      initialCalendarFormat: CalendarFormat.month,
      formatAnimation: FormatAnimation.slide,
      startingDayOfWeek: StartingDayOfWeek.sunday,
      availableGestures: AvailableGestures.horizontalSwipe,
      calendarStyle: CalendarStyle(
        outsideDaysVisible: false,
        weekendStyle: TextStyle().copyWith(color: Colors.black),
      ),
      daysOfWeekStyle: DaysOfWeekStyle(
        weekendStyle: TextStyle().copyWith(color: Colors.black54),
        weekdayStyle: TextStyle().copyWith(color: Colors.black54),
      ),
      headerStyle: HeaderStyle(
        centerHeaderTitle: true,
        formatButtonVisible: false,
      ),
      builders: CalendarBuilders(
        selectedDayBuilder: (context, date, _) {
          return Container(
            margin: const EdgeInsets.all(4.0),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: primaryColor,
            ),
            child: Center(
              child: Text(
                '${date.day}',
                style: TextStyle().copyWith(
                  fontSize: 16.0,
                  color: Colors.white,
                ),
              ),
            ),
          );
        },
        todayDayBuilder: (context, date, _) {
          return Container(
            margin: const EdgeInsets.all(4.0),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.lightBlue[200],
            ),
            child: Center(
              child: Text(
                '${date.day}',
                style: TextStyle().copyWith(fontSize: 16.0),
              ),
            ),
          );
        },
        markersBuilder: (context, date, events, _) {
          final children = <Widget>[];

          if (events.isNotEmpty) {
            children.add(
              Center(
                child: Icon(
                  Icons.close,
                  color: Colors.red,
                  size: 30,
                ),
              ),
            );
          }

          return children;
        },
      ),
      onDaySelected: (date, events) {
        onDaySelected(date, events);
        controller.forward(from: 0.0);
      },
      onVisibleDaysChanged: onVisibleDaysChanged,
    );
  }

  Widget buildEventList() {
    return ListView(
      children: selectedEvents
          .map((event) => Container(
                decoration: BoxDecoration(
                  border: Border.all(width: 0.8),
                  borderRadius: BorderRadius.circular(12.0),
                ),
                margin:
                    const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                child: ListTile(
                  title: Text(event.toString()),
                  onTap: () {},
                ),
              ))
          .toList(),
    );
  }

  Widget requestItemButton() {
    return RaisedButton(
      onPressed: handleRequestItemPressed,
      child: Text('Request Item'),
    );
  }

  void handleRequestItemPressed() async {
    Navigator.pushNamed(
      context,
      ItemRequest.routeName,
      arguments: ItemRequestArgs(
        itemDS.documentID,
        selectedDay,
      ),
    );
  }
}
