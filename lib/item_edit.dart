import 'package:flutter/material.dart';
import 'package:shareapp/item.dart';
import 'package:shareapp/image_detail.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:path/path.dart' as path;
import 'package:firebase_core/firebase_core.dart';
import 'dart:io';
import 'dart:async';
import 'package:multi_image_picker/multi_image_picker.dart';
import 'package:flutter/services.dart';
import 'package:shareapp/asset_view.dart';
//import 'package:multi_image_picker/multi_image_picker.dart';

class ItemEdit extends StatefulWidget {
  Item item;

  ItemEdit(this.item);

  @override
  State<StatefulWidget> createState() {
    //appBarTitle += ' Item';
    return ItemEditState(this.item);
  }
}

enum ItemType { tool, leisure }

/// We initially assume we are in editing mode
class ItemEditState extends State<ItemEdit> {
  Item item;
  File image;
  String imageFileName;

  //List images;
  String appBarText = "Edit"; // Either 'Edit' or 'Add'. Prepended to " Item"
  String updateButton = "Update"; // 'Update' if edit, 'Add' if adding
  bool isEdit = true; // true if on editing mode, false if on adding mode

  TextEditingController nameController = TextEditingController();
  TextEditingController descriptionController = TextEditingController();
  TextEditingController priceController = TextEditingController();
  BuildContext scaffoldContext;

  List<Asset> images = List<Asset>();
  String _error = 'No Error Dectected';

  ItemType currSelected;

  // = ItemType.tool;

  ItemEditState(this.item);

