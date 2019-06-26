import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shareapp/extras/helpers.dart';

class ItemFilter extends StatefulWidget {
  static const routeName = '/allItems';
  final String filter;

  ItemFilter({Key key, this.filter}) : super(key: key);

  @override
  State<StatefulWidget> createState() {
    return ItemFilterState();
  }
}

class ItemFilterState extends State<ItemFilter> {
  String myUserID;

  String title;
  Stream stream;
  String filter;

  bool isLoading = true;
  bool isAuthenticated;

  String font = 'Quicksand';

  @override
  void initState() {
    // TODO: implement initState
    super.initState();

    filter = widget.filter;

    getMyUserID();
    delayPage();
  }

  void delayPage() async {
    Future.delayed(Duration(milliseconds: 750)).then((_) {
      setState(() {
        isLoading = false;
      });
    });
  }

  void getMyUserID() async {
    FirebaseUser user = await FirebaseAuth.instance.currentUser();

    if (user != null) {
      isAuthenticated = true;
      myUserID = user.uid;
    } else {
      isAuthenticated = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (filter == 'All') {
      title = 'All items';
      stream = Firestore.instance.collection('items').snapshots();
    } else {
      title = filter;
      switch (title) {
        case 'Tool':
          title = 'Tools';
          break;
        case 'Home':
          title = 'Household';
          break;
      }
      stream = Firestore.instance
          .collection('items')
          .where('type', isEqualTo: filter)
          .snapshots();
    }

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
              Text(title,
                  style: TextStyle(fontFamily: 'Quicksand', fontSize: 30.0)),
            ],
          ),
          showFilterSelector(),
          buildItemList(),
        ],
      ),
    );
  }

  Widget showFilterSelector() {
    String hint = filter;
    double padding = 20;

    switch (hint) {
      case 'Tool':
        hint = 'Tools';
        break;
      case 'Home':
        hint = 'Household';
        break;
    }

    return Padding(
      padding: EdgeInsets.only(left: padding, right: padding),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
            isDense: true,
            isExpanded: true,
            // [todo value]
            hint: Text(
              hint,
              style: TextStyle(fontFamily: font, fontWeight: FontWeight.w500),
            ),
            onChanged: (value) {
              switch (value) {
                case 'Tools':
                  setState(() => filter = 'Tool');
                  break;
                case 'Leisure':
                  setState(() => filter = 'Leisure');
                  break;
                case 'Household':
                  setState(() => filter = 'Home');
                  break;
                case 'Equipment':
                  setState(() => filter = 'Equipment');
                  break;
                case 'Miscellaneous':
                  setState(() => filter = 'Other');
                  break;
                case 'All':
                  setState(() => filter = 'All');
                  break;
              }
            },
            items: [
              'Tools',
              'Leisure',
              'Household',
              'Equipment',
              'Miscellaneous',
              'All',
            ]
                .map(
                  (selection) => DropdownMenuItem<String>(
                        value: selection,
                        child: Text(
                          selection,
                          style: TextStyle(fontFamily: font),
                        ),
                      ),
                )
                .toList()),
      ),
    );
  }

  Widget buildItemList() {
    int tilerows = MediaQuery.of(context).size.width > 500 ? 3 : 2;
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
                List<DocumentSnapshot> items = snapshot.data.documents;
                List<Widget> cards = [];

                items.forEach((ds) {
                  if (!isAuthenticated ||
                      ds['creator'].documentID != myUserID) {
                    cards.add(itemCard(ds, context));
                  }
                });

                return GridView.count(
                  shrinkWrap: true,
                  mainAxisSpacing: 15.0,
                  crossAxisCount: tilerows,
                  childAspectRatio: (2 / 3),
                  padding: const EdgeInsets.all(20.0),
                  crossAxisSpacing: MediaQuery.of(context).size.width / 20,
                  children: cards,
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
