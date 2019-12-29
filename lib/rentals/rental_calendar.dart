import 'dart:async';
import 'dart:convert';
import 'package:shareapp/services/dialogs.dart';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_picker/flutter_picker.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:intl/intl.dart';
import 'package:shareapp/extras/helpers.dart';
import 'package:shareapp/main.dart';
import 'package:shareapp/models/current_user.dart';
import 'package:shareapp/pages/profile_tab_pages/payouts_page.dart';
import 'package:shareapp/rentals/rental_detail.dart';
import 'package:shareapp/services/const.dart';
import 'package:shareapp/services/functions.dart';
import 'package:shareapp/services/picker_data.dart';
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
  double dailyRate;
  List<DateTime> unavailableDays = [];
  CurrentUser currentUser;

  DateTime selectedDay;
  DateTime visibleDay;
  Map<DateTime, List> events;
  Map<DateTime, List> visibleEvents;
  List selectedEvents;

  AnimationController controller;

  bool isLoading = true;
  bool isAuthenticated;
  bool isOwner;

  DateTime pickupTime;
  int duration;
  List windows;
  int window; // a value 0-23 to represent range index in windows list
  int amPm; // 0 for AM, 1 for PM
  String message;

  double statusBarHeight;
  double pageHeight;
  double pageWidth;

  @override
  void initState() {
    super.initState();
    itemDS = widget.itemDS;
    List unavailable = itemDS['unavailable'];
    currentUser = CurrentUser.getModel(context);
    DocumentReference ownerRef = itemDS['creator'];
    isOwner = currentUser.id == ownerRef.documentID ? true : false;

    if (unavailable != null) {
      for (var timestamp in unavailable) {
        unavailableDays.add(timestamp.toDate());
      }
    }

    events = {};
    visibleEvents = {};
    dailyRate = itemDS['price'].toDouble();

    checkAuthentication();

    DateTime now = DateTime.now();
    DateTime first = DateTime(now.year, now.month, 1);
    DateTime last = DateTime(now.year, now.month + 1, 0);
    getItemAvailability(first, last, true);

    selectedDay = DateTime(now.year, now.month, now.day);
    visibleDay = first;

    List pickerData = JsonDecoder().convert(PickerData);
    windows = pickerData[0];
    duration = 1;
    pickupTime = selectedDay;
    pickupTime = DateTime(
        pickupTime.year, pickupTime.month, pickupTime.day, 5, 0, 0, 0, 0);
    window = 8;
    amPm = 0;

    controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    controller.forward();
  }

  void checkAuthentication() async {
    FirebaseUser user = await FirebaseAuth.instance.currentUser();

    if (user != null) {
      isAuthenticated = true;
    } else {
      isAuthenticated = false;
    }
  }

  Future<dynamic> getItemAvailability(
      DateTime first, DateTime last, bool refresh) async {
    if (refresh) {
      setState(() {
        isLoading = true;
        events = {};
      });
    }

    DateTime lowerDateBound = first.subtract(Duration(days: 5));
    DateTime upperDateBound = last.add(Duration(hours: 23));

    DocumentReference itemDR =
        Firestore.instance.collection('items').document(itemDS.documentID);
    var rentalQuerySnaps = await Firestore.instance
        .collection('rentals')
        .where('item', isEqualTo: itemDR)
        .where('declined', isNull: true)
        .where('pickupStart', isGreaterThanOrEqualTo: lowerDateBound)
        .where('pickupStart', isLessThanOrEqualTo: upperDateBound)
        .getDocuments();

    List<DocumentSnapshot> rentalSnaps = rentalQuerySnaps.documents;

    if (rentalSnaps.isNotEmpty) {
      rentalSnaps.forEach((rentalDS) {
        DateTime pickupStartRaw = rentalDS['pickupStart'].toDate();
        DateTime pickupStart = DateTime(
            pickupStartRaw.year, pickupStartRaw.month, pickupStartRaw.day);
        int duration = rentalDS['duration'];

        for (int i = 0; i <= duration; i++) {
          DateTime dateTime = pickupStart.add(Duration(days: i));
          dateTime = stripHourMin(dateTime);

          events.addAll({
            dateTime: ['unavailable']
          });
        }
      });
    }

    DocumentSnapshot itemSnap = await Firestore.instance
        .collection('items')
        .document(itemDS.documentID)
        .get();

    if (itemSnap != null && itemSnap.exists) {
      List unavailableTimestamps = itemSnap['unavailable'];
      unavailableDays = [];

      if (unavailableTimestamps != null) {
        for (int i = 0; i < unavailableTimestamps.length; i++) {
          DateTime dateTime = unavailableTimestamps[i].toDate();
          unavailableDays.add(dateTime);
          events.addAll({
            dateTime: ['unavailable']
          });
        }
      }
    }

    selectedEvents = events[selectedDay] ?? [];
    visibleEvents = events;

    if (refresh && events != null) {
      setState(() {
        isLoading = false;
      });
    }
  }

  void onDaySelected(DateTime day, List events) {
    setState(() {
      DateTime pickupTimeCopy = pickupTime;
      selectedDay = stripHourMin(day);
      pickupTime = DateTime(selectedDay.year, selectedDay.month,
          selectedDay.day, pickupTimeCopy.hour, pickupTimeCopy.minute);
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
    statusBarHeight = MediaQuery.of(context).padding.top;
    pageHeight = MediaQuery.of(context).size.height - statusBarHeight;
    pageWidth = MediaQuery.of(context).size.width;

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

  void refresh() async {
    DateTime first = DateTime(visibleDay.year, visibleDay.month, 1);
    DateTime last = DateTime(visibleDay.year, visibleDay.month + 1, 0);
    getItemAvailability(first, last, true);

    if (visibleDay.month != selectedDay.month ||
        visibleDay.year != selectedDay.year) {
      setState(() {
        selectedDay = stripHourMin(visibleDay);
      });
    }
  }

  Widget refreshButton() {
    return IconButton(
      icon: Icon(Icons.refresh),
      tooltip: 'Refresh',
      onPressed: () {
        refresh();
      },
    );
  }

  Widget showBody() {
    bool canRequest = !isOwner && !events.containsKey(selectedDay);
    bool unavailable = unavailableDays.contains(selectedDay);
    String unavailableText = unavailable
        ? 'Make item available for this day'
        : 'Make item unavailable for this day';

    return ListView(
      children: <Widget>[
        Column(
          mainAxisSize: MainAxisSize.max,
          children: <Widget>[
            buildCalendar(),
            SizedBox(height: 8.0),
            canRequest
                ? showRequestItemDetail()
                : Center(
                    child: Column(
                      children: <Widget>[
                        isOwner
                            ? RaisedButton(
                                onPressed: () async {
                                  setState(() {
                                    isLoading = true;
                                  });

                                  if (unavailable) {
                                    Firestore.instance
                                        .collection('items')
                                        .document(itemDS.documentID)
                                        .updateData({
                                      'unavailable':
                                          FieldValue.arrayRemove([selectedDay]),
                                    }).then((_) {
                                      unavailableDays.remove(selectedDay);
                                      refresh();
                                    });
                                  } else {
                                    Firestore.instance
                                        .collection('items')
                                        .document(itemDS.documentID)
                                        .updateData({
                                      'unavailable':
                                          FieldValue.arrayUnion([selectedDay]),
                                    }).then((_) {
                                      unavailableDays.add(selectedDay);
                                      refresh();
                                    });
                                  }
                                },
                                color: primaryColor,
                                textColor: Colors.white,
                                child: Text(unavailableText),
                              )
                            : Text(
                                'Item is unavailable on this day',
                                style: TextStyle(fontSize: 20),
                              ),
                      ],
                    ),
                  ),
          ],
        )
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

  Widget requestItemButton() {
    return RaisedButton(
      onPressed: isAuthenticated && !isOwner ? handleRequestItemPressed : null,
      child: Text('Request Item'),
    );
  }

  void handleRequestItemPressed() async {
    setState(() {});

    /*
    Navigator.pushNamed(
      context,
      ItemRequest.routeName,
      arguments: ItemRequestArgs(
        itemDS.documentID,
        selectedDay,
      ),
    );
    */
  }

  Widget showRequestItemDetail() {
    return Column(
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 15),
          child: Container(
            decoration: BoxDecoration(
              border: Border.all(color: Colors.blueGrey[100]),
              borderRadius: BorderRadius.circular(6),
            ),
            padding: EdgeInsets.symmetric(vertical: 13),
            child: showTimePickers(),
          ),
        ),
        divider(),
        showPaymentMethod(),
        Container(height: 20),
        showPriceRequest(),
        Container(height: 20),
        showItemPriceInfo(),
        Container(height: 20),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            children: <Widget>[
              Expanded(
                child: RaisedButton(
                  elevation: 3.0,
                  onPressed: () => validateSend(sendItem),
                  color: primaryColor,
                  child: Text(
                    'Request',
                    style:
                        TextStyle(color: Colors.white, fontFamily: 'Quicksand'),
                  ),
                ),
              ),
            ],
          ),
        )
      ],
    );
  }

  Widget showTimePickers() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        DateTimeItem(
          dateTime: pickupTime,
          window: window,
          amPm: amPm,
          duration: duration,
          onChangedDateTime: (DateTime value) {
            setState(() {
              pickupTime = value;
            });
          },
          onChangedWindow: (int value) {
            setState(() {
              window = value;
              pickupTime = updateDateTime(pickupTime.year, pickupTime.month,
                  pickupTime.day, windows, window, amPm);
            });
          },
          onChangedAmPm: (int value) {
            setState(() {
              amPm = value;

              pickupTime = updateDateTime(pickupTime.year, pickupTime.month,
                  pickupTime.day, windows, window, amPm);
            });
          },
          onChangedDuration: (int value) {
            setState(() {
              duration = value;
            });
          },
        ),
      ],
    );
  }

  Widget showPaymentMethod() {
    return InkWell(
      onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (BuildContext context) => PayoutsPage(),
          )),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 20.0),
        child: Column(
          children: <Widget>[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget>[
                Text('Payment method',
                    style: TextStyle(fontSize: 15.0, fontFamily: 'Quicksand')),
                StreamBuilder(
                  stream: Firestore.instance
                      .collection('users')
                      .document(currentUser.id)
                      .snapshots(),
                  builder: (context, AsyncSnapshot snapshot) {
                    switch (snapshot.connectionState) {
                      case (ConnectionState.waiting):
                      default:
                        if (snapshot.hasData) {
                          DocumentSnapshot myUserDS = snapshot.data;
                          String defaultSource = myUserDS['defaultSource'];

                          if (defaultSource == null) {
                            return Text(
                              'Click to add',
                              style: TextStyle(
                                fontSize: 15.0,
                                fontWeight: FontWeight.bold,
                                fontFamily: 'Quicksand',
                              ),
                            );
                          } else {
                            return StreamBuilder(
                              stream: myUserDS.reference
                                  .collection('sources')
                                  .where('id',
                                      isEqualTo: myUserDS['defaultSource'])
                                  .limit(1)
                                  .snapshots(),
                              builder: (context, AsyncSnapshot snapshot) {
                                switch (snapshot.connectionState) {
                                  case (ConnectionState.waiting):
                                  default:
                                    if (snapshot.hasData &&
                                        snapshot.data.documents.length > 0) {
                                      DocumentSnapshot sourceDS =
                                          snapshot.data.documents[0];

                                      String brand = sourceDS['card']['brand'];
                                      String last4 = sourceDS['card']['last4'];

                                      return Text(
                                        '$brand $last4',
                                        style: TextStyle(
                                          fontSize: 15.0,
                                          fontWeight: FontWeight.bold,
                                          fontFamily: 'Quicksand',
                                        ),
                                      );
                                    } else {
                                      return Container();
                                    }
                                }
                              },
                            );
                          }
                        } else {
                          return Container();
                        }
                    }
                  },
                ),
              ],
            ),
            Container(
              height: 5,
            ),
            Align(
                alignment: Alignment.bottomLeft,
                child: Text('Click to edit',
                    style: TextStyle(
                        fontSize: 10.0,
                        fontFamily: 'Quicksand',
                        fontWeight: FontWeight.w100,
                        fontStyle: FontStyle.italic))),
          ],
        ),
      ),
    );
  }

  Widget showPriceRequest() {
    return InkWell(
      onTap: () async {
        var value = await showDialog(
          barrierDismissible: true,
          context: context,
          builder: (BuildContext context) {
            return Container(
              child: DailyRateDialog(
                pageWidth: pageWidth,
                rate: dailyRate,
              ),
            );
          },
        );

        if (value != null && value is double) {
          setState(() {
            dailyRate = value;
          });
        }
      },
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 20.0),
        child: Column(
          children: <Widget>[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget>[
                Text('Daily Rate',
                    style: TextStyle(fontSize: 15.0, fontFamily: 'Quicksand')),
                Text('\$${dailyRate.toStringAsFixed(2)}',
                    style: TextStyle(
                        fontSize: 15.0,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Quicksand')),
              ],
            ),
            SizedBox(
              height: 5.0,
            ),
            Align(
                alignment: Alignment.bottomLeft,
                child: Text('Click to propose new daily rate',
                    style: TextStyle(
                        fontSize: 10.0,
                        fontFamily: 'Quicksand',
                        fontWeight: FontWeight.w100,
                        fontStyle: FontStyle.italic))),
          ],
        ),
      ),
    );
  }

  Widget showItemPriceInfo() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 20.0),
      child: Column(
        children: <Widget>[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              Text('Total',
                  style: TextStyle(fontSize: 15.0, fontFamily: 'Quicksand')),
              Text('\$${(dailyRate * duration).toStringAsFixed(2)}',
                  style: TextStyle(
                      fontSize: 15.0,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Quicksand')),
            ],
          ),
          SizedBox(
            height: 5.0,
          ),
          Align(
              alignment: Alignment.bottomLeft,
              child: Text(
                  '* You will not be charged until the Owner accepts your proposal',
                  style: TextStyle(
                      fontSize: 10.0,
                      fontFamily: 'Quicksand',
                      fontWeight: FontWeight.w100,
                      fontStyle: FontStyle.italic))),
        ],
      ),
    );
  }

  void validateSend(action) async {
    if (!validate(window, amPm)) {
      showRequestErrorDialog(2);
    } else if (DateTime.now().add(Duration(hours: 1)).isAfter(pickupTime)) {
      showRequestErrorDialog(3);
    } else {
      bool timeIsValid = await validateRental();

      if (!timeIsValid) {
        showRequestErrorDialog(5);
      } else {
        DocumentSnapshot myUserDS = await Firestore.instance
            .collection('users')
            .document(currentUser.id)
            .get();

        if (myUserDS != null && myUserDS.exists) {
          if (myUserDS['address'] == null ||
              myUserDS['birthday'] == null ||
              myUserDS['gender'] == null ||
              myUserDS['phoneNum'] == null) {
            showRequestErrorDialog(4, userSnapshot: myUserDS);
          } else if (currentUser.defaultSource == null ||
              currentUser.defaultSource.isEmpty) {
            showRequestErrorDialog(7);
          } else {
            action();
          }
        }
      }
    }
  }

  Future<bool> showRequestErrorDialog(int type, {userSnapshot}) async {
    final ThemeData theme = Theme.of(context);
    final TextStyle dialogTextStyle =
        theme.textTheme.subhead.copyWith(color: theme.textTheme.caption.color);
    String message = 'Error';

    switch (type) {
      case 1:
        message = 'Someone has already requested this item!';
        break;
      case 2:
        message = 'Pickup window cannot be between midnight and 5 AM';
        break;
      case 3:
        message = 'Pickup window must start at least one hour from now';
        break;
      case 4:
        message = 'You must complete your profile before renting an item!';
        break;
      case 5:
        message = 'Your rental request time interferes with another rental, '
            'or the owner has blocked off this day! Try selecting a different '
            'pickup day or changing the rental duration';
        break;
      case 6:
        message = 'The item owner has disabled renting on this item';
        break;
      case 7:
        message = 'You must add payment information before renting items';
        break;
    }

    return await showDialog<bool>(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: Text('Error'),
              content: Text(
                message,
                style: dialogTextStyle,
              ),
              actions: <Widget>[
                FlatButton(
                  child: const Text('CLOSE'),
                  onPressed: () {
                    Navigator.of(context).pop(
                        false); // Pops the confirmation dialog but not the page.
                  },
                ),
                type == 4
                    ? FlatButton(
                        child: const Text('EDIT PROFILE'),
                        onPressed: () {
                          Navigator.of(context).pop(
                              false); // Pops the confirmation dialog but not the page.
//                          Timestamp timestampBirthday =
//                              userSnapshot['birthday'];na
//                          DateTime birthday;
//
//                          if (timestampBirthday != null) {
//                            birthday = timestampBirthday.toDate();
//                          }
//
//                          UserEdit userEdit =
//                              UserEdit.fromMap(userSnapshot.data, birthday);
//
//                          Navigator.push(
//                              context,
//                              MaterialPageRoute(
//                                builder: (BuildContext context) => ProfileEdit(
//                                  userEdit: userEdit,
//                                ),
//                                fullscreenDialog: true,
//                              ));
                        },
                      )
                    : Container(),
              ],
            );
          },
        ) ??
        false;
  }

  Future<bool> validateRental() async {
    DocumentReference itemDR =
        Firestore.instance.collection('items').document(itemDS.documentID);

    DateTime pickupTimeCopy = stripHourMin(pickupTime);
    DocumentSnapshot itemSnap = await itemDR.get();

    if (itemSnap != null && itemSnap.exists) {
      List unavailable = itemSnap['unavailable'];
      List unavailableDateTimes = [];
      List rentalDateTimes = [];

      if (unavailable != null) {
        for (var timestamp in unavailable) {
          unavailableDateTimes.add(timestamp.toDate());
        }
      }

      for (int i = 0; i < duration; i++) {
        rentalDateTimes.add(pickupTimeCopy.add(Duration(days: i)));
      }

      if (rentalDateTimes.any((item) => unavailableDateTimes.contains(item))) {
        return false;
      }
    }

    // get the rental that starts immediately before the current request
    var rentalBeforeCurrent = await Firestore.instance
        .collection('rentals')
        .where('item', isEqualTo: itemDR)
        .where('declined', isNull: true)
        .where('pickupStart', isLessThanOrEqualTo: pickupTimeCopy)
        .orderBy('pickupStart', descending: false)
        .limit(1)
        .getDocuments();

    // get the document, if it exists
    DocumentSnapshot prevSnap = rentalBeforeCurrent.documents.isNotEmpty
        ? rentalBeforeCurrent.documents[0]
        : null;

    if (prevSnap != null) {
      DateTime prevDateTime = prevSnap['rentalEnd'].toDate();
      prevDateTime = stripHourMin(prevDateTime).add(Duration(minutes: 15));

      if (pickupTimeCopy.isBefore(prevDateTime)) {
        return false;
      }
    }

    // at this point, prevSnap does not exist or
    // prev snap was valid so check the 'after' snap

    // get the rental that starts immediately after the current request pickup
    var rentalAfterCurrent = await Firestore.instance
        .collection('rentals')
        .where('item', isEqualTo: itemDR)
        .where('declined', isNull: true)
        .where('pickupStart', isGreaterThanOrEqualTo: pickupTimeCopy)
        .orderBy('pickupStart', descending: false)
        .limit(1)
        .getDocuments();

    DocumentSnapshot afterSnap = rentalAfterCurrent.documents.isNotEmpty
        ? rentalAfterCurrent.documents[0]
        : null;

    if (afterSnap != null) {
      DateTime afterDateTime = afterSnap['pickupStart'].toDate();
      afterDateTime =
          stripHourMin(afterDateTime).subtract(Duration(minutes: 15));
      pickupTimeCopy = pickupTimeCopy.add(Duration(days: duration));

      if (pickupTimeCopy.isAfter(afterDateTime)) {
        return false;
      }
    }

    return true;
  }

  Future<bool> sendItem() async {
    final ThemeData theme = Theme.of(context);
    final TextStyle dialogTextStyle =
        theme.textTheme.subhead.copyWith(color: theme.textTheme.caption.color);

    String range = parseWindow(windows, window, amPm);

    message = 'Hello. I am requesting to rent your ${itemDS['name']} '
        'for ${duration > 1 ? '$duration days' : '$duration day'}. '
        'I would like to pick up this item '
        'from $range on ${DateFormat('EEE, MMM d yyyy').format(pickupTime)}.';

    return await showDialog<bool>(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: Text('Preview message'),
              content: Text(
                message,
                style: dialogTextStyle,
              ),
              actions: <Widget>[
                FlatButton(
                  child: const Text('Cancel'),
                  onPressed: () {
                    Navigator.of(context).pop(
                        false); // Pops the confirmation dialog but not the page.
                  },
                ),
                FlatButton(
                  child: const Text('Send'),
                  onPressed: () {
                    Navigator.of(context).pop(false);

                    checkItemVisibility().then((int value) {
                      if (value == 0) {
                        validateSend(navToItemRental);
                      } else {
                        showRequestErrorDialog(value);
                      }
                    });

                    // Pops the confirmation dialog but not the page.
                  },
                ),
              ],
            );
          },
        ) ??
        false;
  }

  Future<int> checkItemVisibility() async {
    DocumentReference itemDR =
        Firestore.instance.collection('items').document(itemDS.documentID);

    var itemSnap = await itemDR.get();

    if (!itemSnap.exists) {
      return 5;
    }

    if (itemSnap != null) {
      bool isVisible = itemSnap['isVisible'];

      if (!isVisible) {
        return 6;
      }
    }

    return 0;
  }

  void navToItemRental() async {
    int delay = 500;

    setState(() {
      isLoading = true;
    });

    String rentalID;
    String groupChatId;
    List combinedId;

    DocumentReference itemCreatorDR = itemDS['creator'];
    DocumentSnapshot itemOwnerDS = await itemCreatorDR.get();

    if (itemOwnerDS != null && itemOwnerDS.exists) {
      Map data = getChatRoomData(currentUser.id, itemOwnerDS.documentID);

      if (data != null) {
        groupChatId = data['combinedId'];
        combinedId = data['users'];
      }
    }

    // create rental in 'rentals' collection
    DocumentReference rentalDR =
        await Firestore.instance.collection("rentals").add({
      'declined': null,
      'status': 0,
      'requesting': true,
      'item':
          Firestore.instance.collection('items').document(itemDS.documentID),
      'itemName': itemDS['name'],
      'itemAvatar': itemDS['images'][0],
      'owner': Firestore.instance
          .collection('users')
          .document(itemOwnerDS.documentID),
      'ownerData': {
        'name': itemOwnerDS['name'],
        'avatar': itemOwnerDS['avatar'],
      },
      'renter': Firestore.instance.collection('users').document(currentUser.id),
      'renterData': {
        'name': currentUser.name,
        'avatar': currentUser.avatar,
      },
      'pickupStart': pickupTime,
      'pickupEnd': pickupTime.add(Duration(hours: 1)),
      'rentalEnd': pickupTime.add(Duration(days: duration, hours: 1)),
      'created': DateTime.now(),
      'lastUpdateTime': DateTime.now(),
      'duration': duration,
      'users': [
        Firestore.instance.collection('users').document(itemOwnerDS.documentID),
        Firestore.instance.collection('users').document(currentUser.id),
      ],
      'renterCC': null,
      'ownerCC': null,
      'renterReviewSubmitted': false,
      'ownerReviewSubmitted': false,
      'renterReview': null,
      'ownerReview': null,
      'initialPushNotif': {
        'nameFrom': currentUser.name,
        'pushToken': itemOwnerDS['pushToken'],
        'itemName': itemDS['name'],
      },
      'price': dailyRate,
    });

    if (rentalDR != null) {
      rentalID = rentalDR.documentID;

      DocumentSnapshot ds = await Firestore.instance
          .collection('messages')
          .document(groupChatId)
          .get();

      if (ds != null) {
        if (!ds.exists) {
          Map map = setChatUserData({
            'id': currentUser.id,
            'name': currentUser.name,
            'avatar': currentUser.avatar,
          }, {
            'id': itemOwnerDS.documentID,
            'name': itemOwnerDS['name'],
            'avatar': itemOwnerDS['avatar'],
          });

          try {
            HttpsCallable callable = CloudFunctions.instance.getHttpsCallable(
              functionName: 'createChatRoom',
            );

            final HttpsCallableResult result = await callable.call(
              <String, dynamic>{
                'users': combinedId,
                'combinedId': groupChatId,
                'user0': map['user0'],
                'user1': map['user1'],
              },
            );
          } on CloudFunctionsException catch (e) {
            Fluttertoast.showToast(msg: '${e.message}');
          } catch (e) {}
        }

        var messageReference = Firestore.instance
            .collection('messages')
            .document(groupChatId)
            .collection('messages')
            .document(DateTime.now().millisecondsSinceEpoch.toString());

        Firestore.instance.runTransaction((transaction) async {
          await transaction.set(
            messageReference,
            {
              'idFrom': currentUser.id,
              'idTo': itemOwnerDS.documentID,
              'timestamp': DateTime.now().millisecondsSinceEpoch,
              'content': message,
              'type': 0,
              'pushToken': itemOwnerDS['pushToken'],
              'nameFrom': currentUser.name,
              'rental': rentalDR,
            },
          );
        });

        if (messageReference != null) {
          await new Future.delayed(Duration(milliseconds: delay));

          rentalDR.get().then((ds) {
            if (rentalID != null) {
              Navigator.popAndPushNamed(
                context,
                RentalDetail.routeName,
                arguments: RentalDetailArgs(
                  ds.documentID,
                  currentUser,
                ),
              );
            }
          });
        }
      }
    }
  }
}

