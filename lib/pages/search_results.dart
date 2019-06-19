import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:shareapp/extras/helpers.dart';
import 'package:shareapp/services/const.dart';

class SearchResults extends StatefulWidget {
  static const routeName = '/searchResults';

  SearchResults({Key key}) : super(key: key);

  @override
  State<StatefulWidget> createState() {
    return SearchResultsState();
  }
}

class SearchResultsState extends State<SearchResults> {
  List<DocumentSnapshot> searchList;
  TextEditingController searchController = TextEditingController();

  @override
  void initState() {
    super.initState();

    searchController.text = '';
    getAllItems();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: coolerWhite,
      /*
      floatingActionButton: Container(
        padding: const EdgeInsets.only(top: 120.0, left: 5.0),
        child: FloatingActionButton(
          mini: true,
          onPressed: () => Navigator.pop(context),
          child: Icon(Icons.clear),
          elevation: 1,
          backgroundColor: Colors.white70,
          foregroundColor: primaryColor,
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.miniStartTop,
      */
      body: showBody()//searchList != null ? showBody() : searchField()
    );
  }

  Widget showBody() {
    double h = MediaQuery.of(context).size.height;
    double w = MediaQuery.of(context).size.width;
    return Container(
      height: h,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          SizedBox(height: 50.0),
          Row(crossAxisAlignment: CrossAxisAlignment.center, children: <Widget>[
            SizedBox(width: 10.0,),
            IconButton(onPressed: () => Navigator.pop(context), icon: Icon(Icons.clear, color: primaryColor,)),
            Expanded(child: searchField()),
          ],),
          searchController.text.isNotEmpty
           ? Container(
              alignment: Alignment.topRight,
              child: FlatButton(
                onPressed: () {
                  setState(() {
                    searchController.clear();
                    FocusScope.of(context).requestFocus(FocusNode());
                  });
                },
                child: Text("Reset"),
              ),
            )
          : Container(),
          buildSearchResultsList(),
        ],
      ),
    );
  }

  Widget searchField() {
    return Container(
      padding: EdgeInsets.only(),
      child: Column(
        children: <Widget>[
          Container(
            height: 70,
            decoration: new BoxDecoration(border: Border(left: BorderSide(color: primaryColor, width: 3)),),
            child: Center(
              child: TextField(
                autofocus: true,
                style: TextStyle(fontFamily: 'Quicksand', fontSize: 21),
                keyboardType: TextInputType.text,
                controller: searchController,
                onChanged: (value) {setState(() {});},
                decoration: InputDecoration(
                  hintStyle: TextStyle(fontFamily: 'Quicksand', fontSize: 20.0) ,
                  hintText: "Search for an item",
                  border: InputBorder.none,
                  prefixIcon: Icon(Icons.search, color: primaryColor,),
                ),
              ),
            ),
          ),

        ],
      ),
    );
  }

  Widget buildSearchResultsList() {
    double h = MediaQuery.of(context).size.height;
    return Expanded(
      child: searchController.text.isEmpty ? Container() :
      ListView.builder(
        shrinkWrap: true,
        padding: EdgeInsets.all(0),
        itemCount: searchList == null ? 0 : searchList.length,
        itemBuilder: (context, index) {
          String name = searchList[index]['name'].toLowerCase();
          String description = searchList[index]['description'].toLowerCase();

          List<String> splitList = List();
          splitList.addAll(name.split(' '));
          splitList.addAll(description.split(' '));

          RegExp regExp =
              RegExp(r'^' + searchController.text.toLowerCase() + r'.*$');

          bool show = false;
          splitList.forEach((String str) {
            if (regExp.hasMatch(str)) {
              show = true;
            }
          });

          Widget _searchTile() {
            return InkWell(
              onTap: () => navigateToDetail(searchList[index], context),
              child: Container(
                child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: <Widget>[
                  Row(children: <Widget>[
                    ClipRRect(
                      borderRadius: BorderRadius.circular(5),
                      child: Container(
                        height: 80, width: 80,
                        child: FittedBox(
                          fit: BoxFit.cover,
                          child: CachedNetworkImage(
                            imageUrl: searchList[index]['images'][0],
                            placeholder: (context, url) => new CircularProgressIndicator(),
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: 10.0,),
                    Column(crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[
                      Text('${searchList[index]['name']}', style: TextStyle(fontFamily: 'Quicksand', fontWeight: FontWeight.bold, fontSize: h/45), textAlign: TextAlign.left,),
                      Row( children: <Widget>[
                        StarRating(rating: searchList[index]['rating'].toDouble(), sz: h / 40),
                        SizedBox(width: 5.0,),
                        Text('${searchList[index]['numRatings']} reviews', style: TextStyle(fontFamily: 'Quicksand', fontSize: h/65),),
                      ],),
                      Text('${searchList[index]['condition']}', style: TextStyle(fontFamily: 'Quicksand', fontStyle: FontStyle.italic, fontSize: h/65),),
                    ],),
                  ],),        
                  Column(children: <Widget>[
                      Row(children: <Widget>[
                          Text('\$${searchList[index]['price']}', style: TextStyle(fontFamily: 'Quicksand', fontSize: h/55)),
                          Text(' /day', style: TextStyle(fontFamily: 'Quicksand', fontSize: h/75)),
                      ],),
                  ],),
                ],),
              ),
            );
          }

          return show
              ? Column(
                children: <Widget>[
                  Container(padding:EdgeInsets.symmetric(vertical: 0.0, horizontal: 15.0), child: _searchTile()),
                  divider(),
                ],
              ): Container();
        },
      ),
    );
  }

  Future<Null> getAllItems() async {
    QuerySnapshot querySnapshot = await Firestore.instance
        .collection('items')
        .orderBy('name', descending: false)
        .getDocuments();
    setState(() {
      searchList = querySnapshot.documents;
    });
  }

  void goBack() {
    Navigator.pop(context);
  }
}
