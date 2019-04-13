import 'package:shareapp/pages/item_detail.dart';
import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/foundation.dart';
import 'package:shareapp/models/item.dart';
import 'package:shareapp/models/rental.dart';
import 'package:shareapp/pages/item_edit.dart';
import 'package:shareapp/pages/item_list.dart';
import 'package:shareapp/pages/root_page.dart';
import 'package:shareapp/pages/request_item.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shareapp/pages/chat.dart';
import 'package:shareapp/main.dart';

enum Status {
  requested,
  accepted,
  active,
  returned,
  completed,
}

class ItemRental extends StatefulWidget {
  static const routeName = '/itemRental';
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
        Navigator.of(context).pushNamedAndRemoveUntil('/', (_) => false);
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text('Item Rental'),
          // back button
          leading: IconButton(
            icon: Icon(Icons.arrow_back),
            onPressed: () {
              Navigator.of(context).pushNamedAndRemoveUntil('/', (_) => false);
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

      // Help text when you hold down FAB
      tooltip: 'Chat',

      // Set FAB icon
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
    return Padding(
      padding: EdgeInsets.all(15),
      child: ListView(
        children: <Widget>[
          showItemName(),
          showCancelRequest(),
        ],
      ),
    );
  }

  Widget showItemName() {
    return Container(
      child: Text(
        'Item name: ${itemDS['name']}\n'
            'Item owner: ${ownerDS['displayName']}\n'
            'Item renter: ${renterDS['displayName']}',
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

  Widget showCancelRequest() {
    return Container(
      child: RaisedButton(
        shape: new RoundedRectangleBorder(
            borderRadius: new BorderRadius.circular(5.0)),
        color: Colors.red,
        textColor: Colors.white,
        child: Text(
          'Delete Rental',
          textScaleFactor: 1.25,
        ),
        onPressed: () {
          setState(() {
            deleteRental();
          });
        },
      ),
    );
  }

  void deleteRental() async {
    Firestore.instance.collection('rentals').document(widget.rentalID).delete();

    Firestore.instance
        .collection('messages')
        .document(widget.rentalID)
        .delete();

    Firestore.instance
        .collection('messages')
        .document(widget.rentalID)
        .collection(widget.rentalID)
        .getDocuments()
        .then((snapshot) {
      for (DocumentSnapshot ds in snapshot.documents) {
        ds.reference.delete();
      }
    });

    Firestore.instance
        .collection('items')
        .document(itemDS['id'])
        .updateData({'rental': null});
/*
    Navigator.popUntil(context, (Route<dynamic> route){
      bool shouldPop = false;
      if (route.settings.name == ItemDetail.routeName){
        shouldPop = true;
      }
      return shouldPop;
    });
*/

    Navigator.of(context)
        .pushNamedAndRemoveUntil('/', (_) => false);

/*
    Navigator.popUntil(
      context,
      ModalRoute.withName('/'),
    );
    */
  }

  void goToLastScreen() {
    Navigator.pop(context);
  }
}
