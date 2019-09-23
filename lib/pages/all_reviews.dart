import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shareapp/extras/helpers.dart';

class AllReviews extends StatefulWidget {
  static const routeName = '/allReviews';
  final DocumentSnapshot itemDS;

  AllReviews({Key key, this.itemDS}) : super(key: key);

  @override
  State<StatefulWidget> createState() {
    return AllReviewsState();
  }
}

enum SortByFilter { recent, highToLow }

class AllReviewsState extends State<AllReviews> {
  bool isLoading = true;
  String font = 'Quicksand';
  SortByFilter filter = SortByFilter.recent;
  String filterText = '';
  Stream stream;
  final dateFormat = new DateFormat('MMM dd, yyyy');

  @override
  void initState() {
    // TODO: implement initState
    super.initState();

    getStream();
  }

  void getStream() {
    setState(() {
      isLoading = true;
    });

    Query query = Firestore.instance
        .collection('rentals')
        .where('item',
            isEqualTo: Firestore.instance
                .collection('items')
                .document(widget.itemDS.documentID))
        .where('ownerReviewSubmitted', isEqualTo: true);

    switch (filter) {
      case SortByFilter.recent:
        filterText = 'Recent';
        query = query.orderBy('lastUpdateTime', descending: true);
        break;
      case SortByFilter.highToLow:
        filterText = 'High to low';
        query = query.orderBy('ownerReview.average', descending: true);
        break;
    }

    stream = query.snapshots();

    if (stream != null) {
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: isLoading ? Container() : allReviewsPage(),
    );
  }

  Widget allReviewsPage() {
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
              Text('All reviews for ${widget.itemDS['name']}',
                  style: TextStyle(fontFamily: 'Quicksand', fontSize: 18.0)),
            ],
          ),
          Container(height: 5),
          sortBySelector(),
          Container(height: 5),
          buildReviewsList(),
        ],
      ),
    );
  }

  Widget sortBySelector() {
    String hint = 'Sort by: $filterText';

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
            isDense: true,
            hint: Text(
              hint,
              style: TextStyle(fontFamily: font, fontWeight: FontWeight.w500),
            ),
            onChanged: (value) {
              switch (value) {
                case 'Recent':
                  filter = SortByFilter.recent;
                  break;
                case 'Rating high to low':
                  filter = SortByFilter.highToLow;
                  break;
              }

              getStream();
            },
            items: [
              'Recent',
              'Rating high to low',
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

  Widget buildReviewsList() {
    return Expanded(
      child: StreamBuilder(
        stream: stream,
        builder: (BuildContext context, AsyncSnapshot snapshot) {
          switch (snapshot.connectionState) {
            case ConnectionState.waiting:
            default:
              if (snapshot.hasData) {
                List snaps = snapshot.data.documents;
                List<Widget> reviews = [];

                snaps.forEach((var snap) {
                  Map renter = snap['renterData'];
                  Map customerReview = snap['ownerReview'];

                  reviews.add(reviewTile(
                      renter['avatar'],
                      renter['name'],
                      customerReview['overall'].toDouble(),
                      customerReview['reviewNote'],
                      snap['lastUpdateTime'].toDate()));
                });

                return reviews.isNotEmpty
                    ? ListView(
                        shrinkWrap: true,
                        padding: const EdgeInsets.all(20.0),
                        children: reviews,
                      )
                    : Center(
                        child: Text('No results'),
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
