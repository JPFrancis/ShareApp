import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:intl/intl.dart';
import 'package:shareapp/main.dart';
import 'package:shareapp/rentals/chat.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shareapp/rentals/new_pickup.dart';

enum Status {
  requested,
  accepted,
  active,
  returned,
  completed,
}

class RentalDetail extends StatefulWidget {
  static const routeName = '/itemRental';
  final String rentalID;

  //ItemDetail(this.itemID, this.isMyItem);
  RentalDetail({Key key, this.rentalID}) : super(key: key);

  @override
  State<StatefulWidget> createState() {
    return RentalDetailState();
  }
}

class RentalDetailState extends State<RentalDetail> {
  GoogleMapController googleMapController;

  SharedPreferences prefs;
  String myUserID;
  String url;
  bool isLoading;
  bool isRenter;

  DocumentSnapshot rentalDS;
  DocumentSnapshot itemDS;
  DocumentSnapshot ownerDS;
  DocumentSnapshot renterDS;

  TextStyle textStyle;
  double padding = 5.0;

  TextEditingController reviewController = TextEditingController();
  String review;

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    getMyUserID();
    getSnapshots();
  }

  void getMyUserID() async {
    prefs = await SharedPreferences.getInstance();
    myUserID = prefs.getString('userID') ?? '';
  }

  void getSnapshots() async {
    isLoading = true;
    DocumentReference dr;
    DocumentSnapshot ds = await Firestore.instance
        .collection('rentals')
        .document(widget.rentalID)
        .get();

    if (ds != null) {
      rentalDS = ds;

      dr = rentalDS['item'];

      ds = await Firestore.instance
          .collection('items')
          .document(dr.documentID)
          .get();

      if (ds != null) {
        itemDS = ds;
      }

      dr = rentalDS['owner'];

      ds = await Firestore.instance
          .collection('users')
          .document(dr.documentID)
          .get();

      if (ds != null) {
        ownerDS = ds;
      }

      dr = rentalDS['renter'];

      ds = await Firestore.instance
          .collection('users')
          .document(dr.documentID)
          .get();

      if (ds != null) {
        renterDS = ds;
      }

      if (prefs != null &&
          itemDS != null &&
          ownerDS != null &&
          renterDS != null) {
        setState(() {
          isRenter = myUserID == renterDS.documentID ? true : false;
          isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    textStyle = Theme.of(context).textTheme.title;

    return WillPopScope(
      onWillPop: () {
        goToLastScreen();
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text('Item Rental'),
          // back button
          leading: IconButton(
            icon: Icon(Icons.arrow_back),
            onPressed: () {
              goToLastScreen();
            },
          ),
          actions: <Widget>[
            IconButton(
              icon: Icon(Icons.delete),
              tooltip: 'Delete rental',
              onPressed: () {
                setState(() {
                  deleteRentalDialog();
                });
              },
            ),
          ],
        ),
        body: isLoading
            ? Container(
                child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: <Widget>[
                      Center(child: CircularProgressIndicator())
                    ]),
              )
            : showBody(),
        floatingActionButton: showFAB(),
      ),
    );
  }

  FloatingActionButton showFAB() {
    return FloatingActionButton(
      onPressed: () {
        Navigator.pushNamed(
          context,
          Chat.routeName,
          arguments: ChatArgs(
            widget.rentalID,
          ),
        );
      },
      tooltip: 'Chat',
      child: Icon(Icons.message),
    );
  }

  Future<DocumentSnapshot> getRentalFromFirestore() async {
    DocumentSnapshot ds = await Firestore.instance
        .collection('rentals')
        .document(widget.rentalID)
        .get();

    return ds;
  }

  Widget showBody() {
    return StreamBuilder<DocumentSnapshot>(
      stream: rentalDS.reference.snapshots(),
      builder:
          (BuildContext context, AsyncSnapshot<DocumentSnapshot> snapshot) {
        if (snapshot.hasError) {
          return new Text('${snapshot.error}');
        }
        switch (snapshot.connectionState) {
          case ConnectionState.waiting:
            return Center(
              child: new Container(),
            );
          default:
            if (snapshot.hasData) {
              rentalDS = snapshot.data;

              return Padding(
                padding: EdgeInsets.all(15),
                child: ListView(
                  children: <Widget>[
                    showItemName(),
                    Divider(
                      height: 20,
                    ),
                    showItemRequestStatus(),
                    Container(
                      height: 10,
                    ),
                    showRequestButtons(),
                    showReceiveItemButton(),
                    showReturnedItemButton(),
                    showWriteReview(),
                  ],
                ),
              );
            } else {
              return Container();
            }
        }
      },
    );

    /*
    return Padding(
      padding: EdgeInsets.all(15),
      child: ListView(
        children: <Widget>[
          showItemName(),
          Divider(
            height: 20,
          ),
          showItemRequestStatus(),
          showAcceptRejectButtons(),
        ],
      ),
    );
    */
  }

  Widget showItemName() {
    String itemOwner = 'Item owner: ${ownerDS['name']}';
    String itemRenter = 'Item renter: ${renterDS['name']}';
    String you = ' (You)';

    isRenter ? itemRenter += you : itemOwner += you;

    return Container(
      child: Text(
        'Item name: ${itemDS['name']}\n'
            '$itemOwner\n'
            '$itemRenter',
        style: TextStyle(
          fontSize: 20,
        ),
      ),
    );
  }

  Widget showItemOwner() {
    return Row(
      children: <Widget>[
        Text(
          'Item owner:\n${ownerDS['name']}',
          style: TextStyle(color: Colors.black, fontSize: 20.0),
          textAlign: TextAlign.left,
        ),
        Expanded(
          child: Container(
            height: 50,
            child: CachedNetworkImage(
              key: new ValueKey<String>(
                  DateTime.now().millisecondsSinceEpoch.toString()),
              imageUrl: ownerDS['avatar'],
              placeholder: (context, url) => new CircularProgressIndicator(),
            ),
          ),
        ),
      ],
    );
  }

  Widget showItemRequestStatus() {
    int itemStatus = rentalDS['status'];
    String statusMessage;

    String start = DateFormat('h:mm a on EEE, MMM d yyyy')
        .format(rentalDS['pickupStart'].toDate());
    String end = DateFormat('h:mm a on EEE, MMM d yyyy')
        .format(rentalDS['pickupEnd'].toDate());
    int durationDays = rentalDS['duration'];
    String duration =
        '${durationDays > 1 ? '$durationDays days' : '$durationDays day'}';

    // IF YOU ARE THE RENTER
    if (isRenter) {
      switch (itemStatus) {
        case 0: // requested, renter has sent request
          statusMessage = 'Status: requested (0)\n'
              'Awaiting response from ${ownerDS['name']}\n'
              'Your proposed pickup window:\n'
              'Start: $start\n'
              'End: $end\n'
              'Rental duration: $duration';
          break;
        case 1: // requested, renter need to accept/reject pickup window
          statusMessage = 'Status: requested (0)\n'
              '${ownerDS['name']} has proposed a pickup window:\n'
              'Start: $start\n'
              'End: $end\n'
              'Rental duration: $duration';
          break;
        case 2: // accepted
          statusMessage = 'Status: accepted\n'
              '${ownerDS['name']} has accepted your request\n'
              'Awaiting ${ownerDS['name']} to send item';
          break;
        case 3: // active
          statusMessage = 'Status: active\n'
              'Happy renting your ${itemDS['name']}!\n'
              'Return the item when you are done';
          break;
        case 4: // returned
          statusMessage = 'Status: returned\n'
              '${itemDS['name']} has been returned to you\n'
              'Please write a review of the item';
          break;
        case 5: // completed
          statusMessage = 'Status: completed\n'
              'Rental has been complete!';
          break;
        default:
          statusMessage = 'There was an error with getting status';
          break;
      }
    }

    // IF YOU ARE THE OWNER
    else {
      switch (itemStatus) {
        case 0: // requested, owner needs to accept/reject pickup window
          statusMessage = 'Status: requested (0)\n'
              '${renterDS['name']} has proposed a pickup window:\n'
              'Start: $start\n'
              'End: $end\n'
              'Rental duration: $duration';
          break;
        case 1: // requested, owner has sent new pickup window
          statusMessage = 'Status: requested (0)\n'
              'Awaiting response from ${renterDS['name']}\n'
              'Your proposed pickup window:\n'
              'Start: $start\n'
              'End: $end\n'
              'Rental duration: $duration';
          break;
        case 2: // accepted
          statusMessage = 'Status: accepted\n'
              '${ownerDS['name']} has accepted your request\n'
              'Get ready give the item to ${renterDS['name']}';
          break;
        case 3: // active
          statusMessage = 'Status: active\n'
              '${renterDS['name']} is currently renting your item\n'
              'Press the button when the item has been returned to you to end the rental';
          break;
        case 4: // returned
          statusMessage = 'Status: returned\n'
              'You have returned the item to ${ownerDS['name']}\n'
              'Waiting for ${renterDS['name']} to write a review';
          break;
        case 5: // completed
          statusMessage = 'Status: completed\n'
              'Rental has completed!';
          break;
        default:
          statusMessage = 'There was an error with getting status';
          break;
      }
    }

    return Container(
      child: Text(
        statusMessage,
        style: TextStyle(
          fontSize: 18,
        ),
      ),
    );
  }

  Widget showRequestButtons() {
    return (isRenter && rentalDS['status'] == 1) ||
            (!isRenter && rentalDS['status'] == 0)
        ? Container(
            child: Column(
              children: <Widget>[
                Row(
                  children: <Widget>[
                    Expanded(
                      child: reusableButton('Accept', Colors.green, () {
                        updateStatus(2);
                      }),
                    ),
                    Container(
                      width: 10,
                    ),
                    Expanded(
                      child: reusableButton('Propose new time',
                          Colors.orange[700], newPickupProposal),
                    ),
                    Container(
                      width: 10,
                    ),
                    Expanded(
                      child: reusableButton('Reject', Colors.red[800], null),
                    ),
                  ],
                ),
                Container(
                  padding: EdgeInsets.only(top: 15),
                  child: Text(
                    'Pickup note: ${rentalDS['note']}',
                    textAlign: TextAlign.left,
                    style: TextStyle(
                      fontSize: 20,
                    ),
                  ),
                ),
              ],
            ),
          )
        : Container();
  }

  Widget reusableButton(String text, Color color, action) {
    return ButtonTheme(
      height: 60,
      child: RaisedButton(
        shape: new RoundedRectangleBorder(
            borderRadius: new BorderRadius.circular(5.0)),
        color: color,
        textColor: Colors.white,
        child: Text(
          text,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 16,
          ),
        ),
        onPressed: () {
          action();
        },
      ),
    );
  }

  Widget showReceiveItemButton() {
    return isRenter && rentalDS['status'] == 2
        ? Container(
            child: RaisedButton(
              shape: new RoundedRectangleBorder(
                  borderRadius: new BorderRadius.circular(5.0)),
              color: Colors.green,
              textColor: Colors.white,
              child: Text(
                "I have received the item",
                //addButton + " Images",
                textScaleFactor: 1.25,
              ),
              onPressed: () {
                updateStatus(3);
              },
            ),
          )
        : Container();
  }

  Widget showReturnedItemButton() {
    return !isRenter && rentalDS['status'] == 3
        ? Container(
            child: RaisedButton(
              shape: new RoundedRectangleBorder(
                  borderRadius: new BorderRadius.circular(5.0)),
              color: Colors.green,
              textColor: Colors.white,
              child: Text(
                "${renterDS['name']} has returned the item",
                //addButton + " Images",
                textScaleFactor: 1.25,
              ),
              onPressed: () {
                updateStatus(4);
              },
            ),
          )
        : Container();
  }

  Widget showWriteReview() {
    return isRenter && rentalDS['status'] == 4
        ? Container(
            child: Column(
              children: <Widget>[
                showWriteReviewTextBox(),
                showSubmitReviewButton(),
              ],
            ),
          )
        : Container();
  }

  Widget showSubmitReviewButton() {
    return RaisedButton(
      shape: new RoundedRectangleBorder(
          borderRadius: new BorderRadius.circular(5.0)),
      color: Colors.green,
      textColor: Colors.white,
      child: Text(
        'Submit Review',
        //addButton + " Images",
        textScaleFactor: 1.25,
      ),
      onPressed: () {
        updateStatus(5);
      },
    );
  }

  Widget showWriteReviewTextBox() {
    return Padding(
      padding: EdgeInsets.all(padding),
      child: TextField(
        maxLines: 3,
        controller: reviewController,
        style: textStyle,
        onChanged: (value) {
          review = reviewController.text;
        },
        decoration: InputDecoration(
          labelText: 'Write review',
          filled: true,
        ),
      ),
    );
  }

  void updateStatus(int status) async {
    Firestore.instance
        .collection('rentals')
        .document(widget.rentalID)
        .updateData({'status': status});
  }

  void newPickupProposal() async {
    Navigator.pushNamed(
      context,
      NewPickup.routeName,
      arguments: NewPickupArgs(widget.rentalID, isRenter),
    );
  }

  Future<bool> deleteRentalDialog() async {
    final ThemeData theme = Theme.of(context);

    return await showDialog<bool>(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: Text('Delete rental?'),
              actions: <Widget>[
                FlatButton(
                  child: const Text('Cancel'),
                  onPressed: () {
                    Navigator.of(context).pop(
                        false); // Pops the confirmation dialog but not the page.
                  },
                ),
                FlatButton(
                  child: const Text('Delete'),
                  onPressed: () {
                    Navigator.of(context).pop(false);
                    deleteRental();
                    // Pops the confirmation dialog but not the page.
                  },
                ),
              ],
            );
          },
        ) ??
        false;
  }

  void deleteRental() async {
    int delay = 500;

    setState(() {
      isLoading = true;
    });

    await new Future.delayed(Duration(milliseconds: delay));

    Firestore.instance
        .collection('users')
        .document(renterDS.documentID)
        .collection('rentals')
        .document(widget.rentalID)
        .delete();

    await new Future.delayed(Duration(milliseconds: delay));

    Firestore.instance
        .collection('users')
        .document(ownerDS.documentID)
        .collection('rentals')
        .document(widget.rentalID)
        .delete();

    await new Future.delayed(Duration(milliseconds: delay));

    Firestore.instance.collection('rentals').document(widget.rentalID).delete();

    await new Future.delayed(Duration(milliseconds: delay));

    Firestore.instance
        .collection('rentals')
        .document(widget.rentalID)
        .collection('chat')
        .getDocuments()
        .then((snapshot) {
      for (DocumentSnapshot ds in snapshot.documents) {
        ds.reference.delete();
      }
    });

    await new Future.delayed(Duration(milliseconds: delay));

    Firestore.instance
        .collection('items')
        .document(itemDS.documentID)
        .updateData({'rental': null});

    goToLastScreen();
  }

  void goToLastScreen() {
    Navigator.popUntil(
      context,
      ModalRoute.withName('/'),
    );
  }
}
