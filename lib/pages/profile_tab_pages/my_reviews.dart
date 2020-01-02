import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:shareapp/extras/helpers.dart';
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
            title: Text('My Reviews', style: TextStyle(fontFamily: appFont),),
            centerTitle: true,
            bottom: TabBar(
              indicatorColor: Colors.black,
              tabs: [
                Tab(child: Text(fromRentersTabText, style: TextStyle(fontFamily: appFont),)),
                Tab(child: Text(fromOwnersTabText, style: TextStyle(fontFamily: appFont),)),
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
}
