import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter/material.dart';
import 'package:shareapp/models/item.dart';
import 'package:shareapp/pages/item_edit.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/rendering.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ItemDetail extends StatefulWidget {
  final String itemID;

  ItemDetail(this.itemID);

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

  DocumentSnapshot documentSnapshot;

  //Item item;

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
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
                tooltip: 'Refresh Item',
                onPressed: () {
                  setState(() {
                    setCamera();
                  });
                },
              ),
              IconButton(
                icon: Icon(Icons.edit),
                tooltip: 'Edit Item',
                onPressed: () {
                  navigateToEdit();
                },
              ),
            ]),
        body: showBody(),
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
            padding: EdgeInsets.only(top: 15.0, left: 10.0, right: 10.0),
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
        } else {
          return new Center(
            child: CircularProgressIndicator(),
          );
        }
      },
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
              'Name: ${documentSnapshot['name']}',
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
              'Description: ${documentSnapshot['description']}',
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
              'Price: ${documentSnapshot['price']}',
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
              'Type: ${documentSnapshot['type']}',
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
              'Condition: ${documentSnapshot['condition']}',
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
              'Num images: ${documentSnapshot['numImages']}',
              style: TextStyle(color: Colors.black, fontSize: 20.0),
              textAlign: TextAlign.left,
            ),
          )),
    );
  }

  Widget showItemImages() {
    List imagesList = documentSnapshot['images'];
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
    GeoPoint gp = documentSnapshot['location'];
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
    List imagesList = documentSnapshot['images'];
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
    Item editItem = Item.fromMapNoID(documentSnapshot.data);

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
      setCamera();
    }
  }

  setCamera() async {
    GeoPoint gp = documentSnapshot['location'];
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
