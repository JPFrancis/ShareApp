import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class AllReviews extends StatefulWidget {
  static const routeName = '/allReviews';
  final DocumentSnapshot itemDS;

  AllReviews({Key key, this.itemDS}) : super(key: key);

  @override
  State<StatefulWidget> createState() {
    return AllReviewsState();
  }
}

class AllReviewsState extends State<AllReviews> {
  bool isLoading = true;

  @override
  void initState() {
    // TODO: implement initState
    super.initState();

    delayPage();
  }

  void delayPage() async {
    Future.delayed(Duration(milliseconds: 750)).then((_) {
      setState(() {
        isLoading = false;
      });
    });
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
          buildReviewsList(),
        ],
      ),
    );
  }

  Widget buildReviewsList() {
    return Expanded(
      child: StreamBuilder<QuerySnapshot>(
        stream: Firestore.instance
            .collection('rentals')
            .where('item',
                isEqualTo: Firestore.instance
                    .collection('items')
                    .document(widget.itemDS.documentID))
            .orderBy('review', descending: false)
            .snapshots(),
        builder: (BuildContext context, AsyncSnapshot<QuerySnapshot> snapshot) {
          switch (snapshot.connectionState) {
            case ConnectionState.waiting:
            default:
              if (snapshot.hasData) {
                return new ListView.builder(
                  shrinkWrap: true,
                  padding: EdgeInsets.symmetric(horizontal: 15),
                  itemCount: snapshot.data.documents.length,
                  itemBuilder: (context, index) {
                    DocumentSnapshot rentalDS = snapshot.data.documents[index];
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

                              return ListTile(
                                leading: Icon(Icons.rate_review),
                                title: Text(
                                  '${review['reviewNote']}',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                                subtitle:
                                    Text('Written by: ${reviewerDS['name']}'),
                              );
                            } else {
                              return Container();
                            }
                        }
                      },
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

  void goBack() {
    Navigator.pop(context);
  }
}
