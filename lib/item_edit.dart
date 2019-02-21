import 'package:flutter/material.dart';
import 'package:shareapp/item.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

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

class ItemEditState extends State<ItemEdit> {
  Item item;
  //var itemVar = new Item();
  String editStatus = "Edit"; //

  TextEditingController nameController = TextEditingController();
  TextEditingController descriptionController = TextEditingController();

  ItemType currSelected;
  // = ItemType.tool;

  ItemEditState(this.item);

  @override
  Widget build(BuildContext context) {
    TextStyle textStyle = Theme.of(context).textTheme.title;
    String updateButton = "Save"; // 'Save' if edit, 'Add' if adding
    bool isEdit = true; // true if on editing mode, false if on adding mode

    nameController.text = item.name;
    descriptionController.text = item.description;

    if (item.id == null) {
      isEdit = false;
      editStatus = "Add";
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
            title: Text(editStatus + ' Item'),
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

                // fourth element, save and delete buttons
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
                              goToLastScreen();
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
        'type': item.type
      });

      // update the newly added item with the updated doc id
      final String returnedID = documentReference.documentID;

      Firestore.instance.collection('items').document(returnedID).updateData({ 'id': returnedID});

      // another way of adding new item. The above is better because
      // you can get the doc id of the newly added item
      /*
      Firestore.instance.collection('items').document().setData({
        'description': item.description,
        'id': 'temp',
        'name': item.name,
        'type': item.type
      });
      */
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

  void updateType(bool newType) {
    item.type = newType;
  }

  void goToLastScreen() {
    Navigator.pop(context);
  }
}
