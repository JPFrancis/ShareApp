import 'dart:async';

import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter/material.dart';
import 'package:shareapp/models/item.dart';
import 'package:shareapp/pages/item_edit.dart';
import 'package:shareapp/pages/request_item.dart';
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
        /*
        appBar: AppBar(
          backgroundColor: const Color(0xFFB4C56C).withOpacity(0.5),
 
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
                    setCamera();
                  },
                );
              },
            ),
            IconButton(
              icon: Icon(Icons.add_shopping_cart),
              tooltip: 'Request item',
              onPressed: () {
                handleRequestItemPressed();
              },
            ),
          ],
        ),*/
        body: showBody(),
        bottomNavigationBar: bottomDetails(),
      ),
    );
  }

  Container bottomDetails() {
    return Container(
      height: 120.0,
      decoration: BoxDecoration(color: Colors.white, boxShadow: [BoxShadow(color: Colors.black12, offset: new Offset(0, -10.0), blurRadius: 200.0)]),
      child: 
        Row(children: <Widget>[
          Padding(
            padding: const EdgeInsets.only(left: 30.0),
            child: Text("\$20", style: TextStyle(fontSize: 25.0, fontWeight: FontWeight.bold),),
          ), 
          Padding(
            padding: const EdgeInsets.only(right: 30.0),
            child: requestButton(),
          )
        ],
        mainAxisAlignment: MainAxisAlignment.spaceBetween, ),
      );
  }
  
  RaisedButton requestButton(){
    return RaisedButton(
      onPressed: () => handleRequestItemPressed(),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5.0)),
      color: Colors.red,
      child: Text("Check Availability", style: TextStyle(color: Colors.white,))
    );
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
    return FutureBuilder(
      future: getItemFromFirestore(),
      builder: (BuildContext context, AsyncSnapshot snapshot) {
        if (snapshot.hasData) {
          documentSnapshot = snapshot.data;

          /// usage: ds['name']
          return ListView(
            children: <Widget>[
              Stack(children: <Widget> [showItemImages(), IconButton(icon: Icon(Icons.arrow_back), onPressed: () { goToLastScreen(); },)]),
              showItemDescription(),
              showItemName(),
              showItemCreator(),
              showItemType(),
              showItemCondition(),
//            showNumImages(),
              showItemLocation(),
            ],
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
            padding: EdgeInsets.only(left: 20.0, right: 20.0, top: 10.0),
            child: SizedBox(
                child: Container(
                  height: 50.0,
                  color: Color(0x00000000),
                  child: snapshot.hasData
                      ? Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: <Widget>[
                            Text(
                                'Shared by ${ds['displayName']}',
                                style: TextStyle(
                                    color: Colors.black, fontSize: 20.0),
                                textAlign: TextAlign.left,
                              ),
                            ClipOval(
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
                )),
          );
        });
  }

  Widget showItemName() {
    return Padding(
      padding: const EdgeInsets.only(left: 20.0),
      child: SizedBox(
          child: Container(
            color: Color(0x00000000),
            child: Text(
              '${documentSnapshot['name']}',
              //itemName,
              style: TextStyle(color: Colors.black, fontSize: 50.0, fontWeight: FontWeight.bold),
              textAlign: TextAlign.left,
            ),
          )),
    );
  }

  Widget showItemPrice() {
    return Padding(
      padding: EdgeInsets.only(left: 20.0),
      child: SizedBox(
          //height: 50.0,
          child: Container(
            color: Color(0x00000000),
            child: Text(
              '${documentSnapshot['price']}',
              style: TextStyle(color: Colors.black, fontSize: 30.0, fontWeight: FontWeight.bold),
              textAlign: TextAlign.left,
            ),
          )),
    );
  }

  Widget showItemDescription() {
    return Padding(
      padding: EdgeInsets.only(top: 20.0, left: 20.0),
      child: SizedBox(
          child: Container(
            color: Color(0x00000000),
            child: Text(
              '${documentSnapshot['description']}'.toUpperCase(),
              style: TextStyle(color: Colors.black54, fontSize: 15.0, fontWeight: FontWeight.bold),
              textAlign: TextAlign.left,
            ),
          )),
    );
  }


  Widget showItemType() {
    return Padding(
      padding: EdgeInsets.only(left: 20.0),
      child: SizedBox(
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
      padding: EdgeInsets.only(left: 20.0, top: 15.0),
      child: SizedBox(
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
    return imagesList.length > 0 
      ? Container(height: 350, child: SizedBox.expand(child: getImagesListView(context)),) 
      : Text('No images yet\n');
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
          width: 350.0,
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
    return new SizedBox.expand(
//      width: 300.0,
 //     height: 150.0,
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

  void handleRequestItemPressed() async {
    setState(
          () {},
    );

    Item result = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (BuildContext context) => RequestItem(
            itemID: widget.itemID,
            itemRequester: "",
          ),
          fullscreenDialog: true,
        ));
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
