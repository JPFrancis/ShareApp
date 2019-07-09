import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_picker/flutter_picker.dart';
import 'package:intl/intl.dart';
import 'package:shareapp/extras/helpers.dart';
import 'package:shareapp/main.dart';
import 'package:shareapp/rentals/rental_detail.dart';
import 'package:shareapp/services/const.dart';
import 'package:shareapp/services/picker_data.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum DismissDialogAction {
  cancel,
  discard,
  save,
}

class ItemRequest extends StatefulWidget {
  static const routeName = '/requestItem';
  final String itemID;
  final DateTime startDate;

  ItemRequest({Key key, this.itemID, this.startDate}) : super(key: key);

  @override
  State<StatefulWidget> createState() {
    return ItemRequestState();
  }
}

class ItemRequestState extends State<ItemRequest> {
  final GlobalKey<FormState> formKey = new GlobalKey<FormState>();
  SharedPreferences prefs;

  bool isUploading = false;
  bool isLoading;

  String myUserID;
  String photoURL;
  String myName;
  String groupChatId;
  List<String> combinedID;

  DocumentSnapshot itemDS;
  DocumentSnapshot itemOwnerDS;
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

    initPickerData();
    getMyUserID();
    getSnapshots();
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

  Future<bool> validateRental() async {
    DocumentReference itemDR =
        Firestore.instance.collection('items').document(itemDS.documentID);

    DateTime pickupTimeCopy = stripHourMin(pickupTime);

    // get the rental that starts immediately before the current request
    var rentalBeforeCurrent = await Firestore.instance
        .collection('rentals')
        .where('item', isEqualTo: itemDR)
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

  void initPickerData() {
    List pickerData = JsonDecoder().convert(PickerData);
    windows = pickerData[0];
    duration = 1;

    pickupTime = widget.startDate;

    pickupTime = DateTime(
        pickupTime.year, pickupTime.month, pickupTime.day, 5, 0, 0, 0, 0);

    window = 8;
    amPm = 0;
  }

  void getMyUserID() async {
    prefs = await SharedPreferences.getInstance();
    myUserID = prefs.getString('userID') ?? '';
    myName = prefs.getString('name') ?? '';
  }

  Future<Null> getSnapshots() async {
    isLoading = true;
    DocumentSnapshot ds = await Firestore.instance
        .collection('items')
        .document(widget.itemID)
        .get();

    if (ds != null) {
      itemDS = ds;

      DocumentReference dr = itemDS['creator'];
      String str = dr.documentID;

      ds = await Firestore.instance.collection('users').document(str).get();

      if (ds != null) {
        itemOwnerDS = ds;
      }

      if (prefs != null && itemDS != null && itemOwnerDS != null) {
        if (myUserID.hashCode <= itemOwnerDS.documentID.hashCode) {
          groupChatId = '$myUserID-${itemOwnerDS.documentID}';
          combinedID = [myUserID, itemOwnerDS.documentID];
        } else {
          groupChatId = '${itemOwnerDS.documentID}-$myUserID';
          combinedID = [itemOwnerDS.documentID, myUserID];
        }

        if (groupChatId != null && combinedID != null) {
          setState(() {
            isLoading = false;
          });
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: primaryColor.withBlue(155).withGreen(157).withRed(92),
      floatingActionButton: Container(
        padding: const EdgeInsets.only(top: 120.0, left: 5.0),
        child: FloatingActionButton(
          onPressed: () => Navigator.pop(context),
          child: Icon(Icons.close),
          elevation: 1,
          backgroundColor: Colors.white70,
          foregroundColor: primaryColor,
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.miniStartTop,
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
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.only(bottom: 10.0),
        child: Container(
          height: 60.0,
          padding: EdgeInsets.symmetric(vertical: 10.0, horizontal: 20.0),
          child: RaisedButton(
            elevation: 3.0,
            onPressed: () => validateSend(sendItem),
            color: Colors.white,
            child: Text(
              'Request',
              style: TextStyle(color: primaryColor, fontFamily: 'Quicksand'),
            ),
          ),
        ),
      ),
    );
  }

  Widget showBody() {
    return ListView(
      physics: NeverScrollableScrollPhysics(),
      padding: EdgeInsets.all(0),
      children: <Widget>[
        showItemImage(),
        SizedBox(
          height: 10.0,
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10.0),
          child: Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 15.0, vertical: 5.0),
            decoration: new BoxDecoration(
                boxShadow: <BoxShadow>[
                  CustomBoxShadow(
                      color: Colors.black,
                      blurRadius: 2.0,
                      blurStyle: BlurStyle.outer),
                ],
                color: Colors.white,
                borderRadius: new BorderRadius.all(
                  Radius.circular(20.0),
                )),
            child: Container(
              height: MediaQuery.of(context).size.height,
              child: Column(
                children: <Widget>[
                  showItemCreator(),
                  divider(),
                  showTimePickers(),
                  divider(),
                  showItemPriceInfo(),
                ],
              ),
            ),
          ),
        ),
        // showNoteEdit(),
        //showTimeInfo(), // testing purposes only
      ],
    );
  }

  Widget showItemImage() {
    double widthOfScreen = MediaQuery.of(context).size.width;
    _getItemImage(BuildContext context) {
      var image = itemDS['images'][0];
      return ClipRRect(
        borderRadius: new BorderRadius.all(Radius.circular(20.0)),
        child: FittedBox(
          fit: BoxFit.cover,
          child: CachedNetworkImage(
            imageUrl: image,
            placeholder: (context, url) => new CircularProgressIndicator(),
          ),
        ),
      );
    }

    List imagesList = itemDS['images'];
    return imagesList.length > 0
        ? Container(
            decoration: BoxDecoration(
              borderRadius: new BorderRadius.all(
                Radius.circular(20.0),
              ),
              boxShadow: <BoxShadow>[
                CustomBoxShadow(
                    color: Colors.black,
                    blurRadius: 7.0,
                    blurStyle: BlurStyle.outer),
              ],
            ),
            height: widthOfScreen / 1,
            child: _getItemImage(context),
          )
        : Text('No images yet\n');
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

  Widget showItemCreator() {
    return Padding(
      padding: EdgeInsets.only(left: 20.0, right: 20.0, top: 10.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: <Widget>[
          Text(
            itemDS['name'],
            style: TextStyle(
                color: Colors.black,
                fontFamily: 'Quicksand',
                fontSize: 25.0,
                fontWeight: FontWeight.w500),
          ),
          Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              Container(
                height: 50.0,
                child: ClipOval(
                  child: CachedNetworkImage(
                    imageUrl: itemOwnerDS['avatar'],
                    placeholder: (context, url) =>
                        new CircularProgressIndicator(),
                  ),
                ),
              ),
              Text(
                '${itemOwnerDS['name']}',
                style: TextStyle(
                    color: Colors.black,
                    fontSize: 15.0,
                    fontFamily: 'Quicksand'),
                textAlign: TextAlign.left,
              ),
            ],
          ),
        ],
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
              Text('\$${itemDS['price'] * duration}',
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

  void navToItemRental() async {
    int delay = 500;

    setState(() {
      isUploading = true;
    });

    String rentalID;

    // create rental in 'rentals' collection
    DocumentReference rentalDR =
        await Firestore.instance.collection("rentals").add({
      'status': 0,
      'requesting': true,
      'item': Firestore.instance.collection('items').document(widget.itemID),
      'itemName': itemDS['name'],
      'owner': Firestore.instance
          .collection('users')
          .document(itemOwnerDS.documentID),
      'renter': Firestore.instance.collection('users').document(myUserID),
      'pickupStart': pickupTime,
      'pickupEnd': pickupTime.add(Duration(hours: 1)),
      'rentalEnd': pickupTime.add(Duration(days: duration, hours: 1)),
      'created': DateTime.now(),
      'duration': duration,
      'note': note,
      'users': [
        Firestore.instance.collection('users').document(itemOwnerDS.documentID),
        Firestore.instance.collection('users').document(myUserID),
      ],
      'renterCC': null,
      'ownerCC': null,
      'review': null,
      'initialPushNotif': {
        'nameFrom': myName,
        'pushToken': itemOwnerDS['pushToken'],
        'itemName': itemDS['name'],
      },
    });

    if (rentalDR != null) {
      rentalID = rentalDR.documentID;

      DocumentSnapshot ds = await Firestore.instance
          .collection('messages')
          .document(groupChatId)
          .get();

      if (ds != null) {
        if (!ds.exists) {
          var documentReference =
              Firestore.instance.collection('messages').document(groupChatId);

          Firestore.instance.runTransaction((transaction) async {
            await transaction.set(
              documentReference,
              {
                'users': combinedID,
              },
            );
          });
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
              'idFrom': myUserID,
              'idTo': itemOwnerDS.documentID,
              'timestamp': DateTime.now().millisecondsSinceEpoch,
              'content': message,
              'type': 0,
              'pushToken': itemOwnerDS['pushToken'],
              'nameFrom': myName,
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
                ),
              );
            }
          });
        }
      }
    }
  }

  Future<bool> sendItem() async {
    final ThemeData theme = Theme.of(context);
    final TextStyle dialogTextStyle =
        theme.textTheme.subhead.copyWith(color: theme.textTheme.caption.color);

    String range = parseWindow(windows, window, amPm);

    message = 'Hello ${itemOwnerDS['name']}, '
        'I am requesting to rent your ${itemDS['name']} '
        'for ${duration > 1 ? '$duration days' : '$duration day'}. '
        'I would like to pick up this item '
        'from $range on ${DateFormat('EEE, MMM d yyyy').format(pickupTime)}.'
        '${note.length > 0 ? '\n\nAdditional Note for pickup:\n$note' : ''}';

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

  void validateSend(action) async {
    if (!validate(window, amPm)) {
      showRequestErrorDialog(2);
    } else if (DateTime.now().add(Duration(hours: 1)).isAfter(pickupTime)) {
      showRequestErrorDialog(3);
    } else {
      bool timeIsValid = await validateRental();

      if (timeIsValid) {
        action();
      } else {
        showRequestErrorDialog(4);
      }
    }
  }

  Future<bool> showRequestErrorDialog(int type) async {
    final ThemeData theme = Theme.of(context);
    final TextStyle dialogTextStyle =
        theme.textTheme.subhead.copyWith(color: theme.textTheme.caption.color);
    String message;

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
        message = 'Your rental request time interferes with another rental! Try'
            ' selecting a different pickup day or changing the rental duration';
        break;
      case 5:
        message = 'Item no longer exists';
        break;
      case 6:
        message = 'The item owner has disabled renting on this item';
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
    double w = MediaQuery.of(context).size.width;

    return Container(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: <Widget>[
          InkWell(
            onTap: () {
              showDatePicker(
                      context: context,
                      initialDate: stripHourMin(dateTime),
                      firstDate: stripHourMin(DateTime.now()),
                      lastDate: DateTime.now().add(Duration(days: 300)))
                  .then<void>((DateTime value) {
                if (value != null) {
                  onChangedDateTime(updateDateTime(value.year, value.month,
                      value.day, windows, window, amPm));
                }
              });
            },
            child: Column(
              children: <Widget>[
                Text('Pickup Date',
                    style: TextStyle(
                        fontFamily: 'Quicksand',
                        fontWeight: FontWeight.w200,
                        fontSize: w / 30),
                    textAlign: TextAlign.start),
                SizedBox(height: 3),
                Container(
                  child: Center(
                    child: Text(
                      DateFormat('MMM d').format(dateTime),
                      style: TextStyle(
                          color: primaryColor,
                          fontFamily: 'Quicksand',
                          fontSize: w / 25),
                    ),
                  ),
                ),
              ],
            ),
          ),
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
