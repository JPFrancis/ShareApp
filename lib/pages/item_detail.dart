import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:shareapp/main.dart';
import 'package:shareapp/models/item.dart';
import 'package:shareapp/pages/item_edit.dart';
import 'package:shareapp/rentals/item_request.dart';
import 'package:shareapp/rentals/rental_detail.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ItemDetail extends StatefulWidget {
  static const routeName = '/itemDetail';
  final String itemID;

  ItemDetail({Key key, this.itemID}) : super(key: key);

  @override
  State<StatefulWidget> createState() {
    return ItemDetailState();
  }
}

class ItemDetailState extends State<ItemDetail> {
  final GlobalKey<RefreshIndicatorState> refreshIndicatorKey =
      new GlobalKey<RefreshIndicatorState>();

  GoogleMapController googleMapController;
  String appBarTitle = "Item Details";

  String url;
  double padding = 5.0;

  DocumentSnapshot itemDS;
  DocumentSnapshot creatorDS;
  DocumentSnapshot rentalDS;
  SharedPreferences prefs;
  String myUserID;
  String itemCreator;

  bool isLoading;

  @override
  void initState() {
    // TODO: implement initState
    super.initState();

    WidgetsBinding.instance
        .addPostFrameCallback((_) => refreshIndicatorKey.currentState.show());

    getMyUserID();
    getSnapshots();
  }

  void getMyUserID() async {
    prefs = await SharedPreferences.getInstance();
    myUserID = prefs.getString('userID') ?? '';
  }

  void getItemCreatorID() async {
    Firestore.instance
        .collection('items')
        .document(widget.itemID)
        .get()
        .then((DocumentSnapshot ds) {
      itemCreator = ds['creatorID'];
    });
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
        creatorDS = ds;
      }

      dr = itemDS['rental'];

      if (dr != null) {
        str = dr.documentID;
        ds = await Firestore.instance.collection('rentals').document(str).get();

        if (ds != null) {
          rentalDS = ds;
        }
      }

