import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:shareapp/extras/helpers.dart';
import 'package:shareapp/main.dart';
import 'package:shareapp/models/current_user.dart';
import 'package:shareapp/rentals/rental_detail.dart';
import 'package:shareapp/services/const.dart';
import 'package:timeago/timeago.dart' as timeago;

class TransactionsPage extends StatefulWidget {
  static const routeName = '/transactionsPage';
  final RentalPhase filter;
  final String person;

  TransactionsPage({Key key, this.filter, this.person}) : super(key: key);

  @override
  State<StatefulWidget> createState() {
    return TransactionsPageState();
  }
}

class TransactionsPageState extends State<TransactionsPage> {
  CurrentUser currentUser;

  Stream stream;
  String rentalStatus = '';
  RentalPhase rentalPhase;
  String person;

  bool isLoading = true;
  String font = 'Quicksand';

  @override
  void initState() {
    super.initState();

    currentUser = CurrentUser.getModel(context);
    rentalPhase = widget.filter;
    person = widget.person;

    getStream();
  }

  void getStream() {
    setState(() {
      isLoading = true;
    });

    Query query = Firestore.instance.collection('rentals').where(person,
        isEqualTo:
            Firestore.instance.collection('users').document(currentUser.id));

    switch (rentalPhase) {
      case RentalPhase.requesting:
        rentalStatus = 'requesting';
        query = query.where('requesting', isEqualTo: true);
        break;
      case RentalPhase.upcoming:
        rentalStatus = 'upcoming';
        query = query
            .where('status', isEqualTo: 2)
            .where('pickupStart', isGreaterThan: DateTime.now())
            .orderBy('pickupStart', descending: false)
            .limit(3);
        break;
      case RentalPhase.current:
        rentalStatus = 'current';
        query = query
            .where('status', isEqualTo: 3)
            .where('rentalEnd', isGreaterThan: DateTime.now())
            .limit(3);
        break;
      case RentalPhase.past:
        rentalStatus = 'past';
        query = query
            .where('rentalEnd', isLessThan: DateTime.now())
            .orderBy('rentalEnd', descending: true)
            .limit(3);
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
      appBar: AppBar(
        title: Text('Transactions'),
      ),
      body: isLoading ? Container() : showBody(),
    );
  }

