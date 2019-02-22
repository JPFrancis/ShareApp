import 'package:flutter/material.dart';
import 'package:shareapp/item.dart';
import 'package:shareapp/item_edit.dart';

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
                          strType,
                          style: TextStyle(color: Colors.black, fontSize: 24.0),
                          textAlign: TextAlign.center,
                        ),
                      )
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

  void goToLastScreen() {
    Navigator.pop(context);
  }
}