      if (prefs != null && itemDS != null && creatorDS != null) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () {
        goToLastScreen();
      },
      child: Scaffold(
        body: RefreshIndicator(
          key: refreshIndicatorKey,
          onRefresh: getSnapshots,
          child: isLoading
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
        //floatingActionButton: showFAB(),
        bottomNavigationBar: isLoading
            ? Container(
                height: 0,
              )
            : bottomDetails(),
      ),
    );
  }

  Container bottomDetails() {
    bool userIsInRental;

    if (creatorDS.documentID == myUserID) {
      userIsInRental = true;
    } else if (rentalDS != null && rentalDS['renter'].documentID == myUserID) {
      userIsInRental = true;
    } else {
      userIsInRental = false;
    }

    return Container(
      height: 70.0,
      decoration: BoxDecoration(color: Colors.white, boxShadow: [
        BoxShadow(
          color: Colors.black12,
          offset: new Offset(0, -0.5),
        )
      ]),
      child: Row(
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.only(left: 30.0),
            child: showItemPrice(),
          ),
          Padding(
            padding: const EdgeInsets.only(right: 30.0),
            child: userIsInRental ? viewRentalButton() : requestButton(),
          )
        ],
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
      ),
    );
  }

  RaisedButton requestButton() {
    return RaisedButton(
        onPressed:
            itemDS['rental'] != null ? null : () => handleRequestItemPressed(),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5.0)),
        color: Colors.red,
        child: Text('Request Item', //Text("Check Availability",
            style: TextStyle(color: Colors.white, fontFamily: 'Quicksand')));
  }

  RaisedButton viewRentalButton() {
    return RaisedButton(
        onPressed:
            itemDS['rental'] == null ? null : () => handleViewRentalPressed(),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5.0)),
        color: Colors.red,
        child: Text('View Rental',
            style: TextStyle(color: Colors.white, fontFamily: 'Quicksand')));
  }

  Widget showFAB() {
    return Padding(
      padding: const EdgeInsets.only(right: 10.0),
      child: RaisedButton(
        onPressed: () => navigateToEdit(),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5.0)),
        color: Colors.red,
        child: Icon(Icons.edit),
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
    return ListView(
      children: <Widget>[
        Stack(children: <Widget>[
          showItemImages(),
          backButton(),
        ]),
        showItemType(),
        showItemName(),
        showItemCondition(),
        showItemCreator(),
        showItemDescription(),
        divider(),
        showItemLocation(),
      ],
    );
  }

  Widget backButton() {
    return Container(
      alignment: Alignment.topLeft,
      child: FloatingActionButton(
        child: BackButton(),
        onPressed: () => goToLastScreen(),
        backgroundColor: Colors.transparent,
        elevation: 0.0,
        foregroundColor: Colors.black,
      ),
    );
  }

  Widget divider() {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Divider(),
    );
  }

  Widget showItemCreator() {
    return Padding(
      padding: EdgeInsets.only(left: 20.0, right: 20.0, top: 10.0),
      child: SizedBox(
          child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: <Widget>[
          Text(
            'Shared by ${creatorDS['displayName']}',
            style: TextStyle(
                color: Colors.black, fontSize: 15.0, fontFamily: 'Quicksand'),
            textAlign: TextAlign.left,
          ),
          Container(
            height: 50.0,
            child: ClipOval(
              child: CachedNetworkImage(
                key: new ValueKey<String>(
                    DateTime.now().millisecondsSinceEpoch.toString()),
                imageUrl: creatorDS['photoURL'],
                placeholder: (context, url) => new CircularProgressIndicator(),
              ),
            ),
          ),
        ],
      )),
    );
  }

  Widget showItemName() {
    return Padding(
      padding: const EdgeInsets.only(left: 20.0),
      child: SizedBox(
          child: Container(
        color: Color(0x00000000),
        child: Text(
          '${itemDS['name']}',
          style: TextStyle(
              color: Colors.black,
              fontSize: 40.0,
              fontWeight: FontWeight.bold,
              fontFamily: 'Quicksand'),
          textAlign: TextAlign.left,
        ),
      )),
    );
  }

  Widget showItemPrice() {
    return SizedBox(
        //height: 50.0,
        child: Container(
      color: Color(0x00000000),
      child: Row(
        children: <Widget>[
          Text(
            '\$${itemDS['price']}',
            style: TextStyle(
                color: Colors.black,
                fontSize: 25.0,
                fontWeight: FontWeight.bold,
                fontFamily: 'Quicksand'),
          ),
          Text(
            ' / HOUR',
            style: TextStyle(
                color: Colors.black, fontSize: 12.0, fontFamily: 'Quicksand'),
          )
        ],
      ),
    ));
  }

  Widget showItemDescription() {
    return Padding(
      padding: EdgeInsets.only(top: 20.0, left: 20.0, right: 20.0),
      child: SizedBox(
          child: Container(
        color: Color(0x00000000),
        child: Text(
          '${itemDS['description']}',
          style: TextStyle(
              color: Colors.black, fontSize: 15.0, fontFamily: 'Quicksand'),
          textAlign: TextAlign.left,
        ),
      )),
    );
  }

  Widget showItemType() {
    return Padding(
      padding: EdgeInsets.only(left: 20.0, top: 20.0),
      child: SizedBox(
          child: Container(
        color: Color(0x00000000),
        child: Text(
          '${itemDS['type']}'.toUpperCase(),
          style: TextStyle(
              color: Colors.black54,
              fontSize: 12.0,
              fontWeight: FontWeight.bold,
              fontFamily: 'Quicksand'),
          textAlign: TextAlign.left,
        ),
      )),
    );
  }

  Widget showItemCondition() {
    return Padding(
      padding: EdgeInsets.only(left: 20.0, top: 5.0),
      child: SizedBox(
          child: Container(
        color: Color(0x00000000),
        child: Row(
          children: <Widget>[
            Text(
              'Condition: ',
              style: TextStyle(
                  color: Colors.black54,
                  fontSize: 13.0,
                  fontStyle: FontStyle.italic,
                  fontFamily: 'Quicksand'),
              textAlign: TextAlign.left,
            ),
            Text(
              '${itemDS['condition']}',
              style: TextStyle(
                  color: Colors.black,
                  fontSize: 14.0,
                  fontStyle: FontStyle.italic,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Quicksand'),
              textAlign: TextAlign.left,
            ),
          ],
        ),
      )),
    );
  }

  Widget showNumImages() {
    return Padding(
      padding: EdgeInsets.all(padding),
      child: SizedBox(
          height: 50.0,
          child: Container(
            color: Color(0x00000000),
            child: Text(
              'Num images: ${itemDS['numImages']}',
              style: TextStyle(color: Colors.black, fontSize: 20.0),
              textAlign: TextAlign.left,
            ),
          )),
    );
  }

  Widget showItemImages() {
    double widthOfScreen = MediaQuery.of(context).size.width;
    List imagesList = itemDS['images'];
    return imagesList.length > 0
        ? Container(
            height: widthOfScreen,
            child: SizedBox.expand(child: getImagesListView(context)),
          )
        : Text('No images yet\n');
  }

  Widget showItemLocation() {
    double widthOfScreen = MediaQuery.of(context).size.width;
    GeoPoint gp = itemDS['location'];
    double lat = gp.latitude;
    double long = gp.longitude;

    return Padding(
      padding: const EdgeInsets.only(left: 20.0, right: 20.0),
      child: Column(
        children: <Widget>[
          Align(
            alignment: Alignment.centerLeft,
            child: Padding(
              padding: EdgeInsets.only(bottom: 12.0),
              child: Text('The Location',
                  style: TextStyle(
                      fontSize: 15.0,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                      fontFamily: 'Quicksand')
                  //textScaleFactor: 1.2,
                  ),
            ),
          ),
          Center(
            child: SizedBox(
              width: widthOfScreen,
              height: 200.0,
              child: GoogleMap(
                mapType: MapType.normal,
                rotateGesturesEnabled: false,
                initialCameraPosition: CameraPosition(
                  target: LatLng(lat, long),
                  zoom: 11.5,
                ),
                onMapCreated: (GoogleMapController controller) {
                  googleMapController = controller;
                },
                markers: Set<Marker>.of(
                  <Marker>[
                    Marker(
                      markerId: MarkerId("test_marker_id"),
                      position: LatLng(
                        lat,
                        long,
                      ),
                      infoWindow: InfoWindow(
                        title: 'Item Location',
                        snippet: '${lat}, ${long}',
                      ),
                    )
                  ],
                ),
                gestureRecognizers: <Factory<OneSequenceGestureRecognizer>>[
                  Factory<OneSequenceGestureRecognizer>(
                    () =>

                        /// to disable dragging, use ScaleGestureRecognizer()
                        /// to enable dragging, use EagerGestureRecognizer()
                        EagerGestureRecognizer(),
                    //ScaleGestureRecognizer(),
                  ),
                ].toSet(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  getImagesListView(BuildContext context) {
    double widthOfScreen = MediaQuery.of(context).size.width;
    List imagesList = itemDS['images'];
    return ListView.builder(
      shrinkWrap: true,
      scrollDirection: Axis.horizontal,
      itemCount: imagesList.length,
      itemBuilder: (BuildContext context, int index) {
        return new Container(
          width: widthOfScreen,
          child: sizedContainer(
            new CachedNetworkImage(
              key: new ValueKey<String>(
                  DateTime.now().millisecondsSinceEpoch.toString()),
              imageUrl: imagesList[index],
              placeholder: (context, url) => new CircularProgressIndicator(),
            ),
          ),
        );
      },
    );
  }

  Widget sizedContainer(Widget child) {
    return new SizedBox(
      width: 300.0,
      height: 150.0,
      child: new Center(
        child: child,
      ),
    );
  }

  void navigateToEdit() async {
    Item editItem = Item.fromMap(itemDS.data);

    Item result = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (BuildContext context) => ItemEdit(
                item: editItem,
              ),
          fullscreenDialog: true,
        ));

    if (result != null) {
      setState(
        () {
          getSnapshots();
        },
      );
    }
  }

  void handleRequestItemPressed() async {
    getSnapshots().then(
      (_) {
        itemDS['rental'] != null
            ? showRequestErrorDialog()
            : Navigator.pushNamed(
                context,
                ItemRequest.routeName,
                arguments: ItemRequestArgs(
                  widget.itemID,
                ),
              );
      },
    );
  }

  void handleViewRentalPressed() async {
    getSnapshots().then(
      (_) {
        Navigator.pushNamed(
          context,
          RentalDetail.routeName,
          arguments: RentalDetailArgs(
            rentalDS.documentID,
          ),
        );
      },
    );
  }

  Future<bool> showRequestErrorDialog() async {
    final ThemeData theme = Theme.of(context);
    final TextStyle dialogTextStyle =
        theme.textTheme.subhead.copyWith(color: theme.textTheme.caption.color);

    String message = 'Someone has already requested this item!';

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

  setCamera() async {
    GeoPoint gp = itemDS['location'];
    double lat = gp.latitude;
    double long = gp.longitude;

    LatLng newLoc = LatLng(lat, long);
    googleMapController.animateCamera(CameraUpdate.newCameraPosition(
        new CameraPosition(target: newLoc, zoom: 11.5)));
  }

  void goToLastScreen() {
    Navigator.pop(context);
  }
}
