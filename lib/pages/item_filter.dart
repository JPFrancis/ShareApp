import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shareapp/extras/helpers.dart';

class ItemFilter extends StatefulWidget {
  static const routeName = '/allItems';
  final String typeFilter;

  ItemFilter({Key key, this.typeFilter}) : super(key: key);

  @override
  State<StatefulWidget> createState() {
    return ItemFilterState();
  }
}

class ItemFilterState extends State<ItemFilter> {
  String myUserID;

  Stream stream;
  String typeFilter;
  String conditionFilter;
  int priceFilter;
  String orderByFilter;

  bool isLoading = true;
  bool isAuthenticated;

  String font = 'Quicksand';

  @override
  void initState() {
    // TODO: implement initState
    super.initState();

    typeFilter = widget.typeFilter;
    conditionFilter = 'All';
    priceFilter = 0;
    orderByFilter = 'Alphabetically';

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
    Query query = Firestore.instance.collection('items');

    if (typeFilter != 'All') {
      query = query.where('type', isEqualTo: typeFilter);
    }

    if (conditionFilter != 'All') {
      query = query.where('condition', isEqualTo: conditionFilter);
    }

    if (priceFilter != 0) {
      query = query.where('price', isLessThanOrEqualTo: priceFilter);
    }

    switch (orderByFilter) {
      case 'Alphabetically':
        query = query.orderBy('name', descending: false);
        break;
      case 'Price low to high':
        query = query.orderBy('price', descending: false);
        break;
      case 'Rating':
        query = query.orderBy('rating', descending: true);
        break;
    }

    stream = query.snapshots();

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
              Text('Item Filter Page',
                  style: TextStyle(fontFamily: 'Quicksand', fontSize: 30.0)),
            ],
          ),
          typeSelector(),
          Container(
            height: 20,
          ),
          conditionSelector(),
          Container(
            height: 20,
          ),
          priceSelector(),
          Container(
            height: 20,
          ),
          orderBy(),
          buildItemList(),
        ],
      ),
    );
  }

  Widget typeSelector() {
    String hint = 'Type: $typeFilter';
    double padding = 20;

    switch (hint) {
      case 'Tool':
        hint = 'Type: Tools';
        break;
      case 'Home':
        hint = 'Type: Household';
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
                  setState(() => typeFilter = 'Tool');
                  break;
                case 'Leisure':
                  setState(() => typeFilter = 'Leisure');
                  break;
                case 'Household':
                  setState(() => typeFilter = 'Home');
                  break;
                case 'Equipment':
                  setState(() => typeFilter = 'Equipment');
                  break;
                case 'Miscellaneous':
                  setState(() => typeFilter = 'Other');
                  break;
                case 'All':
                  setState(() => typeFilter = 'All');
                  break;
              }
            },
            items: [
              'All',
              'Tools',
              'Leisure',
              'Household',
              'Equipment',
              'Miscellaneous',
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

  Widget conditionSelector() {
    String hint = 'Condition: $conditionFilter';
    double padding = 20;

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
              setState(() {
                conditionFilter = value;
              });
            },
            items: [
              'All',
              'Lightly Used',
              'Good',
              'Fair',
              'Has Character',
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

  Widget priceSelector() {
    String hint = 'Max price: $priceFilter';
    if (priceFilter == 0) {
      hint = 'Max price: none';
    }

    double padding = 20;

    return Padding(
      padding: EdgeInsets.only(left: padding, right: padding),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<int>(
            isDense: true,
            isExpanded: true,
            // [todo value]
            hint: Text(
              hint,
              style: TextStyle(fontFamily: font, fontWeight: FontWeight.w500),
            ),
            onChanged: (value) {
              setState(() {
                priceFilter = value;
              });
            },
            items: [
              0,
              5,
              10,
              25,
              50,
            ]
                .map(
                  (selection) => DropdownMenuItem<int>(
                        value: selection,
                        child: Text(
                          '$selection',
                          style: TextStyle(fontFamily: font),
                        ),
                      ),
                )
                .toList()),
      ),
    );
  }

  Widget orderBy() {
    String hint = 'Sort by: $orderByFilter';

    double padding = 20;

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
              setState(() {
                orderByFilter = value;
              });
            },
            items: [
              'Alphabetically',
              'Price low to high',
              'Rating',
            ]
                .map(
                  (selection) => DropdownMenuItem<String>(
                        value: selection,
                        child: Text(
                          '$selection',
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
