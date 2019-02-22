import 'package:flutter/material.dart';
import 'package:shareapp/item.dart';
import 'package:shareapp/item_edit.dart';
import 'package:shareapp/item_detail.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ItemList extends StatefulWidget {
  @override
  State<StatefulWidget> createState() {
    return ItemListState();
  }
}

class ItemListState extends State<ItemList> {
  List<Item> itemList;
  int count = 0;

  @override
  Widget build(BuildContext context) {
    //count = itemList.length;

    // Scaffold is like a layout XML file in regular Android.
    // Set position of different widgets/views/buttons etc here
    return Scaffold(
      appBar: AppBar(
        title: Text('Items List'), /*
        actions: <Widget>[
          IconButton(
            icon: Icon(Icons.refresh),
            tooltip: 'Refresh',
            onPressed: () {
              debugPrint('refresh was pressed');
            },
        ),]
          */
      ),

      body: StreamBuilder(
          stream: Firestore.instance.collection('items').orderBy('type', descending: true).snapshots(),
          //stream: Firestore.instance.collection('items').snapshots(),
          builder: (context, snapshot) {
            if (!snapshot.hasData)
              return const Text('Loading...');
            else {
              return ListView.builder(
                //padding: EdgeInsets.all(2.0),
                  itemCount: snapshot.data.documents.length,
                  itemBuilder: (context, index) {
                    DocumentSnapshot ds = snapshot.data.documents[index];
                    Icon tileIcon;
                    if (ds['type']) {
                      tileIcon = Icon(Icons.build);
                    } else {
                      tileIcon = Icon(Icons.golf_course);
                    }

                    return ListTile(
                        leading: tileIcon,
                        //leading: Icon(Icons.build),
                        title: Text(ds['name'], style: TextStyle(fontWeight: FontWeight.bold),),
                        subtitle: Text(ds['description']),
                        onTap: () {
                          //navigateToEdit(Item.fromMap(ds.data, ds['id']));
                          navigateToDetail(Item.fromMap(ds.data, ds['id']));
                          debugPrint("ListTile Tapped");
                        },
                        trailing: IconButton(
                            icon: Icon(Icons.delete),
                            onPressed: () {
                              debugPrint('delete was pressed');
                              Firestore.instance.collection('items').document(
                                  ds['id']).delete();
                            })
                    );
                  }
              );
            }
          }
      ),

      floatingActionButton: FloatingActionButton(
        onPressed: () {
          debugPrint('FAB (add item) clicked');
          navigateToEdit(new Item(
              id: null,
              name: "",
              description: "",
              type: true));
          //navigateToEdit(Item({null, '', '', true}));
          //navigateToDetail(Item('', '', 2), 'Add Item');

        },

        // Help text when you hold down FAB
        tooltip: 'Add New Item',

        // Set FAB icon
        child: Icon(Icons.add),

      ),
    );
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

  void navigateToDetail(Item item) async {
    debugPrint('navToDetail function called');

    bool result = await Navigator.push(context, MaterialPageRoute(builder: (context) {
      return ItemDetail(item);
    }));
    /*
    Navigator.push(context, MaterialPageRoute(builder: (context) {
      return ItemEdit(item, title);
    }));*/
  }
}

void showSnackBar(BuildContext context, String item) {
  var message = SnackBar(
    content: Text("$item was pressed"),
    action: SnackBarAction(
        label: "Undo",
        onPressed: () {
          debugPrint('Performing dummy UNDO operation');
        }
    ),
  );

  Scaffold.of(context).showSnackBar(message);
}