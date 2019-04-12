import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/foundation.dart';
import 'package:shareapp/models/item.dart';
import 'package:shareapp/pages/item_edit.dart';
import 'package:shareapp/pages/request_item.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:cached_network_image/cached_network_image.dart';

class ItemDetail extends StatefulWidget {
  static const routeName = '/itemDetail';
  final String itemID;

  //ItemDetail(this.itemID, this.isMyItem);
  ItemDetail({Key key, this.itemID}) : super(key: key);

  @override
  State<StatefulWidget> createState() {
    return ItemDetailState();
  }
}

class ItemDetailState extends State<ItemDetail> {
  String appBarTitle = "Item Details";
  GoogleMapController googleMapController;

  //List<String> imageURLs = List();
  String url;
  double padding = 5.0;

  TextStyle textStyle;

  DocumentSnapshot itemDS;
  DocumentSnapshot creatorDS;
  SharedPreferences prefs;
  String myUserID;
  String itemCreator;

  bool isLoading;
  bool isMyItem = false;

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    getMyUserID();
    //getItemCreatorID();

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

  void getSnapshots() async {
    isLoading = true;
    DocumentSnapshot ds = await Firestore.instance
        .collection('items')
        .document(widget.itemID)
        .get();

    if (ds != null) {
      itemDS = ds;

      DocumentReference dr = itemDS['creator'];
      String str = dr.documentID;

      if (myUserID == str) {
        isMyItem = true;
      }

      ds = await Firestore.instance.collection('users').document(str).get();

      if (ds != null) {
        creatorDS = ds;
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
    textStyle = Theme.of(context).textTheme.title;

    return WillPopScope(
      onWillPop: () {
        // when user presses back button
        goToLastScreen();
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(appBarTitle),
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
              tooltip: 'Refresh item',
              onPressed: () {
                setState(
                  () {
                    getSnapshots();
                    //setCamera();
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
        bottomNavigationBar: isLoading
            ? Container(
                height: 0,
              )
            : bottomDetails(),
      ),
    );
  }

  Container bottomDetails() {
    return Container(
      height: 100.0,
      decoration: BoxDecoration(color: Colors.white, boxShadow: [
        BoxShadow(
            color: Colors.black12,
            offset: new Offset(0, -10.0),
            blurRadius: 200.0)
      ]),
      child: Row(
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.only(left: 30.0),
            child: Text(
              "\$${itemDS['price']}",
              style: TextStyle(fontSize: 25.0, fontWeight: FontWeight.bold),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(right: 30.0),
            child: requestButton(),
          )
        ],
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
      ),
    );
  }

  RaisedButton requestButton() {
    return RaisedButton(
        onPressed: isMyItem ? null : () => handleRequestItemPressed(),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5.0)),
        color: Colors.red,
        child: Text("Check Availability",
            style: TextStyle(
              color: Colors.white,
            )));
  }

  FloatingActionButton showFAB() {
    return FloatingActionButton(
      onPressed: () {
        navigateToEdit();
      },

      // Help text when you hold down FAB
      tooltip: 'Edit tem',

      // Set FAB icon
      child: Icon(Icons.edit),
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
    return Padding(
      padding: EdgeInsets.all(15),
      child: ListView(
        children: <Widget>[
          showItemCreator(),
          showItemName(),
          showItemDescription(),
          showItemPrice(),
          showItemType(),
          showItemCondition(),
          showNumImages(),
          showItemImages(),
          showItemLocation(),
        ],
      ),
    );
  }

  Widget showItemCreator() {
    return Padding(
      padding: EdgeInsets.all(padding),
      child: SizedBox(
          height: 50.0,
          child: Container(
            color: Color(0x00000000),
            child: Row(
              children: <Widget>[
                CachedNetworkImage(
                  key: new ValueKey<String>(
                      DateTime.now().millisecondsSinceEpoch.toString()),
                  imageUrl: creatorDS['photoURL'],
                  placeholder: (context, url) =>
                      new CircularProgressIndicator(),
                ),
                Container(width: 20),
                Text(
                  'Item created by:\n${creatorDS['displayName']}',
                  style: TextStyle(color: Colors.black, fontSize: 20.0),
                  textAlign: TextAlign.left,
                )
              ],
            ),
          )),
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
              'Name: ${itemDS['name']}',
              //itemName,
              style: TextStyle(color: Colors.black, fontSize: 20.0),
              textAlign: TextAlign.left,
            ),
          )),
    );
  }