class DateTimeItem extends StatelessWidget {
  DateTimeItem({
    Key key,
    DateTime dateTime,
    int window,
    int amPm,
    int duration,
    @required this.onChangedDateTime,
    @required this.onChangedWindow,
    @required this.onChangedAmPm,
    @required this.onChangedDuration,
  })  : assert(onChangedDateTime != null),
        dateTime = DateTime(dateTime.year, dateTime.month, dateTime.day),
        window = window,
        amPm = amPm,
        duration = duration,
        super(key: key);

  final DateTime dateTime;
  final int window;
  final int amPm;
  final int duration;
  final ValueChanged<DateTime> onChangedDateTime;
  final ValueChanged<int> onChangedWindow;
  final ValueChanged<int> onChangedAmPm;
  final ValueChanged<int> onChangedDuration;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    List pickerData = JsonDecoder().convert(PickerData);
    List windows = pickerData[0];

    String range = parseWindow(windows, window, amPm);
    double w = MediaQuery.of(context).size.width;

    return Container(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: <Widget>[
          Container(width: 7,),
          InkWell(
            onTap: () {
              Picker(
                  adapter: PickerDataAdapter<String>(
                    pickerdata: JsonDecoder().convert(PickerData),
                    isArray: true,
                  ),
                  hideHeader: true,
                  selecteds: [window, amPm],
                  title: Text("Select Pickup Window"),
                  columnFlex: [2, 1],
                  onConfirm: (Picker picker, List value) {
                    onChangedWindow(value[0]);
                    onChangedAmPm(value[1]);
                  }).showDialog(context);
            },
            child: Column(
              children: <Widget>[
                Text('Pickup Window',
                    style: TextStyle(
                        fontFamily: 'Quicksand',
                        fontWeight: FontWeight.w200,
                        fontSize: w / 30),
                    textAlign: TextAlign.start),
                SizedBox(height: 3),
                Center(
                  child: Text(
                    range,
                    style: TextStyle(
                        color: primaryColor,
                        fontFamily: 'Quicksand',
                        fontSize: w / 25),
                  ),
                ),
              ],
            ),
          ),
          InkWell(
            onTap: () {
              Picker(
                  adapter: NumberPickerAdapter(data: [
                    NumberPickerColumn(begin: 1, end: 27),
                  ]),
                  hideHeader: true,
                  selecteds: [duration - 1],
                  title: Text('Rental Duration (days)'),
                  onConfirm: (Picker picker, List value) {
                    onChangedDuration(picker.getSelectedValues()[0]);
                  }).showDialog(context);
            },
            child: Column(
              children: <Widget>[
                Text('Days',
                    style: TextStyle(
                        fontFamily: 'Quicksand',
                        fontWeight: FontWeight.w200,
                        fontSize: w / 30),
                    textAlign: TextAlign.start),
                SizedBox(height: 3),
                Center(
                  child: Text(
                    '$duration',
                    style: TextStyle(
                        color: primaryColor,
                        fontFamily: 'Quicksand',
                        fontSize: w / 25),
                  ),
                ),
              ],
            ),
          ),
          Container(
            width: 7,
          ),
        ],
      ),
    );
  }
}

