import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shareapp/main.dart';

import 'package:shareapp/pages/item_detail.dart';
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
    return WillPopScope(
      onWillPop: () {
        goBack();
      },
      child: Scaffold(
        body: allItemsPage(),
        //floatingActionButton: showFAB(),
      ),
    );
  }

  Widget allItemsPage() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        SizedBox( height: 25.0,),
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
        buildItemList('all'),
      ],
    );
  }

  Widget buildItemList([type = 'all', bool status]) {
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
      key: new ValueKey<String>(
          DateTime.now().millisecondsSinceEpoch.toString()),
      imageUrl: ds['images'][0],
      placeholder: (context, url) => new CircularProgressIndicator(),
    );
    return InkWell(onTap: () {
      navigateToDetail(ds.documentID);
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
    return Container(
        decoration: new BoxDecoration( 
          boxShadow: <BoxShadow>[
            CustomBoxShadow(
              color: Colors.black45,
              blurRadius: 4.0,
              blurStyle: BlurStyle.outer
            ),
          ],
        ),
        child: Column(
          children: <Widget>[
            Container(
                height: 2 * h / 3,
                width: w,
                child: FittedBox(fit: BoxFit.cover, child: image)),
            SizedBox(height: 10.0,),
            Container(
              padding: EdgeInsets.only(left: 5.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Row(
                    children: <Widget>[
                      icon,
                      SizedBox( width: 5.0,),
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
                  SizedBox(height: 2.0,),
                  Text(ds['name'], style: TextStyle( fontSize: h / 20, fontFamily: 'Quicksand', fontWeight: FontWeight.bold)),
                  SizedBox(height: 2.0,),
                  Text("\$${ds['price']} per day", style: TextStyle(fontSize: h / 21, fontFamily: 'Quicksand')),
                  SizedBox(height: 2.0,),
                  Row(
                    children: <Widget>[
                      Icon( Icons.star_border, size: h / 19,),
                      Icon( Icons.star_border, size: h / 19,),
                      Icon( Icons.star_border, size: h / 19,),
                      Icon( Icons.star_border, size: h / 19,),
                      Icon( Icons.star_border, size: h / 19,),
                      SizedBox( width: 5.0,),
                      Text( "328", style: TextStyle( fontSize: h / 25, fontFamily: 'Quicksand', fontWeight: FontWeight.bold,),)
                    ],
                  )
                ],
              ),
            ),
          ],
        ),
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

  void goBack() {
    Navigator.pop(context);
  }
}
