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

  @override
  void initState() {
    // TODO: implement initState
    super.initState();

    searchList = widget.searchList;
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () {
        goBack();
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text('Search Results Page'),
        ),
        body: searchList != null && searchList.length > 0
            ? showBody()
            : Container(),
      ),
    );
  }

  Widget showBody() {
    return Container(
      padding: EdgeInsets.all(10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            'Search results for \"${widget.searchQuery}\"',
            style: TextStyle(fontSize: 18),
          ),
          buildSearchResultsList(),
          //buildItemListTEST(),
        ],
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
            String name = searchList[index]['name'];
            String description = searchList[index]['description'];

            return name
                        .toLowerCase()
                        .contains(widget.searchQuery.toLowerCase()) ||
                    description
                        .toLowerCase()
                        .contains(widget.searchQuery.toLowerCase())
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

  Widget buildItemListTEST() {
    return Expanded(
      child: StreamBuilder<QuerySnapshot>(
        stream: Firestore.instance
            .collection('items')
            .where('name', isEqualTo: widget.searchQuery)
            .snapshots(),
        builder: (BuildContext context, AsyncSnapshot<QuerySnapshot> snapshot) {
          if (snapshot.hasError) {
            return new Text('${snapshot.error}');
          }
          switch (snapshot.connectionState) {
            case ConnectionState.waiting:

            default:
              if (snapshot.hasData) {
                List<DocumentSnapshot> items = snapshot.data.documents;
                return ListView.builder(
                  itemCount: items.length,
                  itemBuilder: (context, index) {
                    return ListTile(
                      leading: Icon(Icons.build),
                      title: Text(
                        '${items[index]['name']}',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text('${items[index]['description']}'),
                      onTap: () => navigateToDetail(items[index], context),
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
    Navigator.pop(context, searchList);
  }
}
