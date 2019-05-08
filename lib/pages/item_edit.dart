import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:multi_image_picker/multi_image_picker.dart';
import 'package:shareapp/extras/helpers.dart';
import 'package:shareapp/models/item.dart';
import 'package:shareapp/services/select_location.dart';

enum DismissDialogAction {
  cancel,
  discard,
  save,
}

class ItemEdit extends StatefulWidget {
  static const routeName = '/itemEdit';
  final Item item;

  ItemEdit({Key key, this.item}) : super(key: key);

  @override
  State<StatefulWidget> createState() {
    return ItemEditState();
  }
}

/// We initially assume we are in editing mode
class ItemEditState extends State<ItemEdit> {
  final GlobalKey<FormState> formKey = new GlobalKey<FormState>();

  String appBarText = "Edit"; // Either 'Edit' or 'Add'. Prepended to " Item"
  String addButton = "Edit"; // 'Edit' if edit, 'Add' if adding
  String updateButton = "Save"; // 'Save' if edit, 'Add' if adding

  List<Asset> imageAssets = List<Asset>();
  List imageURLs = List();
  String imageFileName;
  bool imageButton = false;
  bool isEdit = true; // true if on editing mode, false if on adding mode
  bool isUploading = false;

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

  @override
  void initState() {
    super.initState();

    itemCopy = Item.copy(widget.item);
  }

  @override
  Widget build(BuildContext context) {
    theme = Theme.of(context);
    textStyle =
        Theme.of(context).textTheme.headline.merge(TextStyle(fontSize: 20));
    inputTextStyle = Theme.of(context).textTheme.subtitle;

    nameController.text = itemCopy.name;
    descriptionController.text = itemCopy.description;
    priceController.text = itemCopy.price.toString();

    /// new item
    if (itemCopy.id == null) {
      isEdit = false;
      appBarText = "Add";
      addButton = "Add";
      updateButton = "Add";
    }

    if (itemCopy.numImages == 0) {
      imageButton = true;
    }

    const itemType = <String>[
      'Tool',
      'Leisure',
      'Home',
      'Other',
    ];
    dropDownItemType = itemType
        .map(
          (String value) => DropdownMenuItem<String>(
                value: value,
                child: Text(value),
              ),
        )
        .toList();

    const itemCondition = <String>[
      'Lightly Used',
      'Good',
      'Fair',
      'Has Character',
    ];
    dropDownItemCondition = itemCondition
        .map(
          (String value) => DropdownMenuItem<String>(
                value: value,
                child: Text(value),
              ),
        )
        .toList();

    return Scaffold(
      resizeToAvoidBottomPadding: true,
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
      floatingActionButton: RaisedButton(
        color: Color(0xff007f6e),
        child: Text('Next ＞',
            style: TextStyle(color: Colors.white, fontFamily: 'Quicksand')),
        onPressed: () {
          saveWarning();
        },
      ),
    );
  }

  Widget showBody() {
    double height = MediaQuery.of(context).size.height;
    double width = MediaQuery.of(context).size.width;

    return Form(
      key: formKey,
      onWillPop: onWillPop,
      child: ListView(
          shrinkWrap: true,
          padding: EdgeInsets.only(
              top: height / 15, bottom: 10.0, left: 18.0, right: 18.0),
          children: <Widget>[
            backButton(context),
            Padding(
              padding: const EdgeInsets.only(top: 60, bottom: 60.0),
              child: Center(child: Text("[ add image thumbnails here ]")),
            ),
            showImageButtons(),
            divider(),
            reusableCategory("DETAILS"),
            reusableTextEntry("What are you selling? (required)", true,
                nameController, 'name'),
            reusableTextEntry("Describe it... (required)", true,
                descriptionController, 'description'),
            divider(),
            reusableCategory("SPECIFICS"),
            showTypeSelector(),
            showConditionSelector(),
            divider(),
            reusableCategory("PRICE"),
            reusableTextEntry(
                "Price", true, priceController, 'price', TextInputType.number),
            divider(),
            reusableCategory("LOCATION"),
            showItemLocation(),
            showLocationButtons(),
          ]),
    );
  }

