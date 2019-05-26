import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shareapp/extras/helpers.dart';

class AllItems extends StatefulWidget {
  static const routeName = '/allItems';

  AllItems({
    Key key,
  }) : super(key: key);

  @override
  State<StatefulWidget> createState() {
    return AllItemsState();
  }
}

class AllItemsState extends State<AllItems> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: allItemsPage(),
      //floatingActionButton: showFAB(),
    );
  }

  Widget allItemsPage() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        SizedBox(
          height: 25.0,
        ),
        Row(
          children: <Widget>[
            FlatButton(
              child: BackButton(),
              onPressed: () => Navigator.pop(context),
            ),
            Text("Items near you",
                style: TextStyle(fontFamily: 'Quicksand', fontSize: 30.0)),
          ],
        ),
        buildItemListTemp(),
      ],
    );
  }

  Widget buildItemList() {
    CollectionReference collectionReference =
        Firestore.instance.collection('items');
    int tilerows = MediaQuery.of(context).size.width > 500 ? 3 : 2;
    Stream stream = collectionReference.snapshots();
    return Expanded(
      child: StreamBuilder<QuerySnapshot>(
        stream: stream,
        builder: (BuildContext context, AsyncSnapshot<QuerySnapshot> snapshot) {
          if (snapshot.hasError) {
            return new Text('${snapshot.error}');
          }
          switch (snapshot.connectionState) {
            case ConnectionState.waiting:

            default:
              if (snapshot.hasData) {
                List<DocumentSnapshot> items = snapshot.data.documents.toList();
                return GridView.count(
                    shrinkWrap: true,
                    mainAxisSpacing: 15.0,
                    crossAxisCount: tilerows,
                    childAspectRatio: (2 / 3),
                    padding: const EdgeInsets.all(20.0),
                    crossAxisSpacing: MediaQuery.of(context).size.width / 20,
                    children: items
                        .map((DocumentSnapshot ds) => itemCard(ds, context))
                        .toList());
              } else {
                return Container();
              }
          }
        },
      ),
    );
  }

  Widget buildItemListTemp() {
    CollectionReference collectionReference =
        Firestore.instance.collection('items');
    Stream stream = collectionReference.orderBy('name', descending: false).snapshots();
    return Expanded(
      child: StreamBuilder<QuerySnapshot>(
        stream: stream,
        builder: (BuildContext context, AsyncSnapshot<QuerySnapshot> snapshot) {
          if (snapshot.hasError) {
            return new Text('${snapshot.error}');
          }
          switch (snapshot.connectionState) {
            case ConnectionState.waiting:

            default:
              if (snapshot.hasData) {
                return ListView.builder(
                    itemCount: snapshot.data.documents.length,
                    itemBuilder: (context, index) {
                      DocumentSnapshot ds = snapshot.data.documents[index];

                      return ListTile(
                        leading: Icon(Icons.build),
                        title: Text(
                          ds['name'],
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text(ds['description']),
                        onTap: () {
                          navigateToDetail(ds.documentID, context);
                        },
                      );
                    });
              } else {
                return Container();
              }
          }
        },
      ),
    );
  }

  void goBack() {
    Navigator.pop(context);
  }
}
