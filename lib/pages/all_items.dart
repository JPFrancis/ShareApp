import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart';
import 'package:shareapp/main.dart';
import 'package:shareapp/pages/item_detail.dart';

class AllItems extends StatefulWidget {
  FirebaseUser firebaseUser;

  State<StatefulWidget> createState() {
    return AllItemsState();
  }
}

@override
class AllItemsState extends State<AllItems> {
  String userID;
  void initState() {
    super.initState();
    userID = widget.firebaseUser.uid;
  }

  Widget build(BuildContext context) {
    return Scaffold(body: homeTabPage());
  }

  Widget homeTabPage() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        //  searchField(),
        Padding(
          padding: const EdgeInsets.only(left: 20.0),
          child: Text("Items near you",
              style: TextStyle(
                  fontFamily: 'Quicksand',
                  fontWeight: FontWeight.bold,
                  fontSize: 30.0)),
        ),
        buildItemList('all'),
      ],
    );
  }

  Widget buildItemList([type = 'all', bool status]) {
    CollectionReference collectionReference =
        Firestore.instance.collection('items');
    int tilerows = MediaQuery.of(context).size.width > 500 ? 3 : 2;
    Stream stream = collectionReference.snapshots();
    if (type == 'listings') {
      stream = collectionReference
          .where('creator',
              isEqualTo: Firestore.instance.collection('users').document(userID))
          .snapshots();
    }
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
                    crossAxisCount: tilerows,
                    childAspectRatio: (2 / 3),
                    padding: const EdgeInsets.all(20.0),
  //                  mainAxisSpacing: 10.0,
                    crossAxisSpacing: MediaQuery.of(context).size.width / 15,
                    children: items
                        .map((DocumentSnapshot ds) => cardItem(ds))
                        .toList());
              } else {
                return Container();
              }
          }
        },
      ),
    );
  }

  Widget cardItem(DocumentSnapshot ds) {
    CachedNetworkImage image = CachedNetworkImage(
      key: new ValueKey<String>(DateTime.now().millisecondsSinceEpoch.toString()),
      imageUrl: ds['images'][0],
      placeholder: (context, url) => new CircularProgressIndicator(),
    );
    return InkWell(onTap: () {
      navigateToDetail(ds.documentID);
    }, onLongPress: () {
      //ds['rental'] == null ? deleteItemDialog(ds) : deleteItemError();
    }, child: new Container(child: new LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
      double h = constraints.maxHeight;
      double w = constraints.maxWidth;
      Icon icon = Icon(Icons.info_outline);
      switch (ds['type']) {
        case 'Tool':
          icon = Icon(
            Icons.build,
            size: h / 20,
          );
          break;
        case 'Leisure':
          icon = Icon(Icons.golf_course, size: h / 20);
          break;
        case 'Home':
          icon = Icon(Icons.home, size: h / 20);
          break;
        case 'Other':
          icon = Icon(Icons.device_unknown, size: h / 20);
          break;
      }
      return Column(
        children: <Widget>[
          Container(
              height: 2 * h / 3,
              width: w,
              child: FittedBox(fit: BoxFit.cover, child: image)),
          SizedBox(
            height: 10.0,
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Row(
                children: <Widget>[
                  icon,
                  SizedBox(
                    width: 5.0,
                  ),
                  ds['type'] != null
                      ? Text(
                          '${ds['type']}'.toUpperCase(),
                          style: TextStyle(
                              fontSize: h / 25,
                              fontFamily: 'Quicksand',
                              fontWeight: FontWeight.bold),
                        )
                      : Text(''),
                ],
              ),
              Text(ds['name'],
                  style: TextStyle(
                      fontSize: h / 20,
                      fontFamily: 'Quicksand',
                      fontWeight: FontWeight.bold)),
              Text("\$${ds['price']} per day",
                  style: TextStyle(fontSize: h / 21, fontFamily: 'Quicksand')),
              Row(
                children: <Widget>[
                  Icon(
                    Icons.star_border,
                    size: h / 19,
                  ),
                  Icon(
                    Icons.star_border,
                    size: h / 19,
                  ),
                  Icon(
                    Icons.star_border,
                    size: h / 19,
                  ),
                  Icon(
                    Icons.star_border,
                    size: h / 19,
                  ),
                  Icon(
                    Icons.star_border,
                    size: h / 19,
                  ),
                  Container(
                    width: 5.0,
                  ),
                  Text(
                    "328",
                    style: TextStyle(
                      fontSize: h / 25,
                      fontFamily: 'Quicksand',
                      fontWeight: FontWeight.bold,
                    ),
                  )
                ],
              )
            ],
          ),
        ],
      );
    })));
  }

  void navigateToDetail(String itemID) async {
    Navigator.pushNamed(
      context,
      ItemDetail.routeName,
      arguments: ItemDetailArgs(
        itemID,
      ),
    );
  }
}

