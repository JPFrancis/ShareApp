import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:shareapp/extras/helpers.dart';
import 'package:shareapp/main.dart';
import 'package:shareapp/rentals/rental_detail.dart';
import 'package:shareapp/services/const.dart';

class MyReviews extends StatefulWidget {
  static const routeName = '/myReviews';

  MyReviews({Key key}) : super(key: key);

  @override
  State<StatefulWidget> createState() {
    return MyReviewsState();
  }
}

class MyReviewsState extends State<MyReviews> {
  String appBarTitle = 'Payments and payouts';
  double padding = 5.0;
  String myUserID;
  String defaultSource = '';
  String stripeCustId = '';
  int numCards = 0;

  bool isLoading = true;
  bool stripeInit = false;

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    getMyUserID();
    //delayPage();
  }

  void delayPage() async {
    Future.delayed(Duration(milliseconds: 750)).then((_) {
      setState(() {
        isLoading = false;
      });
    });
  }

  void getMyUserID() async {
    FirebaseAuth.instance.currentUser().then((user) {
      myUserID = user.uid;
      delayPage();
    });
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: coolerWhite,
        appBar: PreferredSize(
          preferredSize: Size.fromHeight(90),
          child: AppBar(
            leading: IconButton(
              icon: Icon(Icons.close),
              onPressed: () => Navigator.pop(context),
            ),
            bottom: TabBar(
              indicatorColor: Colors.black,
              tabs: [
                Tab(child: Text(fromRentersTabText)),
                Tab(child: Text(fromOwnersTabText)),
              ],
            ),
          ),
        ),
        body: isLoading
            ? Center(
                child: CircularProgressIndicator(),
              )
            : TabBarView(
                children: [
                  reviewsList(myUserID, ReviewType.fromRenters),
                  reviewsList(myUserID, ReviewType.fromOwners),
                ],
              ),
      ),
    );
  }

  Widget showCreditCards() {
    double w = MediaQuery.of(context).size.width;

    return StreamBuilder(
      stream:
          Firestore.instance.collection('users').document(myUserID).snapshots(),
      builder:
          (BuildContext context, AsyncSnapshot<DocumentSnapshot> snapshot) {
        switch (snapshot.connectionState) {
          case ConnectionState.waiting:
          default:
            DocumentSnapshot ds = snapshot.data;

            if (ds != null && ds.exists) {
              defaultSource = ds['defaultSource'];
              stripeCustId = ds['custId'];
            }

            return StreamBuilder(
              stream: Firestore.instance
                  .collection('users')
                  .document(myUserID)
                  .collection('sources')
                  .snapshots(),
              builder: (BuildContext context,
                  AsyncSnapshot<QuerySnapshot> snapshot) {
                if (snapshot.hasError) {
                  return new Text('${snapshot.error}');
                }

                switch (snapshot.connectionState) {
                  case ConnectionState.waiting:
                    return Container();
                  default:
                    List documents = snapshot.data.documents;
                    numCards = documents.length;

                    return ListView.builder(
                      shrinkWrap: true,
                      itemCount: documents.length + 1,
                      itemBuilder: (context, index) {
                        if (index == documents.length) {
                          return Column(
                            children: <Widget>[
                              Container(height: 10),
                              Container(height: 10),
                            ],
                          );
                        } else {
                          return Column(
                            children: <Widget>[
                              Container(height: 10),
                            ],
                          );
                        }
                      },
                    );
                }
              },
            );
        }
      },
    );
  }

  Widget showPayouts() {
    return Column(
      children: <Widget>[
        buildChargesList(),
        //buildTransactions("past", "renter"),
        //buildTransactions("past", "owner"),
      ],
    );
  }

  Widget buildChargesList() {
    return Expanded(
      child: StreamBuilder<QuerySnapshot>(
        stream: Firestore.instance
            .collection('charges')
            .where('status', isEqualTo: 'succeeded')
            .orderBy('timestamp', descending: true)
            .snapshots(),
        builder: (BuildContext context, AsyncSnapshot<QuerySnapshot> snapshot) {
          if (snapshot.hasError) {
            return new Text('${snapshot.error}');
          }
          switch (snapshot.connectionState) {
            case ConnectionState.waiting:
              return Center(
                child: new Container(),
              );
            default:
              if (snapshot.hasData) {
                List<DocumentSnapshot> docs = snapshot.data.documents;

                return ListView.builder(
                    itemCount: docs.length,
                    itemBuilder: (context, index) {
                      DocumentSnapshot ds = docs[index];
                      double amount = ds['amount'] / 100;

                      return ListTile(
                        title: Text(
                          '\$${amount.toStringAsFixed(0)}',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text('${ds['description']}'),
                      );
                    });
              } else {
                return Container();
              }
          }
        },
      ),
    );
  }

  Widget buildTransactions(String rentalStatus, person) {
    List status;
    switch (rentalStatus) {
      case 'upcoming':
        status = [2];
        break;
      case 'current':
        status = [3, 4];
        break;
      case 'past':
        status = [5];
        break;
    }
    CollectionReference collectionReference =
        Firestore.instance.collection('rentals');
    Stream stream = collectionReference
        .where(person,
            isEqualTo:
                Firestore.instance.collection('users').document(myUserID))
        .snapshots();
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
                var updated = snapshot.data.documents
                    .where((d) => status.contains(d['status']))
                    .toList();
                var items = updated.map((rentalDS) {
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
                            DocumentSnapshot ds = snapshot.data;

                            return StreamBuilder<DocumentSnapshot>(
                              stream: rentalDS['renter'].snapshots(),
                              builder: (BuildContext context,
                                  AsyncSnapshot<DocumentSnapshot> snapshot) {
                                if (snapshot.hasError) {
                                  return new Text('${snapshot.error}');
                                }
                                switch (snapshot.connectionState) {
                                  case ConnectionState.waiting:

                                  default:
                                    if (snapshot.hasData) {
                                      DocumentSnapshot renterDS = snapshot.data;
                                      CachedNetworkImage image =
                                          CachedNetworkImage(
                                        key: ValueKey<String>(ds['images'][0]),
                                        imageUrl: ds['images'][0],
                                        placeholder: (context, url) =>
                                            new CircularProgressIndicator(),
                                        fit: BoxFit.cover,
                                      );

                                      return Container(
                                        child: InkWell(
                                          onTap: () => Navigator.pushNamed(
                                              context, RentalDetail.routeName,
                                              arguments: RentalDetailArgs(
                                                  rentalDS.documentID)),
                                          child: Container(
                                            decoration: BoxDecoration(
                                              boxShadow: <BoxShadow>[
                                                CustomBoxShadow(
                                                    color: Colors.black45,
                                                    blurRadius: 3.5,
                                                    blurStyle: BlurStyle.outer),
                                              ],
                                            ),
                                            child: Stack(
                                              children: <Widget>[
                                                SizedBox.expand(child: image),
                                                SizedBox.expand(
                                                    child: Container(
                                                  color: Colors.black
                                                      .withOpacity(0.4),
                                                )),
                                                Center(
                                                  child: Column(
                                                    children: <Widget>[
                                                      Text(ds['name'],
                                                          style: TextStyle(
                                                              color: Colors
                                                                  .white)),
                                                      // Text("Pickup Time: \n" + DateTime.fromMillisecondsSinceEpoch(rentalDS[ 'pickupStart'].millisecondsSinceEpoch).toString(), style: TextStyle(color:Colors.white)),
                                                    ],
                                                  ),
                                                )
                                              ],
                                            ),
                                          ),
                                        ),
                                      );
                                      // return Container(width: MediaQuery.of(context).size.width/2, padding: EdgeInsets.only(left: 10.0), child: _tile());
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
                });

                return GridView.count(
                  padding: EdgeInsets.all(10.0),
                  mainAxisSpacing: 10,
                  shrinkWrap: true,
                  crossAxisCount: 2,
                  crossAxisSpacing: 10,
                  children: items.toList(),
                );
              } else {
                return Container();
              }
          }
        },
      ),
    );
  }
}