  Widget reusableTextEntry(placeholder, required, controller, saveTo,
      [keyboard = TextInputType.text]) {
    return Container(
      child: TextField(
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
          ),
          labelText: placeholder,
          //border: OutlineInputBorder(borderRadius: BorderRadius.circular(5.0)),
        ),
      ),
    );
  }

  Widget reusableCategory(text) {
    return Container(
        alignment: Alignment.centerLeft,
        child: Text(text,
            style: TextStyle(fontSize: 11.0, fontWeight: FontWeight.w100)));
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
        hint: Text('Category'),
        onChanged: (String newValue) {
          setState(() {
            itemCopy.type = newValue;
          });
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
        hint: Text('Condition'),
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
    return Container(
      child: Row(
        children: <Widget>[
          Expanded(
            child: RaisedButton(
              color: Colors.white,
              textColor: Colors.black,
              child: Text(
                "Add More Photos",
              ),
              onPressed: imageButton
                  ? () {
                      setState(() {
                        loadAssets();
                      });
                    }
                  : null,
            ),
          ),
          /*
          Expanded(
            child: RaisedButton(
              shape: new RoundedRectangleBorder(
                  borderRadius: new BorderRadius.circular(5.0)),
              color: Colors.red,
              textColor: Colors.white,
              child: Text(
                "Delete Images",
                textScaleFactor: 1.25,
              ),
              onPressed: imageButton
                  ? null
                  : () {
                      deleteImagesWarning();
                    },
            ),
          ),*/
        ],
      ),
    );
  }

  Widget showSelectedLocation() {
    return Container(
      child: itemCopy.location != null
          ? Text(
              "Selected location: ${itemCopy.location.latitude}, ${itemCopy.location.longitude}",
              style: TextStyle(fontSize: 16),
            )
          : Text(
              "No location yet",
              style: TextStyle(fontSize: 16),
            ),
    );
  }

  Widget showItemLocation() {
    if (itemCopy.location == null) {
      return Container();

      /// @rohith change this to whatever you want
    }

    double widthOfScreen = MediaQuery.of(context).size.width;
    GeoPoint gp = itemCopy.location;
    double lat = gp.latitude;
    double long = gp.longitude;

    return Padding(
      padding: const EdgeInsets.only(
          left: 20.0, right: 20.0, top: 20.0, bottom: 20.0),
      child: Center(
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
        ),
      ),
    );
  }

  Widget showLocationButtons() {
    return Container(
      child: Row(
        children: <Widget>[
          Expanded(
            child: RaisedButton(
              shape: new RoundedRectangleBorder(
                  borderRadius: new BorderRadius.circular(5.0)),
              color: Colors.red,
              textColor: Colors.white,
              child: itemCopy.location == null
                  ? Text(
                      "Add Location",
                      textScaleFactor: 1.25,
                    )
                  : Text(
                      "Edit Location",
                      textScaleFactor: 1.25,
                    ),
              onPressed: () {
                setState(() {
                  navToLocation();
                });
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
              color: Colors.red,
              textColor: Colors.white,
              child: Text(
                "Reset Location",
                textScaleFactor: 1.25,
              ),
              onPressed: itemCopy.location == null
                  ? null
                  : () {
                      resetLocation();
                    },
            ),
          ),
        ],
      ),
    );
  }

  Widget showCircularProgress() {
    return isUploading
        ? Container(
            child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: <Widget>[
                  Text(
                    "Uploading...",
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
    setState(() {
      isUploading = true;
    });

    // new item
    if (itemCopy.id == null) {
      final DocumentReference documentReference =
          await Firestore.instance.collection("items").add({
        'id': null,
        'status': itemCopy.status,
        'creator': itemCopy.creator,
        'name': itemCopy.name,
        'description': itemCopy.description,
        'type': itemCopy.type,
        'condition': itemCopy.condition,
        'price': itemCopy.price,
        'numImages': itemCopy.numImages,
        'location': itemCopy.location,
        'rental': itemCopy.rental,
      });

      // update the newly added item with the updated doc id
      final String returnedID = documentReference.documentID;

      itemCopy.id = returnedID;

      Firestore.instance
          .collection('items')
          .document(returnedID)
          .updateData({'id': returnedID});

      Firestore.instance
          .collection('users')
          .document(widget.item.creator.documentID)
          .updateData({
        'items': FieldValue.arrayUnion([documentReference])
      });

      if (imageAssets.length == 0) {
        Firestore.instance
            .collection('items')
            .document(returnedID)
            .updateData({'images': List()});
        Navigator.of(context).pop(true);
      } else {
        String done;

        if (imageAssets.length > 0) {
          done = await uploadImages(returnedID);
        }

        if (done != null) {
          Navigator.of(context).pop(true);
        }
      }
    }

    // update item aka item already exists
    else {
      Firestore.instance.collection('items').document(itemCopy.id).updateData({
        'name': itemCopy.name,
        'description': itemCopy.description,
        'type': itemCopy.type,
        'condition': itemCopy.condition,
        'price': itemCopy.price,
        'numImages': itemCopy.numImages,
        'location': itemCopy.location,
      });

      if (imageAssets.length == 0) {
        Navigator.of(context).pop(itemCopy);
      } else {
        String done;

        if (imageAssets.length > 0) {
          done = await uploadImages(itemCopy.id);
        }

        if (done != null) {
          setState(() {
            if (isEdit) widget.item.images = imageURLs;
          });
          Navigator.of(context).pop(itemCopy);
        }
      }
    }
  }

  Future<void> loadAssets() async {
    setState(() {
      imageAssets = List<Asset>();
    });

    List<Asset> resultList = List<Asset>();

    try {
      resultList = await MultiImagePicker.pickImages(
        maxImages: 10,
        enableCamera: false,
        //options: CupertinoOptions(takePhotoIcon: "chat"),
      );
    } on PlatformException catch (e) {}

    // If the widget was removed from the tree while the asynchronous platform
    // message was in flight, we want to discard the reply rather than calling
    // setState to update our non-existent appearance.
    if (!mounted) return;

    setState(() {
      imageAssets = resultList;
      itemCopy.numImages = imageAssets.length;
      imageButton = false;
      //_error = error;
    });
  }

  Future<void> deleteAssets() async {
    setState(() {
      for (int i = 0; i < itemCopy.numImages; i++) {
        FirebaseStorage.instance.ref().child('${itemCopy.id}/$i').delete();
      }

      imageAssets = List<Asset>();
      itemCopy.numImages = 0;
      itemCopy.images = List();
      imageButton = true;

      if (isEdit) {
        Firestore.instance
            .collection('items')
            .document(itemCopy.id)
            .updateData({'images': List()});

        Firestore.instance
            .collection('items')
            .document(itemCopy.id)
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
        done = await saveImage(imageAssets[i], fileName, i);
        result = done;
      } else {
        result = await saveImage(imageAssets[i], fileName, i);
      }

      imageURLs.add(result);
      Firestore.instance
          .collection('items')
          .document(itemCopy.id)
          .updateData({'images': imageURLs});
    }

    return done;
  }

  Future<String> saveImage(Asset asset, String fileName, int index) async {
    ByteData byteData = await asset.requestOriginal();
    List<int> imageData = byteData.buffer.asUint8List();
    StorageReference ref =
        FirebaseStorage.instance.ref().child('$fileName/$index');
    StorageUploadTask uploadTask = ref.putData(imageData);

    return await (await uploadTask.onComplete).ref.getDownloadURL();
  }

  void deleteImage(String fileName) async {
    FirebaseStorage.instance.ref().child(fileName).delete();
  }

  void navToLocation() async {
    GeoPoint returnLoc = await Navigator.push(context,
        MaterialPageRoute<GeoPoint>(builder: (BuildContext context) {
      return SelectLocation(itemCopy.location);
    }));

    if (returnLoc != null) {
      setState(() {
        itemCopy.location = returnLoc;
        setCamera();
      });
    }
  }

  setCamera() async {
    GeoPoint gp = itemCopy.location;
    double lat = gp.latitude;
    double long = gp.longitude;

    LatLng newLoc = LatLng(lat, long);
    googleMapController.animateCamera(CameraUpdate.newCameraPosition(
        new CameraPosition(target: newLoc, zoom: 11.5)));
  }

  void resetLocation() {
    setState(() {
      itemCopy.location = null;
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
    if (itemCopy.location != null && itemCopy.numImages > 0) {
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
                'Please add images and location',
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
}
