import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shareapp/extras/helpers.dart';

class AllItems extends StatefulWidget {
  static const routeName = '/allItems';

  AllItems({Key key}) : super(key: key);

  @override
  State<StatefulWidget> createState() {
    return AllItemsState();
  }
}

class AllItemsState extends State<AllItems> {
  bool isLoading;

  @override
  void initState() {
    // TODO: implement initState
    super.initState();

    delayPage();
  }

  void delayPage() async {
    isLoading = true;
    Future.delayed(Duration(milliseconds: 750)).then((_) {
      setState(() {
        isLoading = false;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: isLoading ? Container() : allItemsPage(),
    );
  }

  Widget allItemsPage() {
    return WillPopScope(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          SizedBox(
            height: 25.0,
          ),
          Row(
            children: <Widget>[
              FlatButton(
                child: BackButton(),
                onPressed: () => goBack(),
              ),
              Text("Items near you",
                  style: TextStyle(fontFamily: 'Quicksand', fontSize: 30.0)),
            ],
          ),
          buildItemList(),
        ],
      ),
    );
  }


  Widget buildItemList() {
    int tilerows = MediaQuery.of(context).size.width > 500 ? 3 : 2;
    return Expanded(
      child: StreamBuilder<QuerySnapshot>(
        stream: Firestore.instance.collection('items').snapshots(),
        builder: (BuildContext context, AsyncSnapshot<QuerySnapshot> snapshot) {
          if (snapshot.hasError) { return new Text('${snapshot.error}'); }
          switch (snapshot.connectionState) {
            case ConnectionState.waiting:

            default:
              if (snapshot.hasData) {
                List<DocumentSnapshot> items = snapshot.data.documents;
                return GridView.count(
                  shrinkWrap: true,
                  mainAxisSpacing: 15.0,
                  crossAxisCount: tilerows,
                  childAspectRatio: (2 / 3),
                  padding: const EdgeInsets.all(20.0),
                  crossAxisSpacing: MediaQuery.of(context).size.width / 20,
                  children: items.map((DocumentSnapshot ds) => itemCard(ds, context)).toList()
                );
              } else { return Container(); }
          }
        },
      ),
    );
  }

  Widget buildItemListTemp() {
    return Expanded(
      child: StreamBuilder<QuerySnapshot>(
        stream: Firestore.instance
            .collection('items')
            .orderBy('name', descending: false)
            .snapshots(),
        builder: (BuildContext context, AsyncSnapshot<QuerySnapshot> snapshot) {
          if (snapshot.hasError) {
            return new Text('${snapshot.error}');
          }
          switch (snapshot.connectionState) {
            case ConnectionState.waiting:

            default:
              if (snapshot.hasData) {
                List<DocumentSnapshot> allItems = snapshot.data.documents;
                return ListView.builder(
                  itemCount: allItems.length,
                  itemBuilder: (context, index) {
                    return ListTile(
                      leading: Icon(Icons.build),
                      title: Text( '${allItems[index]['name']}', style: TextStyle(fontWeight: FontWeight.bold),),
                      subtitle: Text('${allItems[index]['description']}'),
                      onTap: () => navigateToDetail(allItems[index], context),
                      trailing: StarRating(rating: 3.5, sz: MediaQuery.of(context).size.height/15),
                    );
                  },
                );
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