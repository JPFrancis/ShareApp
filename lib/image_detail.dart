import 'package:flutter/material.dart';
import 'package:shareapp/item.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';
import 'dart:async';

class ImageDetail extends StatefulWidget {
  File image;

  ImageDetail(this.image);

  @override
  State<StatefulWidget> createState() {
    //appBarTitle += ' Item';
    return ImageDetailState(this.image);
  }
}

class ImageDetailState extends State<ImageDetail> {
  File item;
  File image;
  List images;
  String appBarText = "Edit"; // Either 'Edit' or 'Add'. Prepended to " Item"
  String updateButton = "Update"; // 'Update' if edit, 'Add' if adding
  bool isEdit = true; // true if on editing mode, false if on adding mode

  // = ItemType.tool;

  ImageDetailState(this.image);

  @override
  Widget build(BuildContext context) {
    TextStyle textStyle = Theme
        .of(context)
        .textTheme
        .title;

    return WillPopScope(
        onWillPop: () {
          // when user presses back button
          goToLastScreen();
        },
        child: Scaffold(
          appBar: AppBar(
            title: Text("Image Detail"),
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
                Image.file(image, height: 300.0, width: 300.0),
              ],
            ),
          ),
        ));
  }

  void goToLastScreen() {
    Navigator.pop(context);
  }
}

/*

  Widget showImage() {
    return Container(
      child: Column(
        children: <Widget>[
          Image.file(image, height: 300.0, width: 300.0),
          RaisedButton(
            elevation: 7.0,
            child: Text('Upload'),
            textColor: Colors.white,
            color: Colors.blue,
            onPressed: () {
              final StorageReference firebaseStorageRef =
              FirebaseStorage.instance.ref().child('myimage.jpg');
              final StorageUploadTask task =
              firebaseStorageRef.putFile(image);
            },
          )
        ],
      ),
    );
  }
 */
