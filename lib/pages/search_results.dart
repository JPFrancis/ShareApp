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
  TextEditingController searchController = TextEditingController();
  List<DocumentSnapshot> allItems;
  List<String> filteredList;
  List<String> searchList;
  List<String> suggestionsList;
  bool showSuggestions = true;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();

    searchController.text = '';
    getAllItems();
  }

  Future<Null> getAllItems() async {
    searchList = [];
    filteredList = [];
    suggestionsList = [];

    QuerySnapshot querySnapshot = await Firestore.instance
        .collection('items')
        .orderBy('name', descending: false)
        .getDocuments();

    if (querySnapshot != null) {
      allItems = querySnapshot.documents;

      allItems.forEach((DocumentSnapshot ds) {
        String name = ds['name'].toLowerCase();
        String description = ds['description'].toLowerCase();

        suggestionsList.add(name);
        searchList.addAll(name.split(' '));
        searchList.addAll(description.split(' '));
      });

      suggestionsList = suggestionsList.toSet().toList();

      searchList = searchList.toSet().toList();

      for (int i = 0; i < searchList.length; i++) {
        searchList[i] = searchList[i].replaceAll(RegExp(r"[^\w]"), '');
      }

      searchList = searchList.toSet().toList();
      searchList.sort();
      searchList.remove('');
      filteredList = searchList;

      //debugPrint('LIST: $searchList, LENGTH: ${searchList.length}');
      setState(() {
        isLoading = false;
      });
    }
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
      body: isLoading ? Container() : showBody(),
    );
  }

  Widget showBody() {
    double h = MediaQuery.of(context).size.height;
    double w = MediaQuery.of(context).size.width;

    RegExp regExp = RegExp(r'^' + searchController.text.toLowerCase() + r'.*$');

    if (searchController.text.isNotEmpty) {
      List<String> temp = [];
      for (int i = 0; i < filteredList.length; i++) {
        if (regExp.hasMatch(filteredList[i])) {
          temp.add(filteredList[i]);
        }
      }

      filteredList = temp;
    } else {
      filteredList = searchList;
    }

    return Container(
      height: h,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          SizedBox(height: 50.0),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              SizedBox(
                width: 10.0,
              ),
              IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: Icon(
                    Icons.clear,
                    color: primaryColor,
                  )),
              Expanded(
                child: searchField(),
              ),
            ],
          ),
          searchController.text.isNotEmpty
              ? Container(
                  alignment: Alignment.topRight,
                  child: FlatButton(
                    onPressed: () {
                      setState(() {
                        searchController.clear();
                        showSuggestions = true;
                        //FocusScope.of(context).requestFocus(FocusNode());
                      });
                    },
                    child: Text("Reset"),
                  ),
                )
              : Container(),
          buildLists(),
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
            decoration: new BoxDecoration(
              border: Border(left: BorderSide(color: primaryColor, width: 3)),
            ),
            child: Center(
              child: TextField(
                autofocus: true,
                textInputAction: TextInputAction.search,
                style: TextStyle(fontFamily: 'Quicksand', fontSize: 21),
                keyboardType: TextInputType.text,
                controller: searchController,
                onTap: () {
                  setState(() {
                    showSuggestions = true;
                  });
                },
                onSubmitted: (value) {
                  setState(() {
                    showSuggestions = false;
                  });
                },
                onChanged: (value) {
                  setState(() {
                    showSuggestions = true;
                  });
                },
                decoration: InputDecoration(
                  hintStyle: TextStyle(fontFamily: 'Quicksand', fontSize: 20.0),
                  hintText: "Search for an item",
                  border: InputBorder.none,
                  prefixIcon: Icon(
                    Icons.search,
                    color: primaryColor,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget buildLists() {
    double h = MediaQuery.of(context).size.height;

    return Expanded(
      child: showSuggestions ? buildSuggestionsList() : buildItemsList(),
      //child: buildSuggestionsList(),
    );
  }

  Widget buildItemsList() {
    double h = MediaQuery.of(context).size.height;

    return ListView.builder(
      shrinkWrap: true,
      padding: EdgeInsets.all(0),
      itemCount: allItems == null ? 0 : allItems.length,
      itemBuilder: (context, index) {
        String name = allItems[index]['name'].toLowerCase();
        String description = allItems[index]['description'].toLowerCase();
        String searchText = searchController.text.trim().toLowerCase();

        List<String> splitList = List();
        splitList.addAll(name.split(' '));
        splitList.addAll(description.split(' '));

        RegExp regExp = RegExp(r'^' + searchText + r'.*$');

        bool show = false;
        splitList.forEach((String str) {
          if (regExp.hasMatch(str)) {
            show = true;
          }
        });

        if (name == searchText) {
          show = true;
        }

        Widget _searchTile() {
          return InkWell(
            onTap: () => navigateToDetail(allItems[index], context),
            child: Container(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: <Widget>[
                  Row(
                    children: <Widget>[
                      ClipRRect(
                        borderRadius: BorderRadius.circular(5),
                        child: Container(
                          height: 80,
                          width: 80,
                          child: FittedBox(
                            fit: BoxFit.cover,
                            child: CachedNetworkImage(
                              imageUrl: allItems[index]['images'][0],
                              placeholder: (context, url) =>
                                  new CircularProgressIndicator(),
                            ),
                          ),
                        ),
                      ),
                      SizedBox(
                        width: 10.0,
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(
                            '${allItems[index]['name']}',
                            style: TextStyle(
                                fontFamily: 'Quicksand',
                                fontWeight: FontWeight.bold,
                                fontSize: h / 45),
                            textAlign: TextAlign.left,
                          ),
                          Row(
                            children: <Widget>[
                              StarRating(
                                  rating: allItems[index]['rating'].toDouble(),
                                  sz: h / 40),
                              SizedBox(
                                width: 5.0,
                              ),
                              Text(
                                '${allItems[index]['numRatings']} reviews',
                                style: TextStyle(
                                    fontFamily: 'Quicksand', fontSize: h / 65),
                              ),
                            ],
                          ),
                          Text(
                            '${allItems[index]['condition']}',
                            style: TextStyle(
                                fontFamily: 'Quicksand',
                                fontStyle: FontStyle.italic,
                                fontSize: h / 65),
                          ),
                        ],
                      ),
                    ],
                  ),
                  Column(
                    children: <Widget>[
                      Row(
                        children: <Widget>[
                          Text('\$${allItems[index]['price']}',
                              style: TextStyle(
                                  fontFamily: 'Quicksand', fontSize: h / 55)),
                          Text(' /day',
                              style: TextStyle(
                                  fontFamily: 'Quicksand', fontSize: h / 75)),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        }

        return show
            ? Column(
                children: <Widget>[
                  Container(
                      padding:
                          EdgeInsets.symmetric(vertical: 0.0, horizontal: 15.0),
                      child: _searchTile()),
                  divider(),
                ],
              )
            : Container();
      },
    );
  }

  Widget buildSuggestionsList() {
    List builderList =
        searchController.text.isEmpty ? suggestionsList : filteredList;

    return ListView.builder(
        itemCount: builderList.length,
        itemBuilder: (context, index) {
          return ListTile(
            title: Text(builderList[index]),
            trailing: IconButton(
              icon: Icon(Icons.keyboard_arrow_up),
              onPressed: () {
                setState(() {
                  searchController.text = builderList[index];
                  searchController.value = TextEditingValue(
                      text: builderList[index],
                      selection: TextSelection.collapsed(
                          offset: builderList[index].length));
                });
              },
            ),
            onTap: () {
              setState(() {
                searchController.text = builderList[index];
                showSuggestions = false;
                FocusScope.of(context).requestFocus(FocusNode());
              });
            },
          );
        });
  }

  void goBack() {
    Navigator.pop(context);
  }
}
