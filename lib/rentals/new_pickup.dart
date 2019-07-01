import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_picker/flutter_picker.dart';
import 'package:intl/intl.dart';
import 'package:shareapp/services/picker_data.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum DismissDialogAction {
  cancel,
  discard,
  save,
}

class NewPickup extends StatefulWidget {
  static const routeName = '/newPickup';
  final String rentalID;
  final bool isRenter;

  NewPickup({Key key, this.rentalID, this.isRenter}) : super(key: key);

  @override
  State<StatefulWidget> createState() {
    return NewPickupState();
  }
}

class NewPickupState extends State<NewPickup> {
  final GlobalKey<FormState> formKey = new GlobalKey<FormState>();
  SharedPreferences prefs;

  bool isUploading = false;
  bool isLoading;
  String myUserID;
  String myName;

  DocumentSnapshot rentalDS;
  DocumentSnapshot itemDS;
  DocumentSnapshot otherUserDS;

  Future<File> selectedImage;
  File imageFile;
  String message;
  String note;

  TextEditingController noteController = TextEditingController();
  FocusNode focusNode;

  DateTime pickupTime;
  int duration;
  List windows;
  int window; // a value 0-23 to represent range index in windows list
  int amPm; // 0 for AM, 1 for PM

  TextStyle textStyle;
  TextStyle inputTextStyle;
  ThemeData theme;
  double padding = 5.0;

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    focusNode = FocusNode();
    note = '';

