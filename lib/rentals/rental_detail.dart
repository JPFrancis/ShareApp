import 'package:shareapp/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/foundation.dart';
import 'package:shareapp/models/item.dart';
import 'package:shareapp/rentals/chat.dart';
import 'package:shareapp/models/rental.dart';
import 'package:shareapp/pages/item_edit.dart';
import 'package:shareapp/pages/home_page.dart';
import 'package:shareapp/pages/root_page.dart';
import 'package:shareapp/pages/item_detail.dart';
import 'package:shareapp/rentals/item_request.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:cached_network_image/cached_network_image.dart';

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
                    showAcceptRejectRequestButtons(),
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
    String itemOwner = 'Item owner: ${ownerDS['displayName']}';
    String itemRenter = 'Item renter: ${renterDS['displayName']}';
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
          'Item owner:\n${ownerDS['displayName']}',
          style: TextStyle(color: Colors.black, fontSize: 20.0),
          textAlign: TextAlign.left,
        ),
        Expanded(
          child: Container(
            height: 50,
            child: CachedNetworkImage(
              key: new ValueKey<String>(
                  DateTime.now().millisecondsSinceEpoch.toString()),
              imageUrl: ownerDS['photoURL'],
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

    if (isRenter) {
      switch (itemStatus) {
        case 1: // requested
          statusMessage = 'Status: requested\n'
              'Awaiting response from ${ownerDS['displayName']}';
          break;
        case 2: // accepted
          statusMessage = 'Status: accepted\n'
              '${ownerDS['displayName']} has accepted your request\n'
              'Awaiting ${ownerDS['displayName']} to send item';
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
    } else {
      switch (itemStatus) {
        case 1: // requested
          statusMessage = 'Status: requested\n'
              'Do you accept the request from ${renterDS['displayName']}?\n'
              '${renterDS['displayName']} wants to pick up the item between ${rentalDS['start']} and ${rentalDS['end']}';
          break;
        case 2: // accepted
          statusMessage = 'Status: accepted\n'
              '${ownerDS['displayName']} has accepted your request\n'
              'Get ready give the item to ${renterDS['displayName']}';
          break;
        case 3: // active
          statusMessage = 'Status: active\n'
              '${renterDS['displayName']} is currently renting your item\n'
              'Press the button when the item has been returned to you to end the rental';
          break;
        case 4: // returned
          statusMessage = 'Status: returned\n'
              'You have returned the item to ${ownerDS['displayName']}\n'
          'Waiting for ${renterDS['displayName']} to write a review';
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
          fontSize: 20,
        ),
      ),
    );
  }

  Widget showAcceptRejectRequestButtons() {
    return !isRenter && rentalDS['status'] == 1
        ? Container(
            child: Row(
              children: <Widget>[
                Expanded(
                  child: RaisedButton(
                    shape: new RoundedRectangleBorder(
                        borderRadius: new BorderRadius.circular(5.0)),
                    color: Colors.green,
                    textColor: Colors.white,
                    child: Text(
                      "Accept",
                      //addButton + " Images",
                      textScaleFactor: 1.25,
                    ),
                    onPressed: () {
                      updateStatus(2);
                    },
                  ),
                ),
                Container(
                  width: 15.0,
                ),
                Expanded(
                  child: RaisedButton(
                    shape: new RoundedRectangleBorder(
                        borderRadius: new BorderRadius.circular(5.0)),
                    color: Colors.red[800],
                    textColor: Colors.white,
                    child: Text(
                      "Reject",
                      textScaleFactor: 1.25,
                    ),
                    onPressed: () {},
                  ),
                ),
              ],
            ),
          )
        : Container();
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
                "${renterDS['displayName']} has returned the item",
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
    Firestore.instance
        .collection('users')
        .document(renterDS.documentID)
        .collection('rentals')
        .document(widget.rentalID)
        .delete();

    Firestore.instance
        .collection('users')
        .document(ownerDS.documentID)
        .collection('rentals')
        .document(widget.rentalID)
        .delete();

    /*
    DocumentReference documentReference = rentalDS.reference;
    
    Firestore.instance.collection('users').document(myUserID).updateData({
      'rentals': FieldValue.arrayRemove([documentReference])
    });

    Firestore.instance.collection('users').document(ownerDS.documentID).updateData({
      'rentals': FieldValue.arrayRemove([documentReference])
    });
    */

    Firestore.instance.collection('rentals').document(widget.rentalID).delete();

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
