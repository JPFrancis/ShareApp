import 'dart:async';
import 'dart:typed_data';
import 'dart:io' show Platform;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:geoflutterfire/geoflutterfire.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:multi_image_picker/multi_image_picker.dart';
import 'package:shareapp/extras/helpers.dart';
import 'package:shareapp/main.dart';
import 'package:shareapp/models/current_user.dart';
import 'package:shareapp/models/item.dart';
import 'package:shareapp/pages/item_detail.dart';
import 'package:shareapp/services/const.dart';
import 'package:shareapp/services/database.dart';
import 'package:shareapp/services/functions.dart';
import 'package:shareapp/services/select_location.dart';
import 'package:uni_links/uni_links.dart';
import 'package:url_launcher/url_launcher.dart';

enum DismissDialogAction {
  cancel,
  discard,
  save,
}

class ItemEdit extends StatefulWidget {
  static const routeName = '/itemEdit';
  final Item item;
  final String itemId;

  ItemEdit({Key key, this.item, this.itemId}) : super(key: key);

  @override
  State<StatefulWidget> createState() {
    return ItemEditState();
  }
}

/// We initially assume we are in editing mode
class ItemEditState extends State<ItemEdit> {
  final GlobalKey<FormState> formKey = new GlobalKey<FormState>();
  CurrentUser currentUser;
  FirebaseUser firebaseUser;
  String itemId;

  String appBarText = "Edit"; // Either 'Edit' or 'Add'. Prepended to " Item"
  String addButton = "Edit"; // 'Edit' if edit, 'Add' if adding
  String updateButton = "Save"; // 'Save' if edit, 'Add' if adding

  List<Asset> imageAssets = List<Asset>();
  List imageURLs = List();
  String imageFileName;
  int totalImagesCount;
  bool imageButton = false;
  bool isEdit; // true if on editing mode, false if on adding mode
  bool isLoading = false;

  GoogleMapController googleMapController;
  TextEditingController nameController = TextEditingController();
  TextEditingController descriptionController = TextEditingController();
  TextEditingController priceController = TextEditingController();

  List<DropdownMenuItem<String>> dropDownItemType;
  List<DropdownMenuItem<String>> dropDownItemCondition;

  TextStyle textStyle;
  TextStyle inputTextStyle;
  ThemeData theme;

  Item itemCopy;
  Position currentLocation;
  Geoflutterfire geo = Geoflutterfire();

  @override
  void initState() {
    super.initState();

    currentUser = CurrentUser.getModel(context);

    if (currentUser.connectedAcctId == null) {
      initStream();
    }

    isLoading = true;
    itemId = widget.itemId;
    isEdit = itemId != null ? true : false;
    itemCopy = Item.copy(widget.item);

    nameController.text = itemCopy.name;
    descriptionController.text = itemCopy.description;
    priceController.text = itemCopy.price.toString();

    /// new item
    if (!isEdit) {
      appBarText = "Add";
      addButton = "Add";
      updateButton = "Add";
    }

    if (itemCopy.numImages == 0) {
      imageButton = true;
    }

    imageURLs.addAll(itemCopy.images);

    totalImagesCount = itemCopy.numImages;
    imageAssets = List<Asset>();

    const itemType = <String>[
      'Tool',
      'Leisure',
      'Home',
      'Equipment',
      'Other',
    ];

    dropDownItemType = itemType
        .map((String value) => DropdownMenuItem<String>(
            value: value,
            child: Text(value, style: TextStyle(fontFamily: 'Quicksand'))))
        .toList();

    const itemCondition = <String>[
      'Lightly Used',
      'Good',
      'Fair',
      'Has Character',
    ];

    dropDownItemCondition = itemCondition
        .map((String value) => DropdownMenuItem<String>(
            value: value,
            child: Text(value, style: TextStyle(fontFamily: 'Quicksand'))))
        .toList();

    getLoc();
  }

