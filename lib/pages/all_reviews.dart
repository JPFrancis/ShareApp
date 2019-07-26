import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
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

  void delayPage() async {
    Future.delayed(Duration(milliseconds: 750)).then((_) {
      setState(() {
        isLoading = false;
      });
    });
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
        .where('submittedReview', isEqualTo: true);

    switch (filter) {
      case SortByFilter.recent:
        filterText = 'Recent';
        query = query.orderBy('lastUpdateTime', descending: true);
        break;
      case SortByFilter.highToLow:
        filterText = 'High to low';
        query = query.orderBy('review.average', descending: true);
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
      child: StreamBuilder<QuerySnapshot>(
        stream: stream,
        builder: (BuildContext context, AsyncSnapshot<QuerySnapshot> snapshot) {
          switch (snapshot.connectionState) {
            case ConnectionState.waiting:
            default:
              if (snapshot.hasData) {
                return Padding(
                  padding: EdgeInsets.all(10),
                  child: ListView.builder(
                    shrinkWrap: true,
                    padding: EdgeInsets.symmetric(horizontal: 15),
                    itemCount: snapshot.data.documents.length,
                    itemBuilder: (context, index) {
                      DocumentSnapshot rentalDS =
                          snapshot.data.documents[index];
                      Map review = rentalDS['review'];

                      return StreamBuilder<DocumentSnapshot>(
                        stream: rentalDS['renter'].snapshots(),
                        builder: (BuildContext context,
                            AsyncSnapshot<DocumentSnapshot> snapshot) {
                          switch (snapshot.connectionState) {
                            case ConnectionState.waiting:

                            default:
                              if (snapshot.hasData) {
                                DocumentSnapshot reviewerDS = snapshot.data;

                                return Container(
                                  child: Column(
                                    children: <Widget>[
                                      Row(
                                        children: <Widget>[
                                          Container(
                                            height: 40.0,
                                            child: ClipOval(
                                              child: CachedNetworkImage(
                                                imageUrl: reviewerDS['avatar'],
                                                placeholder: (context, url) =>
                                                    CircularProgressIndicator(),
                                              ),
                                            ),
                                          ),
                                          SizedBox(width: 5),
                                          Text(
                                            reviewerDS['name'],
                                            style: TextStyle(
                                                fontFamily: 'Quicksand',
                                                fontWeight: FontWeight.bold),
                                          ),
                                          Container(width: 5),
                                          StarRating(
                                              rating: rentalDS['review']
                                                      ['average']
                                                  .toDouble()),
                                        ],
                                      ),
                                      Container(
                                          padding: EdgeInsets.only(left: 45.0),
                                          alignment: Alignment.centerLeft,
                                          child: Text(
                                              rentalDS['review']['reviewNote'],
                                              style: TextStyle(
                                                  fontFamily: 'Quicksand'))),
                                      Container(
                                          padding: EdgeInsets.only(left: 45.0),
                                          alignment: Alignment.centerLeft,
                                          child: Text(
                                              '${dateFormat.format(rentalDS['lastUpdateTime'].toDate())}',
                                              style: TextStyle(
                                                  fontFamily: 'Quicksand'))),
                                      Container(height: 10),
                                    ],
                                  ),
                                );
                              } else {
                                return Container();
                              }
                          }
                        },
                      );
                    },
                  ),
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
