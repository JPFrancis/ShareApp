import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shareapp/extras/helpers.dart';

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
    // TODO: implement initState
    super.initState();

    searchList = widget.searchList;
    searchController.text = widget.searchQuery;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Search Results Page'),
      ),
      body: searchList != null && searchList.length > 0
          ? showBody()
          : Container(),
    );
  }

  Widget showBody() {
    return WillPopScope(
      child: Container(
        padding: EdgeInsets.all(10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            searchField(),
            buildSearchResultsList(),
          ],
        ),
      ),
    );
  }

  Widget searchField() {
    return Container(
      height: 100,
      child: Container(
        padding: EdgeInsets.only(left: 10),
        color: Colors.white,
        child: Row(
          children: <Widget>[
            Icon(Icons.search),
            SizedBox(
              width: 10.0,
            ),
            Expanded(
              child: TextField(
                keyboardType: TextInputType.text,
                controller: searchController,
                onTap: () {
                  if (searchList.length == 0) {
                    setState(() {
                      getAllItems();
                    });
                  }
                },
                onChanged: (value) {
                  setState(() {});
                },
                decoration: InputDecoration(
                  labelStyle: TextStyle(
                    color: Colors.black54,
                  ),
                ),
              ),
            ),
            Container(
              width: 40,
              child: FlatButton(
                onPressed: () {
                  setState(() {
                    searchController.clear();
                    FocusScope.of(context).requestFocus(FocusNode());
                  });
                },
                child: Icon(Icons.clear),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget buildSearchResultsList() {
    return Expanded(
      child: RefreshIndicator(
        onRefresh: () => getAllItems(),
        child: ListView.builder(
          itemCount: searchList.length,
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

            return show
                ? ListTile(
                    leading: Icon(Icons.build),
                    title: Text(
                      '${searchList[index]['name']}',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text('${searchList[index]['description']}'),
                    onTap: () => navigateToDetail(searchList[index], context),
                  )
                : Container();
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