  @override
  void dispose() {
    nameController.dispose();
    descriptionController.dispose();
    priceController.dispose();

    super.dispose();
  }

  void initStream() async {
    getLinksStream().listen((link) async {
      try {
        var latestUri;
        if (link != null) latestUri = Uri.parse(link);
        qq('$latestUri');

        dynamic value = await DB()
            .addStripeConnectedAccount(
                url: latestUri.toString(), userId: currentUser.id)
            .catchError((e) {
          setState(() {
            isLoading = false;
          });

          showToast('An error occurred');
        });

        if (value != null && value is String && value.isNotEmpty) {
          currentUser.addConnectedAcctId(value);
          showToast('Success! Creating item now..');
          saveItem();
        }
      } on FormatException {
        showToast('An error occurred');
      }
    });
  }

  void getLoc() async {
    if (isEdit) {
      setState(() {
        isLoading = false;
      });
    } else {
      FirebaseAuth.instance.currentUser().then((user) {
        firebaseUser = user;
      });

      currentLocation = currentUser.currentLocation;

      if (currentLocation != null) {
        setState(() {
          itemCopy.location['geopoint'] =
              GeoPoint(currentLocation.latitude, currentLocation.longitude);
          isLoading = false;
        });
      } else {
        showToast('Could not get location');
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    theme = Theme.of(context);
    textStyle =
        Theme.of(context).textTheme.headline.merge(TextStyle(fontSize: 20));
    inputTextStyle = Theme.of(context).textTheme.subtitle;

    return Scaffold(
      resizeToAvoidBottomPadding: true,
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
      floatingActionButton: isLoading
          ? Container()
          : RaisedButton(
              child: Text('Next ＞',
                  style:
                      TextStyle(color: Colors.white, fontFamily: 'Quicksand')),
              color: Color(0xff007f6e),
              onPressed: () {
                saveWarning();
              },
            ),
    );
  }

  Widget showBody() {
    double height = MediaQuery.of(context).size.height;
    return Form(
      key: formKey,
      onWillPop: onWillPop,
      child: Stack(
        children: <Widget>[
          ListView(
              shrinkWrap: true,
              padding: EdgeInsets.only(
                  top: height / 15, bottom: 10.0, left: 17.0, right: 17.0),
              children: <Widget>[
                Align(
                    alignment: Alignment.topRight,
                    child: Text("$totalImagesCount / 8",
                        style: TextStyle(
                            fontFamily: 'Quicksand',
                            fontWeight: FontWeight.bold))),
                showImages(),
                divider(),
                reusableCategory("DETAILS"),
                reusableTextEntry("What are you listing? (required)", true,
                    nameController, 'name'),
                reusableTextEntry("Describe it... (required)", true,
                    descriptionController, 'description'),
                divider(),
                reusableCategory("SPECIFICS"),
                showTypeSelector(),
                showConditionSelector(),
                divider(),
                reusableCategory("PRICE"),
                reusableTextEntry("Price (per day)", true, priceController,
                    'price', TextInputType.number),
                divider(),
                reusableCategory("LOCATION"),
                showItemLocation(),
                showLocationButtons(),
                Text(
                  "* Your address will not be visible to any user other than you",
                  style: TextStyle(fontFamily: appFont, fontSize: 12.0),
                ),
                isEdit ? deleteButton() : Container()
              ]),
          Container(
            padding: EdgeInsets.only(top: 30, left: 20),
            alignment: Alignment.topLeft,
            child: FloatingActionButton(
                onPressed: () => Navigator.pop(context),
                child: Icon(Icons.arrow_back),
                elevation: 1,
                backgroundColor: Colors.white70,
                foregroundColor: primaryColor),
          ),
        ],
      ),
    );
  }

  Widget deleteButton() {
    return OutlineButton(
      child: Text(
        'Delete Item',
        style: TextStyle(fontFamily: 'Quicksand', color: Colors.red),
      ),
      onPressed: () => deleteItemDialog(),
      borderSide: BorderSide(color: Colors.red),
    );
  }

  Widget reusableTextEntry(placeholder, required, controller, saveTo,
      [keyboard = TextInputType.text]) {
    return Container(
      child: TextField(
        style: TextStyle(fontFamily: 'Quicksand'),
        keyboardType: keyboard,
        controller: controller,
        onChanged: (value) {
          switch (saveTo) {
            case 'name':
              itemCopy.name = controller.text;
              break;
            case 'description':
              itemCopy.description = controller.text;
              break;
            case 'price':
              itemCopy.price = int.parse(controller.text);
              break;
            default:
          }
        },
        decoration: InputDecoration(
          labelStyle: TextStyle(
              color: required ? Colors.black54 : Colors.black26,
              fontFamily: 'Quicksand'),
          labelText: placeholder,
          //border: OutlineInputBorder(borderRadius: BorderRadius.circular(5.0)),
        ),
      ),
    );
  }

  Widget reusableCategory(text) {
    return Container(
      alignment: Alignment.centerLeft,
      child: Text(
        text,
        style: TextStyle(
            fontSize: 11.0,
            fontWeight: FontWeight.w100,
            fontFamily: 'Quicksand'),
      ),
    );
  }

  Widget showImages() {
    return getAllImages(context);
  }

  getAllImages(BuildContext context) {
    List<Widget> databaseImages = itemCopy.images
        .map((image) => Container(
            decoration: BoxDecoration(border: Border.all()),
            child: FittedBox(
              fit: BoxFit.cover,
              child: CachedNetworkImage(
                  imageUrl: image,
                  placeholder: (context, url) =>
                      new CircularProgressIndicator()),
            )))
        .toList();

    List<Widget> assetImages = imageAssets
        .map((asset) => Container(
            decoration: BoxDecoration(border: Border.all()),
            child: AssetThumb(
              asset: asset,
              height: 250,
              width: 250,
            )))
        .toList();

    List<Widget> allImages = []..addAll(databaseImages)..addAll(assetImages);
    allImages.add(
      InkWell(
        onTap: () {
          loadAssets();
        },
        child: totalImagesCount < 8
            ? Container(
                decoration: BoxDecoration(border: Border.all()),
                child: Icon(Icons.add),
              )
            : Container(),
      ),
    );

    return Container(
      child: GridView.count(
        crossAxisSpacing: 5,
        mainAxisSpacing: 5,
        childAspectRatio: (5 / 5),
        padding: EdgeInsets.all(0),
        physics: NeverScrollableScrollPhysics(),
        crossAxisCount: 4,
        shrinkWrap: true,
        children: allImages,
      ),
    );
  }

  Widget showItemCreator() {
    return Container(
        child: Text(
      "Item created by: ${itemCopy.creator}",
      style: TextStyle(fontSize: 16),
    ));
  }

  Widget showTypeSelector() {
    return Container(
      padding: EdgeInsets.only(left: 15.0, right: 15.0),
      child: DropdownButton<String>(
        value: itemCopy.type,
        hint: Text(
          'Category',
          style: TextStyle(fontFamily: 'Quicksand'),
        ),
        onChanged: (String newValue) {
          setState(() => itemCopy.type = newValue);
        },
        items: dropDownItemType,
      ),
    );
  }

  Widget showConditionSelector() {
    return Container(
      padding: EdgeInsets.only(left: 15.0, right: 15.0),
      child: DropdownButton<String>(
        value: itemCopy.condition,
        hint: Text(
          'Condition',
          style: TextStyle(fontFamily: 'Quicksand'),
        ),
        onChanged: (String newValue) {
          setState(() {
            itemCopy.condition = newValue;
          });
        },
        items: dropDownItemCondition,
      ),
    );
  }

  Widget showImageCount() {
    return Container(
        child: Text(
      "Num images selected: ${itemCopy.numImages}",
      style: TextStyle(fontSize: 16),
    ));
  }

  Widget showImageButtons() {
    _showAlertDialog(BuildContext context) {
      // set up the buttons
      Widget cameraButton = FlatButton(
        child: Icon(Icons.camera),
        onPressed: () {},
      );
      Widget galleryButton = FlatButton(
        child: Icon(Icons.image),
        onPressed: () {
          loadAssets();
          Navigator.pop(context);
        },
      );

      CupertinoAlertDialog alert = CupertinoAlertDialog(
        actions: [
          cameraButton,
          galleryButton,
        ],
      );
      // show the dialog
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return alert;
        },
      );
    }

    return Container(
      child: Row(
        children: <Widget>[
          Expanded(
            child: RaisedButton(
                color: Colors.white,
                textColor: Colors.black,
                child: Text(
                  "Add Images",
                  style: TextStyle(fontFamily: 'Quicksand'),
                ),
                onPressed: () {
                  _showAlertDialog(context);
                }),
          ),
        ],
      ),
    );
  }