// false if window is between midnight and 5am, true otherwise
bool validate(int window, int amPm) {
  // am
  if (amPm == 0) {
    // 1:00-2:00am to 4:30-5:30am
    if (0 <= window && window <= 7) {
      return false;
    }

    // 11:30-12:30am to 12:30-1:30am
    if (21 <= window && window <= 23) {
      return false;
    }
  }

  return true;
}

String parseWindow(List windows, int window, int amPm) {
  String start = windows[window].split(' - ')[0];
  String end = windows[window].split(' - ')[1];
  String errorMessage = 'Range can\'t be between\nmidnight and 5 AM';
  String range;

  if (!validate(window, amPm)) {
    range = errorMessage;
  } else {
    if (amPm == 0 && window == 20) {
      range = '$start PM - Midnight';
    } else if (amPm == 1 && window == 20) {
      range = '$start AM - Noon';
    } else if (amPm == 1 && window == 21) {
      range = '$start AM - $end PM';
    } else if (amPm == 1 && window == 22) {
      range = 'Noon - $end PM';
    } else {
      range =
          '$start ${amPm == 0 ? 'AM' : 'PM'} - $end ${amPm == 0 ? 'AM' : 'PM'}';
    }
  }

  return range;
}

DateTime updateDateTime(year, month, day, windows, window, amPm) {
  String start = windows[window].split(' - ')[0];
  int hour = int.parse(start.split(':')[0]);
  int minute = int.parse(start.split(':')[1]);

  if (amPm == 1 && hour != 12) {
    hour += 12;
  }

  if (window == 20 && amPm == 0) {
    hour = 23;
  }

  if (amPm == 1 && (window == 20 || window == 21)) {
    hour = 11;
  }

  return DateTime(year, month, day, hour, minute, 0, 0, 0);
}

void delay() async {
  await new Future.delayed(const Duration(seconds: 3));
}
