import 'package:flutter/material.dart';
import 'package:shareapp/item.dart';
import 'package:shareapp/item_edit.dart';
import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:path/path.dart' as path;

class ItemDetail extends StatefulWidget {
  Item item;

  ItemDetail(this.item);

  @override
  State<StatefulWidget> createState() {
    return ItemDetailState(this.item);
  }
}

class ItemDetailState extends State<ItemDetail> {
  Item item;
  String appBarTitle = "Item Details";
  String strType;
  File image;
  String url;

  ItemDetailState(this.item);

  @override
  Widget build(BuildContext context) {
    TextStyle textStyle = Theme
        .of(context)
        .textTheme
        .title;

    if (item.type) {
      strType = "Tool";
    } else {
      strType = "Leisure";
    }

    getImage();

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
                // edit item button
                IconButton(
                  icon: Icon(Icons.edit),
                  tooltip: 'Edit Item',
                  onPressed: () {
                    navigateToEdit(item);
                    debugPrint('edit button was pressed');
                  },
                ),
              ]),
          body: Padding(
            padding: EdgeInsets.only(top: 15.0, left: 10.0, right: 10.0),
            child: ListView(
              children: <Widget>[
                // first element
                Padding(
                  padding: EdgeInsets.only(
                      top: 15.0, bottom: 15.0, left: 10.0, right: 10.0),
                  child: SizedBox(
                      height: 50.0,
                      child: Container(
                        alignment: AlignmentDirectional.center,
                        color: Color(0x00000000),
                        child: Text(
                          item.name,
                          style: TextStyle(color: Colors.black, fontSize: 24.0),
                          textAlign: TextAlign.center,
                        ),
                      )
                  ),
                ),

                // second element
                Padding(
                  padding: EdgeInsets.only(
                      top: 15.0, bottom: 15.0, left: 10.0, right: 10.0),
                  child: SizedBox(
                      height: 50.0,
                      child: Container(
                        alignment: AlignmentDirectional.center,
                        color: Color(0x00000000),
                        child: Text(
                          item.description,
                          style: TextStyle(color: Colors.black, fontSize: 24.0),
                          textAlign: TextAlign.center,
                        ),
                      )
                  ),
                ),

                // third element
                Padding(
                  padding: EdgeInsets.only(
                      top: 15.0, bottom: 15.0, left: 10.0, right: 10.0),
                  child: SizedBox(
                      height: 50.0,
                      child: Container(
                        alignment: AlignmentDirectional.center,
                        color: Color(0x00000000),
                        child: Text(
                          item.price.toString(),
                          style: TextStyle(color: Colors.black, fontSize: 24.0),
                          textAlign: TextAlign.center,
                        ),
                      )
                  ),
                ),

                // fourth element
                Padding(
                  padding: EdgeInsets.only(
                      top: 15.0, bottom: 15.0, left: 10.0, right: 10.0),
                  child: SizedBox(
                      height: 50.0,
                      child: Container(
                        alignment: AlignmentDirectional.center,
                        color: Color(0x00000000),
                        child: Text(
                          strType,
                          style: TextStyle(color: Colors.black, fontSize: 24.0),
                          textAlign: TextAlign.center,
                        ),
                      )
                  ),
                ),

                // fifth element
                Padding(
                  padding: EdgeInsets.only(
                      top: 15.0, bottom: 15.0, left: 10.0, right: 10.0),
                  child: Container(
                    child:
                    image == null ? Text('Select an image') : Image.network(url),
                    //Image.file(image, height: 300.0, width: 300.0),
                  ),
                ),
              ],
            ),
          ),
        ));
  }

  void navigateToEdit(Item item) async {
    debugPrint('navToEdit function called');

    bool result = await Navigator.push(context, MaterialPageRoute(builder: (context) {
      return ItemEdit(item);
    }));
    /*
    Navigator.push(context, MaterialPageRoute(builder: (context) {
      return ItemEdit(item, title);
    }));*/
  }

  void getImage() async {
    StorageReference ref = FirebaseStorage.instance.ref().child(item.id);

    var url = await ref.getDownloadURL();
    setState(() {
      this.url = url;

      image = Image.network(url) as File;
    });
  }

  void goToLastScreen() {
    Navigator.pop(context);
  }
}
