import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/foundation.dart';
import 'package:shareapp/models/item.dart';
import 'package:shareapp/models/rental.dart';
import 'package:shareapp/pages/item_edit.dart';
import 'package:shareapp/pages/request_item.dart';
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

class ItemRental extends StatefulWidget {
  final String rentalID;

  //ItemDetail(this.itemID, this.isMyItem);
  ItemRental({Key key, this.rentalID}) : super(key: key);

  @override
  State<StatefulWidget> createState() {
    return ItemRentalState();
  }
}

class ItemRentalState extends State<ItemRental> {
  GoogleMapController googleMapController;

  //List<String> imageURLs = List();
  String url;
  double padding = 5.0;

  TextStyle textStyle;

  DocumentSnapshot rentalDS;
  DocumentSnapshot itemDS;
  DocumentSnapshot ownerDS;
  DocumentSnapshot renterDS;
  SharedPreferences prefs;
  String myUserID;

  bool isLoading;

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
    DocumentSnapshot ds = await Firestore.instance
        .collection('rentals')
        .document(widget.rentalID)
        .get();

    if (ds != null) {
      rentalDS = ds;

      ds = await Firestore.instance
          .collection('items')
          .document(rentalDS['item'])
          .get();

      if (ds != null) {
        itemDS = ds;
      }

      ds = await Firestore.instance
          .collection('users')
          .document(rentalDS['owner'])
          .get();

      if (ds != null) {
        ownerDS = ds;
      }

      ds = await Firestore.instance
          .collection('users')
          .document(rentalDS['renter'])
          .get();

      if (ds != null) {
        renterDS = ds;
      }

      if (prefs != null &&
          itemDS != null &&
          ownerDS != null &&
          renterDS != null) {
        setState(() {
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
        // when user presses back button
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
              icon: Icon(Icons.refresh),
              tooltip: 'Refresh rental',
              onPressed: () {
                setState(
                  () {
                    getSnapshots();
                  },
                );
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
      ),
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
    return Padding(
      padding: EdgeInsets.all(15),
      child: ListView(
        children: <Widget>[
          showItemCreator(),
          showItemName(),
        ],
      ),
    );
  }

  Widget showItemRequestStatus() {
    int itemStatus = itemDS['status'];
    String statusMessage;

    switch (itemStatus) {
      case 1: // requested
        statusMessage = 'Status: requested\n'
            'Awaiting response from ${ownerDS['displayName']}';
        break;
      case 2: // accepted
        statusMessage = 'Status: accepted\n'
            '${ownerDS['displayName']} has accepted your request';
        break;
      case 3: // active
        statusMessage = 'Status: active\n'
            'Happy renting your ${itemDS['name']}!';
        break;
      case 4: // returned
        statusMessage = 'Status: returned\n'
            '${itemDS['name']} has been returned to ${ownerDS['displayName']}';
        break;
      case 5: // completed
        statusMessage = 'Status: completed\n'
            'Rental has completed';
        break;
      default:
        statusMessage = 'There was an error with getting status';
        break;
    }

    return Padding(
      padding: EdgeInsets.all(padding),
      child: SizedBox(
        height: 50.0,
        child: Container(
          color: Color(0x00000000),
          child: Text(
            statusMessage,
            style: TextStyle(color: Colors.black, fontSize: 20.0),
            textAlign: TextAlign.left,
          ),
        ),
      ),
    );
  }

  Widget showItemCreator() {
    return FutureBuilder(
        future: rentalDS['creator'].get(),
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
                            CachedNetworkImage(
                              key: new ValueKey<String>(DateTime.now()
                                  .millisecondsSinceEpoch
                                  .toString()),
                              imageUrl: ds['photoURL'],
                              placeholder: (context, url) =>
                                  new CircularProgressIndicator(),
                            ),
                            Container(width: 20),
                            Text(
                              'Item created by:\n${ds['displayName']}',
                              style: TextStyle(
                                  color: Colors.black, fontSize: 20.0),
                              textAlign: TextAlign.left,
                            )
                          ],
                        )
                      : Container(),
                )),
          );
        });
  }

  Widget showItemName() {
    return Padding(
      padding: EdgeInsets.all(padding),
      child: SizedBox(
          height: 50.0,
          child: Container(
            color: Color(0x00000000),
            child: Text(
              'Name: ${rentalDS['name']}',
              //itemName,
              style: TextStyle(color: Colors.black, fontSize: 20.0),
              textAlign: TextAlign.left,
            ),
          )),
    );
  }

  void goToLastScreen() {
    Navigator.pop(context);
  }
}