    getMyUserID();
    getSnapshots();
  }

  @override
  void dispose() {
    // Clean up the controller when the widget is disposed.
    noteController.dispose();
    super.dispose();
  }

  void getMyUserID() async {
    prefs = await SharedPreferences.getInstance();
    myName = prefs.getString('name') ?? '';
    var user = await FirebaseAuth.instance.currentUser();
    if (user != null) {
      myUserID = user.uid;
    }
  }

  Future<Null> getSnapshots() async {
    isLoading = true;
    DocumentSnapshot ds = await Firestore.instance
        .collection('rentals')
        .document(widget.rentalID)
        .get();

    if (ds != null) {
      rentalDS = ds;

      DocumentReference itemDR = rentalDS['item'];

      String str = itemDR.documentID;

      ds = await Firestore.instance.collection('items').document(str).get();

      if (ds != null) {
        itemDS = ds;

        DocumentReference otherUserDR =
            widget.isRenter ? rentalDS['owner'] : rentalDS['renter'];
        str = otherUserDR.documentID;

        List pickerData = JsonDecoder().convert(PickerData);
        windows = pickerData[0];

        pickupTime = rentalDS['pickupStart'].toDate();
        duration = rentalDS['duration'];

        String date = DateFormat('h#mm#a').format(pickupTime);
        List parsedDate = date.split('#');
        int hour = int.parse(parsedDate[0]);
        int minute = int.parse(parsedDate[1]);
        String amPmStr = parsedDate[2];

        window = (hour - 1) * 2;
        amPm = amPmStr == 'AM' ? 0 : 1;

        if (minute == 30) {
          window++;
        }

        pickupTime = DateTime(pickupTime.year, pickupTime.month, pickupTime.day,
            hour, minute, 0, 0, 0);

        ds = await Firestore.instance.collection('users').document(str).get();

        if (ds != null) {
          otherUserDS = ds;

          if (prefs != null && itemDS != null && otherUserDS != null) {
            setState(() {
              isLoading = false;
            });
          }
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    theme = Theme.of(context);
    textStyle =
        Theme.of(context).textTheme.headline.merge(TextStyle(fontSize: 20));
    inputTextStyle = Theme.of(context).textTheme.subtitle;

    return Scaffold(
      appBar: AppBar(
        title: Text('New Pickup'),
        actions: <Widget>[
          FlatButton(
            child: Text('SEND',
                textScaleFactor: 1.05,
                style: theme.textTheme.body2.copyWith(color: Colors.white)),
            onPressed: () {
              validateSend(sendItem);
            },
          ),
        ],
      ),
      body: Stack(
        children: <Widget>[
          isLoading
              ? Container(
                  decoration:
                      new BoxDecoration(color: Colors.white.withOpacity(0.0)),
                )
              : showBody(),
          showCircularProgress(),
        ],
      ),
      bottomNavigationBar: Container(
        height: MediaQuery.of(context).size.height / 10,
        color: Colors.black,
        child: RaisedButton(
          child: Text("test"),
          onPressed: null,
          color: Colors.red,
        ),
      ),
    );
  }

  Widget showBody() {
    return Padding(
      padding: EdgeInsets.all(15),
      child: ListView(
        children: <Widget>[
          Container(
            height: 10,
          ),
          showItemPriceInfo(),
          showTimePickers(),
          Container(
            height: 10,
          ),
          showNoteEdit(),
          showTimeInfo(), // testing purposes only
        ],
      ),
    );
  }

  // testing purposes only, will remove in final build
  Widget showTimeInfo() {
    return Container(
      padding: EdgeInsets.all(10),
      child: Text(
        'TESTING PURPOSES ONLY\n'
        'Start: ${pickupTime}\n'
        'End: ${pickupTime.add(Duration(hours: 1))}\n'
        'Window: $window\n'
        'amPm: $amPm\n'
        'duration: $duration',
        style: theme.textTheme.caption,
      ),
    );
  }

  Widget showItemPriceInfo() {
    return Padding(
      padding: EdgeInsets.all(padding),
      child: SizedBox(
          height: 50.0,
          child: Container(
            color: Color(0x00000000),
            child: Text(
              'Item daily rate: \$${itemDS['price']}\n'
              'Total due: \$${itemDS['price'] * duration}',
              //itemName,
              style: TextStyle(color: Colors.black, fontSize: 20.0),
              textAlign: TextAlign.left,
            ),
          )),
    );
  }

  Widget showTimePickers() {
    return Padding(
      padding: EdgeInsets.all(padding),
      child: Column(
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
      ),
    );
  }

  Widget showNoteEdit() {
    return Padding(
      padding: EdgeInsets.all(padding),
      child: TextField(
        //keyboardType: TextInputType.multiline,
        focusNode: focusNode,
        maxLines: 3,
        controller: noteController,
        style: textStyle,
        onChanged: (value) {
          setState(() {
            note = noteController.text;
          });
        },
        decoration: InputDecoration(
          labelText: 'Add note (optional)',
          filled: true,
        ),
      ),
    );
  }

  Widget showCircularProgress() {
    return isUploading
        ? Container(
            child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: <Widget>[Center(child: CircularProgressIndicator())]),
          )
        : Container(
            height: 0.0,
            width: 0.0,
          );
  }

  void sendNewTime() async {
    int delay = 500;

    setState(() {
      isUploading = true;
    });

    int newStatus = widget.isRenter ? 0 : 1;

    Firestore.instance
        .collection('rentals')
        .document(widget.rentalID)
        .updateData({
      'status': newStatus,
      'pickupStart': pickupTime,
      'pickupEnd': pickupTime.add(Duration(hours: 1)),
      'rentalEnd': pickupTime.add(Duration(days: duration, hours: 1)),
      'duration': duration,
      'note': note,
    }).then((_) {
      Future.delayed(Duration(seconds: 1)).then((_) {
        Firestore.instance.collection('notifications').add({
          'title': 'New pickup window proposal',
          'body': 'From: ${myName}',
          'pushToken': otherUserDS['pushToken'],
          'rentalID': widget.rentalID,
          'timestamp': DateTime.now().millisecondsSinceEpoch,
        }).then((_) {
          Navigator.of(context).pop();
        });
      });
    });
  }

  Future<bool> sendItem() async {
    final ThemeData theme = Theme.of(context);
    final TextStyle dialogTextStyle =
        theme.textTheme.subhead.copyWith(color: theme.textTheme.caption.color);

    String range = parseWindow(windows, window, amPm);

    message = 'Window: $range\n'
        'Date: ${DateFormat('EEE, MMM d yyyy').format(pickupTime)}\n'
        'Duration: ${duration > 1 ? '$duration days' : '$duration day'}\n\n'
        'Pickup note: ${note.length > 0 ? '\n\nAdditional Note:\n$note' : ''}';

    return await showDialog<bool>(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: Text('Preview new pickup'),
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
                    validateSend(sendNewTime);
                    // Pops the confirmation dialog but not the page.
                  },
                ),
              ],
            );
          },
        ) ??
        false;
  }

  void validateSend(action) {
    if (!validate(window, amPm)) {
      showRequestErrorDialog(1);
    } else if (DateTime.now().add(Duration(hours: 1)).isAfter(pickupTime)) {
      showRequestErrorDialog(2);
    } else {
      action();
    }
  }

  Future<bool> showRequestErrorDialog(int type) async {
    final ThemeData theme = Theme.of(context);
    final TextStyle dialogTextStyle =
        theme.textTheme.subhead.copyWith(color: theme.textTheme.caption.color);
    String message;

    switch (type) {
      case 1:
        message = 'Pickup window cannot be between midnight and 5 AM';
        break;
      case 2:
        message = 'Pickup window must start at least one hour from now';
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
                  child: const Text('Ok'),
                  onPressed: () {
                    Navigator.of(context).pop(
                        false); // Pops the confirmation dialog but not the page.
                  },
                ),
              ],
            );
          },
        ) ??
        false;
  }

  Future<bool> onWillPop() async {
    final ThemeData theme = Theme.of(context);
    final TextStyle dialogTextStyle =
        theme.textTheme.subhead.copyWith(color: theme.textTheme.caption.color);

    return await showDialog<bool>(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              content: Text(
                'Discard changes?',
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
                  child: const Text('Discard'),
                  onPressed: () {
                    Navigator.of(context).pop(
                        true); // Returning true to _onWillPop will pop again.
                  },
                ),
              ],
            );
          },
        ) ??
        false;
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

    return DefaultTextStyle(
      style: theme.textTheme.subhead,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text('Day to pickup item', style: theme.textTheme.caption),
          Container(
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              decoration: BoxDecoration(
                  border:
                      Border(bottom: BorderSide(color: theme.dividerColor))),
              child: InkWell(
                onTap: () {
                  showDatePicker(
                    context: context,
                    initialDate: dateTime,
                    firstDate: DateTime(2000),
                    lastDate: DateTime(2100),
                  ).then<void>((DateTime value) {
                    if (value != null) {
                      onChangedDateTime(updateDateTime(value.year, value.month,
                          value.day, windows, window, amPm));
                    }
                  });
                },
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: <Widget>[
                    Text(DateFormat('EEE, MMM d yyyy').format(dateTime)),
                    const Icon(Icons.arrow_drop_down, color: Colors.black54),
                  ],
                ),
              ),
            ),
          ),
          Container(
            height: 12,
          ),
          Text(
              'Pickup window\n(earliest pickup must be at least 1 hr from now)',
              style: theme.textTheme.caption),
          Container(
            //margin: const EdgeInsets.only(left: 8.0),
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            decoration: BoxDecoration(
                border: Border(bottom: BorderSide(color: theme.dividerColor))),
            child: InkWell(
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
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: <Widget>[
                  Text(range),
                  const Icon(Icons.arrow_drop_down, color: Colors.black54),
                ],
              ),
            ),
          ),
          Container(
            height: 12,
          ),
          Text('How many days will you be renting?',
              style: theme.textTheme.caption),
          Container(
            //margin: const EdgeInsets.only(left: 8.0),
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            decoration: BoxDecoration(
                border: Border(bottom: BorderSide(color: theme.dividerColor))),
            child: InkWell(
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
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: <Widget>[
                  Text('$duration'),
                  const Icon(Icons.arrow_drop_down, color: Colors.black54),
                ],
              ),
            ),
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