  Widget showItemDescription() {
    return Padding(
      padding: EdgeInsets.all(padding),
      child: SizedBox(
          height: 50.0,
          child: Container(
            color: Color(0x00000000),
            child: Text(
              'Description: ${itemDS['description']}',
              style: TextStyle(color: Colors.black, fontSize: 20.0),
              textAlign: TextAlign.left,
            ),
          )),
    );
  }

  Widget showItemPrice() {
    return Padding(
      padding: EdgeInsets.all(padding),
      child: SizedBox(
          height: 50.0,
          child: Container(
            color: Color(0x00000000),
            child: Text(
              'Price: ${itemDS['price']}',
              style: TextStyle(color: Colors.black, fontSize: 20.0),
              textAlign: TextAlign.left,
            ),
          )),
    );
  }

  Widget showItemType() {
    return Padding(
      padding: EdgeInsets.all(padding),
      child: SizedBox(
          height: 50.0,
          child: Container(
            color: Color(0x00000000),
            child: Text(
              'Type: ${itemDS['type']}',
              style: TextStyle(color: Colors.black, fontSize: 20.0),
              textAlign: TextAlign.left,
            ),
          )),
    );
  }

  Widget showItemCondition() {
    return Padding(
      padding: EdgeInsets.all(padding),
      child: SizedBox(
          height: 50.0,
          child: Container(
            color: Color(0x00000000),
            child: Text(
              'Condition: ${itemDS['condition']}',
              style: TextStyle(color: Colors.black, fontSize: 20.0),
              textAlign: TextAlign.left,
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
    List imagesList = itemDS['images'];
    return Padding(
      padding: EdgeInsets.all(padding),
      child: imagesList.length > 0
          ? Container(
              margin: EdgeInsets.symmetric(vertical: 20.0),
              height: 200,
              child: getImagesListView(context))
          : Text('No images yet\n'),
    );
  }

  Widget showItemLocation() {
    GeoPoint gp = itemDS['location'];
    double lat = gp.latitude;
    double long = gp.longitude;
    setCamera();
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 30.0),
        child: Column(
          children: <Widget>[
            Padding(
              padding: EdgeInsets.only(bottom: 12.0),
              child: Text(
                'Click the marker to open options',
                textScaleFactor: 1.2,
              ),
            ),
            FlatButton(
              //materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              onPressed: setCamera,
              child: Text(
                'Reset camera',
                textScaleFactor: 1,
                textAlign: TextAlign.center,
              ),
            ),
            Center(
              child: SizedBox(
                width: 300.0,
                height: 300.0,
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
                          // to disable dragging, use ScaleGestureRecognizer()
                          // to enable dragging, use EagerGestureRecognizer()
                          EagerGestureRecognizer(),
                      //ScaleGestureRecognizer(),
                    ),
                  ].toSet(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  getImagesListView(BuildContext context) {
    List imagesList = itemDS['images'];
    return ListView.builder(
      shrinkWrap: true,
      scrollDirection: Axis.horizontal,
      itemCount: imagesList.length,
      itemBuilder: (BuildContext context, int index) {
        return new Container(
          width: 160.0,
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

  Item makeCopy(Item old) {
    Item output = Item();

    output.name = old.name;
    output.description = old.description;
    output.type = old.type;
    output.numImages = old.numImages;
    output.id = old.id;
    output.price = old.price;
    output.location = old.location;
    output.images = List();

    for (int i = 0; i < old.numImages; i++) {
      output.images.add(old.images[i]);
    }

    return output;
  }

  void navigateToEdit() async {
    Item editItem = Item.fromMapNoID(itemDS.data);

    Item result = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (BuildContext context) => ItemEdit(
                item: editItem,
              ),
          fullscreenDialog: true,
        ));

    if (result != null) {
      //updateParameters();
      //setCamera();
      setState(
        () {
          getSnapshots();
          //setCamera();
        },
      );
    }
  }

  void handleRequestItemPressed() async {
    /*
    setState(
      () {
        getSnapshots();
      },
    );
    */

    Item result = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (BuildContext context) => RequestItem(
                itemID: widget.itemID,
                itemRequester: myUserID,
              ),
          fullscreenDialog: true,
        ));
  }

  setCamera() async {
    GeoPoint gp = itemDS['location'];
    double lat = gp.latitude;
    double long = gp.longitude;

    LatLng newLoc = LatLng(lat, long);
    //final GoogleMapController controller = await _controller.future;
    googleMapController.animateCamera(CameraUpdate.newCameraPosition(
        new CameraPosition(target: newLoc, zoom: 11.5)));
  }

  void goToLastScreen() {
    Navigator.pop(context);
  }
}