  Widget showBody() {
    return Container(
      padding: EdgeInsets.all(15),
      child: Column(
        children: <Widget>[
          Text('Showing rentals where you are the item $person'),
          Container(height: 15),
          Text('Showing rentals with status $rentalStatus'),
          Container(height: 15),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: <Widget>[
              ownerRenterSelector(),
              rentalStatusSelector(),
            ],
          ),
          Container(height: 15),
          Expanded(
            child: buildRentals(),
          )
        ],
      ),
    );
  }

  Widget ownerRenterSelector() {
    String hint = 'Role: $person';

    return DropdownButtonHideUnderline(
      child: DropdownButton<String>(
          isDense: true,
          hint: Text(
            hint,
            style: TextStyle(fontFamily: font, fontWeight: FontWeight.w500),
          ),
          onChanged: (value) {
            switch (value) {
              case 'Owner':
                person = 'owner';
                break;
              case 'Renter':
                person = 'renter';
                break;
            }

            getStream();
          },
          items: [
            'Owner',
            'Renter',
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
    );
  }

  Widget rentalStatusSelector() {
    String hint = 'Rental status: $rentalStatus';

    return DropdownButtonHideUnderline(
      child: DropdownButton<String>(
          isDense: true,
          hint: Text(
            hint,
            style: TextStyle(fontFamily: font, fontWeight: FontWeight.w500),
          ),
          onChanged: (value) {
            switch (value) {
              case 'Requesting':
                rentalPhase = RentalPhase.requesting;
                break;
              case 'Upcoming':
                rentalPhase = RentalPhase.upcoming;
                break;
              case 'Current':
                rentalPhase = RentalPhase.current;
                break;
              case 'Past':
                rentalPhase = RentalPhase.past;
                break;
            }

            getStream();
          },
          items: [
            'Requesting',
            'Upcoming',
            'Current',
            'Past',
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
    );
  }

  Widget buildRentals() {
    return StreamBuilder<QuerySnapshot>(
      stream: stream,
      builder: (BuildContext context, AsyncSnapshot<QuerySnapshot> snapshot) {
        if (snapshot.hasError) {
          return new Text('${snapshot.error}');
        }
        switch (snapshot.connectionState) {
          case ConnectionState.waiting:

          default:
            if (snapshot.hasData) {
              var updated = snapshot.data.documents.toList();
              return ListView.builder(
                padding: EdgeInsets.symmetric(horizontal: 10.0),
                shrinkWrap: true,
                physics: NeverScrollableScrollPhysics(),
                itemCount: updated.length,
                itemBuilder: (context, index) {
                  DocumentSnapshot rentalDS = updated[index];
                  DocumentReference itemDR = rentalDS['item'];

                  return StreamBuilder<DocumentSnapshot>(
                    stream: itemDR.snapshots(),
                    builder: (BuildContext context,
                        AsyncSnapshot<DocumentSnapshot> snapshot) {
                      if (snapshot.hasError) {
                        return new Text('${snapshot.error}');
                      }
                      switch (snapshot.connectionState) {
                        case ConnectionState.waiting:

                        default:
                          if (snapshot.hasData) {
                            DocumentSnapshot itemDS = snapshot.data;
                            int durationDays = rentalDS['duration'];
                            String duration =
                                '${durationDays > 1 ? '$durationDays days' : '$durationDays day'}';

                            return StreamBuilder<DocumentSnapshot>(
                              stream: person == "renter"
                                  ? rentalDS["owner"].snapshots()
                                  : rentalDS["renter"].snapshots(),
                              builder: (BuildContext context,
                                  AsyncSnapshot<DocumentSnapshot> snapshot) {
                                if (snapshot.hasError) {
                                  return new Text('${snapshot.error}');
                                }
                                switch (snapshot.connectionState) {
                                  case ConnectionState.waiting:

                                  default:
                                    if (snapshot.hasData) {
                                      DocumentSnapshot otherUserDS =
                                          snapshot.data;
                                      int status = rentalDS['status'];
                                      bool isRenter =
                                          person == 'renter' ? true : false;

                                      CustomBoxShadow cbs =
                                          (isRenter && status == 1) ||
                                                  (!isRenter && status == 0)
                                              ? CustomBoxShadow(
                                                  color: primaryColor,
                                                  blurRadius: 6.0,
                                                  blurStyle: BlurStyle.outer)
                                              : CustomBoxShadow(
                                                  color: Colors.black38,
                                                  blurRadius: 3.0,
                                                  blurStyle: BlurStyle.outer);

                                      return Column(
                                        children: <Widget>[
                                          Container(
                                            decoration: new BoxDecoration(
                                              image: DecorationImage(
                                                image:
                                                    CachedNetworkImageProvider(
                                                        itemDS['images'][0]),
                                                fit: BoxFit.cover,
                                                colorFilter:
                                                    new ColorFilter.mode(
                                                        Colors.black
                                                            .withOpacity(0.45),
                                                        BlendMode.srcATop),
                                              ),
                                              boxShadow: <BoxShadow>[cbs],
                                            ),
                                            child: InkWell(
                                              onTap: () {
                                                Navigator.pushNamed(context,
                                                    RentalDetail.routeName,
                                                    arguments: RentalDetailArgs(
                                                        rentalDS.documentID,
                                                        currentUser));
                                              },
                                              child: Row(
                                                mainAxisAlignment:
                                                    MainAxisAlignment
                                                        .spaceAround,
                                                children: <Widget>[
                                                  Column(
                                                    children: <Widget>[
                                                      SizedBox(
                                                        height: 6.0,
                                                      ),
                                                      Container(
                                                          height: 30,
                                                          width: 30,
                                                          decoration: BoxDecoration(
                                                              shape: BoxShape
                                                                  .circle,
                                                              color:
                                                                  Colors.white,
                                                              image: DecorationImage(
                                                                  image: CachedNetworkImageProvider(
                                                                      otherUserDS[
                                                                          'avatar']),
                                                                  fit: BoxFit
                                                                      .fill))),
                                                      Text(
                                                        otherUserDS['name'],
                                                        style: TextStyle(
                                                            color: Colors.white,
                                                            fontFamily:
                                                                'Quicksand',
                                                            fontWeight:
                                                                FontWeight
                                                                    .bold),
                                                      ),
                                                    ],
                                                  ),
                                                  Column(
                                                    children: <Widget>[
                                                      Row(children: <Widget>[
                                                        Text("Request Sent: ",
                                                            style: TextStyle(
                                                                color: Colors
                                                                    .white,
                                                                fontFamily:
                                                                    'Quicksand')),
                                                        Text(
                                                          timeago.format(
                                                              rentalDS[
                                                                      'created']
                                                                  .toDate()),
                                                          style: TextStyle(
                                                              color:
                                                                  Colors.white,
                                                              fontFamily:
                                                                  'Quicksand',
                                                              fontWeight:
                                                                  FontWeight
                                                                      .bold),
                                                        )
                                                      ]),
                                                      Row(
                                                        children: <Widget>[
                                                          Text(
                                                            "Requested Duration: ",
                                                            style: TextStyle(
                                                                color: Colors
                                                                    .white,
                                                                fontFamily:
                                                                    'Quicksand'),
                                                          ),
                                                          Text(duration,
                                                              style: TextStyle(
                                                                  color: Colors
                                                                      .white,
                                                                  fontFamily:
                                                                      'Quicksand',
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .bold))
                                                        ],
                                                      )
                                                    ],
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                          SizedBox(height: 5.0)
                                        ],
                                      );
                                    } else {
                                      return Container();
                                    }
                                }
                              },
                            );
                          } else {
                            return Container(
                              color: Colors.pink,
                            );
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
    );
  }
}
