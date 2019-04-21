import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shareapp/models/item.dart';
import 'package:shareapp/pages/select_location.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:multi_image_picker/multi_image_picker.dart';

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

  bool isUploading = false;
  String imageFileName;

  String appBarText = "Edit"; // Either 'Edit' or 'Add'. Prepended to " Item"
  String addButton = "Edit"; // 'Edit' if edit, 'Add' if adding
  String updateButton = "Save"; // 'Save' if edit, 'Add' if adding
  bool isEdit = true; // true if on editing mode, false if on adding mode

  TextEditingController nameController = TextEditingController();
  TextEditingController descriptionController = TextEditingController();
  TextEditingController priceController = TextEditingController();

  List<Asset> imageAssets = List<Asset>();
  bool imageButton = false;

  List imageURLs = List();

  TextStyle textStyle;
  TextStyle inputTextStyle;

  List<DropdownMenuItem<String>> dropDownItemType;
  List<DropdownMenuItem<String>> dropDownItemCondition;

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

    // new item
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
      'tool',
      'leisure',
      'home',
      'other',
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
      'lightly used',
      'good',
      'fair',
      'has character',
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
      appBar: AppBar(
        title: Text(appBarText + ' Item'),
        actions: <Widget>[
          FlatButton(
            child: Text('SAVE',
                textScaleFactor: 1.05,
                style: theme.textTheme.body2.copyWith(color: Colors.white)),
            onPressed: () {
              saveWarning();
              //Navigator.pop(context, DismissDialogAction.save);
            },
          ),
        ],
      ),
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
    );
  }

  Widget showBody() {
    return Form(
      key: formKey,
      onWillPop: onWillPop,
      child: ListView(
        padding:
            EdgeInsets.only(top: 10.0, bottom: 10.0, left: 18.0, right: 18.0),
        children: <Widget>[
          //showItemCreator(),
          Column(
            children: <Widget>[
              showTypeSelector(),
              showConditionSelector(),
            ],
          ),
          showNameEditor(),
          showDescriptionEditor(),
          showPriceEditor(),
          showImageCount(),
          showImageButtons(),
          showSelectedLocation(),
          showLocationButtons(),
        ].map<Widget>((Widget child) {
          return Container(
            padding: const EdgeInsets.symmetric(vertical: 11),
            child: child,
          );
        }).toList(),
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
      child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: <Widget>[
            Text(
              'Select Item Type:',
              textScaleFactor: 1.15,
            ),
            DropdownButton<String>(
              value: itemCopy.type,
              hint: Text('Choose'),
              onChanged: (String newValue) {
                setState(() {
                  itemCopy.type = newValue;
                });
              },
              items: dropDownItemType,
            ),
          ]),
    );
  }

  Widget showConditionSelector() {
    return Container(
      padding: EdgeInsets.only(left: 15.0, right: 15.0),
      child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: <Widget>[
            Text(
              'Select Item Condition:',
              textScaleFactor: 1.15,
            ),
            DropdownButton<String>(
              value: itemCopy.condition,
              hint: Text('Choose'),
              onChanged: (String newValue) {
                setState(() {
                  itemCopy.condition = newValue;
                });
              },
              items: dropDownItemCondition,
            ),
          ]),
    );
  }

  Widget showNameEditor() {
    return Container(
      //padding: EdgeInsets.only(left: 5.0, right: 5.0),
      child: TextField(
        controller: nameController,
        style: textStyle,
        onChanged: (value) {
          itemCopy.name = nameController.text;
        },
        decoration: InputDecoration(
          labelText: 'Name',
          filled: true,
          //border: OutlineInputBorder(borderRadius: BorderRadius.circular(5.0)),
        ),
      ),
    );
  }

  Widget showDescriptionEditor() {
    return Container(
      child: TextField(
        keyboardType: TextInputType.multiline,
        maxLines: null,
        controller: descriptionController,
        style: textStyle,
        onChanged: (value) {
          itemCopy.description = descriptionController.text;
        },
        decoration: InputDecoration(
          labelText: 'Description',
          filled: true,
          //border: OutlineInputBorder(borderRadius: BorderRadius.circular(5.0)),
        ),
      ),
    );
  }

  Widget showPriceEditor() {
    return Container(
      child: TextField(
        keyboardType: TextInputType.number,
        controller: priceController,
        style: textStyle,
        onChanged: (value) {
          itemCopy.price = int.parse(priceController.text);
        },
        decoration: InputDecoration(
          labelText: 'Price',
          hintText: 'Hourly rate',
          filled: true,
        ),
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
              shape: new RoundedRectangleBorder(
                  borderRadius: new BorderRadius.circular(5.0)),
              color: Colors.red,
              textColor: Colors.white,
              child: Text(
                "Add Images",
                //addButton + " Images",
                textScaleFactor: 1.25,
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
                "Delete Images",
                textScaleFactor: 1.25,
              ),
              onPressed: imageButton
                  ? null
                  : () {
                      deleteImagesWarning();
                    },
            ),
          ),
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
    if (isUploading) {
      //return Center(child: CircularProgressIndicator());

      return Container(
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
      );
    }
    return Container(
      height: 0.0,
      width: 0.0,
    );
  }

  void saveItem() async {
    /// use final FormState form = _formKey.currentState;
    /// links:
    /// https://codingwithjoe.com/building-forms-with-flutter/
    /// https://flutter.dev/docs/cookbook/forms/retrieve-input

    setState(() {
      isUploading = true;

      //widget.item = itemCopy;
      /*
      List list = List();
      list.add('https://bit.ly/2I11dot');
      widget.item.images = list;
      */

      /*
      widget.item.name = itemCopy.name;
      widget.item.description = itemCopy.description;
      widget.item.price = itemCopy.price;
      widget.item.type = itemCopy.type;
      widget.item.condition = itemCopy.condition;
      widget.item.location = itemCopy.location;
      widget.item.compare(itemCopy);
*/
    });

    ///if (_formKey.currentState.validate())

    //goToLastScreen();

    // new item
    if (itemCopy.id == null) {
      final DocumentReference documentReference =
          await Firestore.instance.collection("items").add({
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
    //await MultiImagePicker.deleteImages(assets: images);
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

  /// fileName is the id of the item
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
      });
    }
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
