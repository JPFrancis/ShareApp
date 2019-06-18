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

  final List<DocumentSnapshot> searchList;
  final String searchQuery;

  SearchResults({Key key, this.searchList, this.searchQuery}) : super(key: key);

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

    searchList = widget.searchList;
    searchController.text = widget.searchQuery;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: coolerWhite,
      floatingActionButton: Container(
        padding: const EdgeInsets.only(top: 120.0, left: 5.0),
        child: FloatingActionButton(
          onPressed: () => Navigator.pop(context),
          child: Icon(Icons.arrow_back),
          elevation: 1,
          backgroundColor: Colors.white70,
          foregroundColor: primaryColor,
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.startTop,
      body: searchList != null && searchList.length > 0
          ? showBody()
          : Container(),
    );
  }

  Widget showBody() {
    double h = MediaQuery.of(context).size.height;
    double w = MediaQuery.of(context).size.width;
    return Container(
      child: Container(
        height: MediaQuery.of(context).size.height,
        padding: EdgeInsets.only(bottom: 30),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            buildSearchResultsList(),
            searchField(),
          ],
        ),
      ),
    );
  }

  Widget searchField() {
    return Container(
      padding: EdgeInsets.only(left: 10, right: 10),
      child: Container(
      decoration: new BoxDecoration(
        border: Border.all(color: primaryColor),
        color: Colors.white,
        borderRadius: new BorderRadius.all(Radius.circular(9))),
        child: TextField(
          keyboardType: TextInputType.text,
          controller: searchController,
          onTap: () {if (searchList.length == 0) setState(() {getAllItems();});},
          onChanged: (value) {setState(() {});},
          decoration: InputDecoration(
            border: InputBorder.none,
            prefixIcon: Icon(Icons.search, color: primaryColor,),
            suffixIcon: 
              Container(
                width: 40,
                child: FlatButton(
                  onPressed: () {
                    setState(() {
                      searchController.clear();
                      FocusScope.of(context).requestFocus(FocusNode());
                  });},
                  child: Icon(Icons.clear, color: primaryColor,),
              ),),
            labelStyle: TextStyle(color: Colors.black54),
          ),
        ),
      ),
    );
  }

  Widget buildSearchResultsList() {
    double h = MediaQuery.of(context).size.height;
    return Expanded(
      child: RefreshIndicator(
        onRefresh: () => getAllItems(),
        child: searchController.text.isEmpty ? Container() :
        ListView.builder(
          shrinkWrap: true,
          padding: EdgeInsets.only(bottom: 0.0, top: 60),
          itemCount: searchList.length,
          itemBuilder: (context, index) {
            String name = searchList[index]['name'].toLowerCase();
            String description = searchList[index]['description'].toLowerCase();

            List<String> splitList = List();
            splitList.addAll(name.split(' '));
            splitList.addAll(description.split(' '));

            RegExp regExp = RegExp(r'^' + searchController.text.toLowerCase() + r'.*$');

            bool show = false;
            splitList.forEach((String str) {
              if (regExp.hasMatch(str)) {
                show = true;
              }
            });

            Widget _searchTile(){
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