  Widget showSelectedLocation() {
    return Container(
      child: itemCopy.location['geopoint'] != null
          ? Text(
              "Selected location: ${itemCopy.location['geopoint'].latitude}, ${itemCopy.location['geopoint'].longitude}",
              style: TextStyle(fontSize: 16),
            )
          : Text(
              "No location yet",
              style: TextStyle(fontSize: 16),
            ),
    );
  }

  Widget showItemLocation() {
    if (itemCopy.location['geopoint'] == null) {
      return Container();
    } else {
      double widthOfScreen = MediaQuery.of(context).size.width;
      GeoPoint gp = itemCopy.location['geopoint'];
      double lat = gp.latitude;
      double long = gp.longitude;

      return Container(
        padding: EdgeInsets.only(top: 10.0),
        decoration: BoxDecoration(
            //border: Border(top: BorderSide(color: Colors.black), bottom: BorderSide(color: Colors.black)),
            ),
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
          /*
          gestureRecognizers: <Factory<OneSequenceGestureRecognizer>>[
            Factory<OneSequenceGestureRecognizer>(
                  () =>

              /// to disable dragging, use ScaleGestureRecognizer()
              /// to enable dragging, use EagerGestureRecognizer()
              EagerGestureRecognizer(),
              //ScaleGestureRecognizer(),
            ),
          ].toSet(),
          */
        ),
      );
    }
  }

  Widget showLocationButtons() {
    return Container(
      child: Row(
        children: <Widget>[
          Expanded(
            child: RaisedButton(
              color: primaryColor,
              textColor: Colors.white,
              child: itemCopy.location['geopoint'] == null
                  ? Text(
                      "Add Location",
                      style: TextStyle(fontFamily: 'Quicksand'),
                    )
                  : Text("Edit Location",
                      style: TextStyle(
                        fontFamily: 'Quicksand',
                      )),
              onPressed: () {
                setState(() {
                  navToLocation();
                });
              },
            ),
          ),
          /*
          SizedBox(
            width: 15.0,
          ),
          Expanded(
            child: RaisedButton(
              color: primaryColor,
              textColor: Colors.white,
              child: Text(
                "Reset Location",
                textScaleFactor: 1.25,
                style: TextStyle(fontFamily: 'Quicksand'),
              ),
              onPressed:
                  itemCopy.location == null ? null : () => resetLocation(),
            ),
          ),*/
        ],
      ),
    );
  }

  Widget showCircularProgress() {
    return isLoading
        ? Container(
            child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: <Widget>[
                  Text(
                    'Loading...',
                    style: TextStyle(fontSize: 30),
                  ),
                  Container(
                    height: 20.0,
                  ),
                  Center(child: CircularProgressIndicator())
                ]),
          )
        : Container(
            height: 0.0,
            width: 0.0,
          );
  }

  void saveItem() async {
    // Trim spaces and capitlize first letter of item name
    itemCopy.name = (itemCopy.name.trim())[0].toUpperCase() +
        (itemCopy.name.trim()).substring(1);
    itemCopy.description = itemCopy.description.trim();

    List<String> searchKeyList = [];
    String name = itemCopy.name.toLowerCase();
    String description = itemCopy.description.toLowerCase();
    List<String> nameList = name.split(' ');
    List<String> descriptionList = description.split(' ');

    nameList.forEach((str) {
      searchKeyList.add(str.substring(0, 1));
    });

    descriptionList.forEach((str) {
      searchKeyList.add(str.substring(0, 1));
    });

    searchKeyList = searchKeyList.toSet().toList();
    searchKeyList.sort();
    searchKeyList.removeWhere((str) => !RegExp('[a-z]').hasMatch(str));

    GeoPoint gp = itemCopy.location['geopoint'];
    GeoFirePoint myLocation =
        geo.point(latitude: gp.latitude, longitude: gp.longitude);

    // new item
    if (!isEdit) {
      try {
        HttpsCallable callable = CloudFunctions.instance.getHttpsCallable(
          functionName: 'addItem',
        );

        final HttpsCallableResult result = await callable.call(
          <String, dynamic>{
            'status': itemCopy.isVisible,
            'creator': itemCopy.creator.documentID,
            'name': itemCopy.name,
            'description': itemCopy.description,
            'type': itemCopy.type,
            'condition': itemCopy.condition,
            'rating': 0,
            'numRatings': 0,
            'price': itemCopy.price,
            'images': [],
            'numImages': totalImagesCount,
            'geohash': myLocation.data['geohash'],
            'lat': gp.latitude,
            'long': gp.longitude,
            'searchKey': searchKeyList,
            'isVisible': true,
            'owner': {
              'name': firebaseUser.displayName,
              'avatar': firebaseUser.photoUrl,
            },
          },
        );

        final String returnedID = result.data;
        itemId = returnedID;

        String done;

        if (imageAssets.length > 0) {
          done = await uploadImages(returnedID);
        }

        if (done != null) {
          Firestore.instance
              .collection('items')
              .document(returnedID)
              .get()
              .then((DocumentSnapshot ds) {
            Navigator.popAndPushNamed(
              context,
              ItemDetail.routeName,
              arguments: ItemDetailArgs(
                ds,
                context,
              ),
            );
          });
        }
      } on CloudFunctionsException catch (e) {
        Fluttertoast.showToast(msg: '${e.message}');

        setState(() {
          isLoading = false;
        });
      } catch (e) {
        Fluttertoast.showToast(msg: '${e}');

        setState(() {
          isLoading = false;
        });
      }
    }

    // update item aka item already exists
    else {
      try {
        HttpsCallable callable = CloudFunctions.instance.getHttpsCallable(
          functionName: 'updateItem',
        );

        final HttpsCallableResult result = await callable.call(
          <String, dynamic>{
            'itemId': itemId,
            'name': itemCopy.name,
            'description': itemCopy.description,
            'type': itemCopy.type,
            'condition': itemCopy.condition,
            'price': itemCopy.price,
            'numImages': totalImagesCount,
            'geohash': myLocation.data['geohash'],
            'lat': gp.latitude,
            'long': gp.longitude,
            'searchKey': searchKeyList,
          },
        );

        if (result != null) {
          Fluttertoast.showToast(msg: '${result.data}');

          if (imageAssets.length == 0) {
            Navigator.of(context).pop(itemCopy);
          } else {
            String done;

            if (imageAssets.length > 0) {
              done = await uploadImages(itemId);
            }

            if (done != null) {
              Navigator.of(context).pop(itemCopy);
            }
          }
        }
      } on CloudFunctionsException catch (e) {
        Fluttertoast.showToast(msg: '${e.message}');

        setState(() {
          isLoading = false;
        });
      } catch (e) {
        Fluttertoast.showToast(msg: '${e}');

        setState(() {
          isLoading = false;
        });
      }
    }
  }

  Future<void> loadAssets() async {
    List<Asset> resultList = List<Asset>();

    try {
      resultList = await MultiImagePicker.pickImages(
        maxImages: 8 - totalImagesCount,
        enableCamera: true,
      );
    } on PlatformException catch (e) {}

    if (!mounted) {
      return;
    }

    setState(() {
      imageAssets.addAll(resultList);
      totalImagesCount = itemCopy.numImages + imageAssets.length;
      imageButton = false;
    });
  }

  Future<void> deleteAssets() async {
    setState(() {
      for (int i = 0; i < itemCopy.numImages; i++) {
        FirebaseStorage.instance
            .ref()
            .child('/items/${itemId}/$i.jpg')
            .delete();
      }

      imageAssets = List<Asset>();
      itemCopy.numImages = 0;
      itemCopy.images = List();
      imageButton = true;

      if (isEdit) {
        Firestore.instance
            .collection('items')
            .document(itemId)
            .updateData({'images': List()});

        Firestore.instance
            .collection('items')
            .document(itemId)
            .updateData({'numImages': 0});

        widget.item.numImages = itemCopy.numImages;
        widget.item.images = itemCopy.images;
      }
    });
  }

  // fileName is the id of the item
  Future<String> uploadImages(String fileName) async {
    String done;
    String result;

    for (var i = 0; i < imageAssets.length; i++) {
      if (i == imageAssets.length - 1) {
        done = await saveImage(
            imageAssets[i], fileName, i + itemCopy.images.length);
        result = done;
      } else {
        result = await saveImage(
            imageAssets[i], fileName, i + itemCopy.images.length);
      }

      imageURLs.add(result);
    }

    Firestore.instance
        .collection('items')
        .document(itemId)
        .updateData({'images': imageURLs});

    return done;
  }

  Future<List<int>> compressList(List<int> list) async {
    var result = await FlutterImageCompress.compressWithList(
      list,
      minHeight: 1000,
      minWidth: 1080,
      quality: 95,
    );

    return result;
  }

  Future<String> saveImage(Asset asset, String fileName, int index) async {
    ByteData byteData = await asset.requestOriginal();
//    List<int> imageData = byteData.buffer.asUint8List();
    var imageList = byteData.buffer.asUint8List().toList();
    List<int> ret = await compressList(imageList);
    Uint8List imageData = Uint8List.fromList(ret);
    debugPrint('========= ${imageData.runtimeType}');

    StorageReference ref =
        FirebaseStorage.instance.ref().child('/items/$fileName/$index.jpg');
    StorageUploadTask uploadTask =
        ref.putData(imageData, StorageMetadata(contentType: 'image/jpeg'));

    return await (await uploadTask.onComplete).ref.getDownloadURL();
  }

  void deleteImage(String fileName) async {
    FirebaseStorage.instance.ref().child(fileName).delete();
  }

  void navToLocation() async {
    GeoPoint returnLoc = await Navigator.push(context,
        MaterialPageRoute<GeoPoint>(builder: (BuildContext context) {
      return SelectLocation(itemCopy.location['geopoint']);
    }));

    if (returnLoc != null) {
      setState(() {
        itemCopy.location['geopoint'] = returnLoc;
        setCamera();
      });
    }
  }

  setCamera() async {
    GeoPoint gp = itemCopy.location['geopoint'];
    double lat = gp.latitude;
    double long = gp.longitude;

    LatLng newLoc = LatLng(lat, long);
    googleMapController?.animateCamera(CameraUpdate.newCameraPosition(
        new CameraPosition(target: newLoc, zoom: 11.5)));
  }

  void resetLocation() {
    setState(() {
      itemCopy.location['geopoint'] = null;
    });
  }

  Future<bool> onWillPop() async {
    if (widget.item.compare(itemCopy)) return true;

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

  Future<bool> deleteImagesWarning() async {
    /// if we are creating a new item
    if (!isEdit) {
      deleteAssets();
      return true;
    }

    final ThemeData theme = Theme.of(context);
    final TextStyle dialogTextStyle =
        theme.textTheme.subhead.copyWith(color: theme.textTheme.caption.color);

    return await showDialog<bool>(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: Text('Warning!'),
              content: Text(
                'You are currently editing an item. '
                'Deleting its images will delete '
                'the images in the database, even '
                'if you don\'t press save',
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
                  child: const Text('Continue'),
                  onPressed: () {
                    deleteAssets();
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

  Future<bool> saveWarning() async {
    String message = 'Please add item name, description, images, and location';
    bool addPayment = false;

    if (currentUser.connectedAcctId == null) {
      message = 'To receive payment from rentals, you must put in your '
          'bank account info.\n\nNOTE: We do not use this to charge you';
      addPayment = true;
    } else if (itemCopy.location['geopoint'] != null &&
        totalImagesCount > 0 &&
        itemCopy.name.length > 0 &&
        itemCopy.description.length > 0) {
      setState(() {
        isLoading = true;
      });

      saveItem();
      return true;
    }

    final ThemeData theme = Theme.of(context);
    final TextStyle dialogTextStyle =
        theme.textTheme.subhead.copyWith(color: theme.textTheme.caption.color);

    return await showDialog<bool>(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: Text('Error!'),
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

                    if (addPayment) {
                      setState(() {
                        isLoading = true;
                      });
                      addConnectedAccount();
                    }
                  },
                ),
              ],
            );
          },
        ) ??
        false;
  }

  void addConnectedAccount() async {
    String name = currentUser.name;
    List<String> list = name.split(' ');
    String first = list[0];
    String last = '';

    if (list.length > 1) {
      last = list[1];
    }

    String firstName = first ?? '';
    String lastName = last ?? '';
    String redirectUri = '';

    redirectUri += 'share-app.web.app/';

    String key = '';

    var snap = await Firestore.instance
        .collection('keys')
        .document('stripe_onboarding')
        .get();

    if (snap != null && snap.exists) {
      key = snap['current'];
    }

    String url = 'https://connect.stripe.com/express/oauth/authorize?'
        'redirect_uri=$redirectUri'
        '&client_id=$key'
        '&stripe_user[country]=US'
        '&stripe_user[phone_number]=${currentUser.phoneNum}'
        '&stripe_user[business_type]=individual'
        '&stripe_user[email]=${currentUser.email}'
        '&stripe_user[first_name]=$firstName'
        '&stripe_user[last_name]=$lastName'
        '&stripe_user[product_description]=ShareApp';

    if (await canLaunch(url)) {
      await launch(url);
    }
  }

  Future<bool> deleteItemDialog() async {
    return await showDialog<bool>(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: Text('Delete item?'),
              content: Text('${itemCopy.name}'),
              actions: <Widget>[
                FlatButton(
                  child: const Text('No'),
                  onPressed: () {
                    Navigator.of(context).pop(
                        false); // Pops the confirmation dialog but not the page.
                  },
                ),
                FlatButton(
                  child: const Text('Yes'),
                  onPressed: () {
                    deleteItem();
                    Navigator.of(context).pop(false);

                    // Pops the confirmation dialog but not the page.
                  },
                ),
              ],
            );
          },
        ) ??
        false;
  }

  Future<bool> showUserLocationError() async {
    final ThemeData theme = Theme.of(context);
    final TextStyle dialogTextStyle =
        theme.textTheme.subhead.copyWith(color: theme.textTheme.caption.color);

    return await showDialog<bool>(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: Text('Error'),
              content: Text(
                'Problem with getting your current location',
                style: dialogTextStyle,
              ),
              actions: <Widget>[
                FlatButton(
                  child: const Text('Close'),
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

  void deleteItem() async {
    setState(() {
      isLoading = true;
    });

    Firestore.instance
        .collection('items')
        .document(itemId)
        .delete()
        .then((_) => Navigator.popUntil(
              context,
              ModalRoute.withName('/'),
            ));
  }
}
