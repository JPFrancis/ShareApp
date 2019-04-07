import 'dart:io';
import 'dart:async';
import 'package:intl/intl.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cached_network_image/cached_network_image.dart';

enum DismissDialogAction {
  cancel,
  discard,
  save,
}

class RequestItem extends StatefulWidget {
  final String itemRequester;
  final String itemID;

  RequestItem({Key key, this.itemRequester, this.itemID}) : super(key: key);

  @override
  State<StatefulWidget> createState() {
    return RequestItemState();
  }
}

/// We initially assume we are in editing mode
class RequestItemState extends State<RequestItem> {
  final GlobalKey<FormState> formKey = new GlobalKey<FormState>();
  SharedPreferences prefs;

  bool isUploading = false;
  String photoURL;

  TextEditingController displayNameController = TextEditingController();

  TextStyle textStyle;
  TextStyle inputTextStyle;

  DocumentSnapshot documentSnapshot;
  ThemeData theme;
  double padding = 5.0;
  String note;
  TextEditingController noteController = TextEditingController();

  Future<File> selectedImage;
  File imageFile;

  DateTime _fromDateTime = DateTime.now();
  DateTime _toDateTime = DateTime.now();

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    theme = Theme.of(context);
    textStyle =
        Theme.of(context).textTheme.headline.merge(TextStyle(fontSize: 20));
    inputTextStyle = Theme.of(context).textTheme.subtitle;
    note = '';