  @override
  Widget build(BuildContext context) {
    TextStyle textStyle = Theme.of(context).textTheme.title;

    nameController.text = item.name;
    descriptionController.text = item.description;
    priceController.text = item.price.toString();

    if (item.id == null) {
      isEdit = false;
      appBarText = "Add";
      updateButton = "Add";
    }

    if (item.type) {
      currSelected = ItemType.tool;
    } else {
      currSelected = ItemType.leisure;
    }

    return WillPopScope(
        onWillPop: () {
          // when user presses back button
          goToLastScreen();
        },
        child: Scaffold(
          appBar: AppBar(
            title: Text(appBarText + ' Item'),
            leading: IconButton(
              icon: Icon(Icons.arrow_back),
              onPressed: () {
                goToLastScreen();
              },
            ),
          ),
          body: Padding(
            padding: EdgeInsets.only(top: 15.0, left: 10.0, right: 10.0),
            child: ListView(
              children: <Widget>[
                // first element
                Padding(
                  padding: EdgeInsets.only(
                      top: 15.0, bottom: 15.0, left: 10.0, right: 10.0),
                  child: Row(
                    children: <Widget>[
                      Expanded(
                        child: RadioListTile<ItemType>(
                          title: const Text('Tool'),
                          value: ItemType.tool,
                          groupValue: currSelected,
                          onChanged: (ItemType value) {
                            setState(() {
                              currSelected = value;
                              item.type = true;
                            });
                          },
                        ),
                      ),
                      Container(
                        width: 15.0,
                      ),
                      Expanded(
                        child: RadioListTile<ItemType>(
                          title: const Text('Leisure'),
                          value: ItemType.leisure,
                          groupValue: currSelected,
                          onChanged: (ItemType value) {
                            setState(() {
                              currSelected = value;
                              item.type = false;
                            });
                          },
                        ),
                      ),
                    ],
                  ),
                ),

                // second element
                Padding(
                  padding: EdgeInsets.only(
                      top: 15.0, bottom: 15.0, left: 10.0, right: 10.0),
                  child: TextField(
                    controller: nameController,
                    style: textStyle,
                    onChanged: (value) {
                      updateName();
                      debugPrint('Something changed in name text field');
                    },
                    decoration: InputDecoration(
                        labelText: 'Name',
                        labelStyle: textStyle,
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(5.0))),
                  ),
                ),

                // third element
                Padding(
                  padding: EdgeInsets.only(
                      top: 15.0, bottom: 15.0, left: 10.0, right: 10.0),
                  child: TextField(
                    controller: descriptionController,
                    style: textStyle,
                    onChanged: (value) {
                      updateDescription();
                      debugPrint('Something changed in description text field');
                    },
                    decoration: InputDecoration(
                        labelText: 'Description',
                        labelStyle: textStyle,
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(5.0))),
                  ),
                ),

                // fourth element - price controller
                Padding(
                  padding: EdgeInsets.only(
                      top: 15.0, bottom: 15.0, left: 10.0, right: 10.0),
                  child: TextField(
                    keyboardType: TextInputType.number,
                    controller: priceController,
                    style: textStyle,
                    onChanged: (value) {
                      updatePrice();
                      debugPrint('Something changed in price text field');
                    },
                    decoration: InputDecoration(
                        labelText: 'Price',
                        labelStyle: textStyle,
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(5.0))),
                  ),
                ),

                // fifth element, add image button
                Padding(
                  padding: EdgeInsets.only(
                      top: 15.0, bottom: 15.0, left: 10.0, right: 10.0),
                  child: Row(
                    children: <Widget>[
                      Expanded(
                        child: RaisedButton(
                          shape: new RoundedRectangleBorder(
                              borderRadius: new BorderRadius.circular(5.0)),
                          color: Colors.blue,
                          textColor: Colors.white,
                          child: Text(
                            updateButton + " Image",
                            textScaleFactor: 1.25,
                          ),
                          onPressed: () {
                            setState(() {
                              loadAssets();
                              //getImage();
                              //debugPrint("Save button clicked");
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
                          color: Colors.blue,
                          textColor: Colors.white,
                          child: Text(
                            "Delete Images",
                            textScaleFactor: 1.25,
                          ),
                          onPressed: () {
                            setState(() {
                              //debugPrint("Nav to image button pressed");
                              deleteAssets();
                            });
                          },
                        ),
                      ),
                    ],
                  ),
                ),

                // sixth element: selected picture
                Padding(
                    padding: EdgeInsets.only(
                        top: 15.0, bottom: 15.0, left: 10.0, right: 10.0),
                    child: Text("Num images selected: ${images.length}")),

                // seventh element, save and delete buttons
                Padding(
                  padding: EdgeInsets.only(
                      top: 15.0, bottom: 15.0, left: 10.0, right: 10.0),
                  child: Row(
                    children: <Widget>[
                      Expanded(
                        child: RaisedButton(
                          shape: new RoundedRectangleBorder(
                              borderRadius: new BorderRadius.circular(5.0)),
                          color: Colors.red,
                          textColor: Colors.white,
                          child: Text(
                            //'Save',
                            updateButton,
                            textScaleFactor: 1.5,
                          ),
                          onPressed: () {
                            setState(() {
                              saveItem();
                              //debugPrint("Save button clicked");
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
                            'Delete',
                            textScaleFactor: 1.5,
                          ),
                          onPressed: () {
                            setState(() {
                              deleteItem();
                              debugPrint("Delete button clicked");
                            });
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ));
  }

  void deleteItem() {
    goToLastScreen();

    if (item.id != null) {
      Firestore.instance.collection('items').document(item.id).delete();
    }
  }

  void saveItem() async {
    goToLastScreen();

    // new item
    if (item.id == null) {
      // insert your data ({ 'group_name'...) instead of `data` here
      final DocumentReference documentReference =
          await Firestore.instance.collection("items").add({
        'description': item.description,
        'id': 'temp',
        'name': item.name,
        'price': item.price,
        'type': item.type
      });

      // update the newly added item with the updated doc id
      final String returnedID = documentReference.documentID;

      Firestore.instance
          .collection('items')
          .document(returnedID)
          .updateData({'id': returnedID});

      uploadImage(returnedID);
    }

    // update item aka item already exists
    else {
      Firestore.instance.collection('items').document(item.id).updateData({
        'name': item.name,
        'description': item.description,
        'type': item.type
      });
    }
  }

  void updateName() {
    item.name = nameController.text;
  }

  void updateDescription() {
    item.description = descriptionController.text;
  }

  void updatePrice() {
    item.price = int.parse(priceController.text);
  }

  void updateType(bool newType) {
    item.type = newType;
  }

  Future<void> loadAssets() async {
    setState(() {
      images = List<Asset>();
    });

    List<Asset> resultList = List<Asset>();
    String error = 'No Error Dectected';

    try {
      resultList = await MultiImagePicker.pickImages(
        maxImages: 300,
        enableCamera: true,
        options: CupertinoOptions(takePhotoIcon: "chat"),
      );
    } on PlatformException catch (e) {
      error = e.message;
    }

    // If the widget was removed from the tree while the asynchronous platform
    // message was in flight, we want to discard the reply rather than calling
    // setState to update our non-existent appearance.
    if (!mounted) return;

    setState(() {
      images = resultList;
      _error = error;
    });
  }

  Widget buildBody(BuildContext ctxt, int index) {
    Asset asset = images[index];
    return AssetView(
      index,
      asset,
      key: UniqueKey(),
    );
  }

  Widget buildGridView() {
    if (images.length > 0) {
      return GridView.count(
        crossAxisCount: 3,
        children: List.generate(images.length, (index) {
          Asset asset = images[index];
          return AssetView(
            index,
            asset,
            key: UniqueKey(),
          );
        }),
      );
    }
  }

  Future<void> deleteAssets() async {
    //await MultiImagePicker.deleteImages(assets: images);
    setState(() {
      images = List<Asset>();
    });
  }

  void getImage() async {
    var newImage = await ImagePicker.pickImage(source: ImageSource.gallery);
    imageFileName = path.basename(newImage.path);

    setState(() {
      image = newImage;
    });
  }

  void uploadImage(String fileName) async {
    StorageReference storageRef =
        FirebaseStorage.instance.ref().child(fileName);
/*
    for(var i = 0; i < images.length; i++){
      Asset asset = images[i];

      storageRef.putFile(image);
      //StorageUploadTask task = storageRef.putFile(images[i]);
      
    }*/

    StorageUploadTask task = storageRef.putFile(image);

    /*
    String fileName = image.toString() + ".jpg";
    final ref = FirebaseStorage.instance.ref().child(fileName);

    ref.putFile(image);

    var url = await ref.getDownloadURL() as String;
    return url;*/
  }

  void deleteImage(String fileName) async {
    FirebaseStorage.instance.ref().child(fileName).delete();
  }

  void navigateToImageDetail(File file) async {
    debugPrint('navigateToImageDetail function called');

    bool result =
        await Navigator.push(context, MaterialPageRoute(builder: (context) {
      return ImageDetail(file);
    }));
    /*
    Navigator.push(context, MaterialPageRoute(builder: (context) {
      return ItemEdit(item, title);
    }));*/
  }

  void goToLastScreen() {
    Navigator.pop(context);
  }

  void showSnackBar(String item) {
    var message = SnackBar(
      content: Text("$item was pressed"),
      action: SnackBarAction(
          label: "Undo",
          onPressed: () {
            debugPrint('Performing dummy UNDO operation');
          }),
    );

    Scaffold.of(scaffoldContext).showSnackBar(message);
  }
}