    return Scaffold(
      appBar: AppBar(
        title: Text('Item Request'),
        actions: <Widget>[
          FlatButton(
            child: Text('SEND',
                textScaleFactor: 1.05,
                style: theme.textTheme.body2.copyWith(color: Colors.white)),
            onPressed: () {},
          ),
        ],
      ),
      body: Stack(
        children: <Widget>[
          isUploading
              ? Container(
                  decoration:
                      new BoxDecoration(color: Colors.white.withOpacity(0.0)),
                )
              : showBody(),
          showCircularProgress(),
        ],
      ),
    );
  }

  Future<DocumentSnapshot> getItemFromFirestore() async {
    DocumentSnapshot ds = await Firestore.instance
        .collection('items')
        .document(widget.itemID)
        .get();

    return ds;
  }

  Widget showBody() {
    return FutureBuilder(
      future: getItemFromFirestore(),
      builder: (BuildContext context, AsyncSnapshot snapshot) {
        if (snapshot.hasData) {
          documentSnapshot = snapshot.data;

          /// usage: ds['name']
          return Padding(
            padding: EdgeInsets.all(15),
            child: ListView(
              children: <Widget>[
                showItemName(),
                showItemCreator(),
                Container(
                  height: 10,
                ),
                showStartTimePicker(),
                showEndTimePicker(),
                Container(
                  height: 10,
                ),
                showNoteEdit(),

              ],
            ),
          );
        } else {
          return new Center(
            child: CircularProgressIndicator(),
          );
        }
      },
    );
  }

  Widget showItemName() {
    return Padding(
      padding: EdgeInsets.all(padding),
      child: SizedBox(
          height: 50.0,
          child: Container(
            color: Color(0x00000000),
            child: Text(
              'You\'re requesting a:\n${documentSnapshot['name']}',
              //itemName,
              style: TextStyle(color: Colors.black, fontSize: 20.0),
              textAlign: TextAlign.left,
            ),
          )),
    );
  }

  Widget showItemCreator() {
    return FutureBuilder(
      future: documentSnapshot['creator'].get(),
      builder: (BuildContext context, AsyncSnapshot snapshot) {
        DocumentSnapshot ds = snapshot.data;

        return Padding(
          padding: EdgeInsets.all(padding),
          child: SizedBox(
            height: 50.0,
            child: Container(
              color: Color(0x00000000),
              child: snapshot.hasData
                  ? Row(
                      children: <Widget>[
                        Text(
                          'You\'re requesting from:\n${ds['displayName']}',
                          style: TextStyle(color: Colors.black, fontSize: 20.0),
                          textAlign: TextAlign.left,
                        ),
                        Expanded(
                          child: CachedNetworkImage(
                            key: new ValueKey<String>(DateTime.now()
                                .millisecondsSinceEpoch
                                .toString()),
                            imageUrl: ds['photoURL'],
                            placeholder: (context, url) =>
                                new CircularProgressIndicator(),
                          ),
                        ),
                      ],
                    )
                  : Container(),
            ),
          ),
        );
      },
    );
  }

  Widget showNoteEdit() {
    return Padding(
      padding: EdgeInsets.all(padding),
      child: TextField(
        //keyboardType: TextInputType.multiline,
        maxLines: 3,
        controller: noteController,
        style: textStyle,
        onChanged: (value) {
          note = noteController.text;
        },
        decoration: InputDecoration(
          labelText: 'Add note (optional)',
          filled: true,
          //border: OutlineInputBorder(borderRadius: BorderRadius.circular(5.0)),
        ),
      ),
    );
  }

  Widget showStartTimePicker() {
    return Padding(
      padding: EdgeInsets.all(padding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text('Start', style: theme.textTheme.caption),
          DateTimeItem(
            dateTime: _fromDateTime,
            onChanged: (DateTime value) {
              setState(() {
                _fromDateTime = value;
              });
            },
          ),
        ],
      ),
    );
  }

  Widget showEndTimePicker() {
    return Padding(
      padding: EdgeInsets.all(padding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text('End', style: theme.textTheme.caption),
          DateTimeItem(
            dateTime: _toDateTime,
            onChanged: (DateTime value) {
              setState(() {
                _toDateTime = value;
              });
            },
          ),
        ],
      ),
    );
  }

  Widget showCircularProgress() {
    if (isUploading) {
      //return Center(child: CircularProgressIndicator());

      return Container(
        child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              Text(
                "Sending...",
                style: TextStyle(fontSize: 30),
              ),
              Container(
                height: 20.0,
              ),
              Center(child: CircularProgressIndicator())
            ]),
      );
    }
    return Container(
      height: 0.0,
      width: 0.0,
    );
  }

  Future<bool> onWillPop() async {
    //if (widget.userEdit.displayName == userEditCopy.displayName) return true;

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
  DateTimeItem({Key key, DateTime dateTime, @required this.onChanged})
      : assert(onChanged != null),
        date = DateTime(dateTime.year, dateTime.month, dateTime.day),
        time = TimeOfDay(hour: dateTime.hour, minute: dateTime.minute),
        super(key: key);

  final DateTime date;
  final TimeOfDay time;
  final ValueChanged<DateTime> onChanged;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return DefaultTextStyle(
      style: theme.textTheme.subhead,
      child: Row(
        children: <Widget>[
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              decoration: BoxDecoration(
                  border:
                      Border(bottom: BorderSide(color: theme.dividerColor))),
              child: InkWell(
                onTap: () {
                  showDatePicker(
                    context: context,
                    initialDate: date,
                    firstDate: date.subtract(const Duration(days: 30)),
                    lastDate: date.add(const Duration(days: 30)),
                  ).then<void>((DateTime value) {
                    if (value != null)
                      onChanged(DateTime(value.year, value.month, value.day,
                          time.hour, time.minute));
                  });
                },
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: <Widget>[
                    Text(DateFormat('EEE, MMM d yyyy').format(date)),
                    const Icon(Icons.arrow_drop_down, color: Colors.black54),
                  ],
                ),
              ),
            ),
          ),
          Container(
            margin: const EdgeInsets.only(left: 8.0),
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            decoration: BoxDecoration(
                border: Border(bottom: BorderSide(color: theme.dividerColor))),
            child: InkWell(
              onTap: () {
                showTimePicker(
                  context: context,
                  initialTime: time,
                ).then<void>((TimeOfDay value) {
                  if (value != null)
                    onChanged(DateTime(date.year, date.month, date.day,
                        value.hour, value.minute));
                });
              },
              child: Row(
                children: <Widget>[
                  Text('${time.format(context)}'),
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
