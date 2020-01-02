import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:scoped_model/scoped_model.dart';
import 'package:shareapp/extras/helpers.dart';
import 'package:shareapp/extras/quote_icons.dart';
import 'package:shareapp/models/current_user.dart';
import 'package:shareapp/models/user.dart';
import 'package:shareapp/services/const.dart';
import 'package:shareapp/services/functions.dart';

class ProfilePage extends StatefulWidget {
  static const routeName = '/profilePage';

  final String userID;

  ProfilePage({Key key, this.userID}) : super(key: key);

  @override
  State<StatefulWidget> createState() {
    return ProfilePageState();
  }
}

class ProfilePageState extends State<ProfilePage>
    with SingleTickerProviderStateMixin {
  CurrentUser currentUser;
  DocumentSnapshot userDS;
  List<DocumentSnapshot> searchList;
  TextEditingController searchController = TextEditingController();
  bool isLoading = true;
  TabController tabController;

  final List<Tab> myTabs = <Tab>[
    Tab(text: fromRentersTabText),
    Tab(text: fromOwnersTabText),
  ];

  double pageHeight;
  double pageWidth;

  @override
  void initState() {
    // TODO: implement initState
    super.initState();

    currentUser = CurrentUser.getModel(context);
    tabController = TabController(vsync: this, length: myTabs.length);
    getSnapshots();
  }

  Future<Null> getSnapshots() async {
    DocumentSnapshot ds = await Firestore.instance
        .collection('users')
        .document(widget.userID)
        .get();

    if (ds != null) {
      userDS = ds;

      delayPage();
    }
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
    double statusBarHeight = MediaQuery.of(context).padding.top;
    pageHeight = MediaQuery.of(context).size.height - statusBarHeight;
    pageWidth = MediaQuery.of(context).size.width;

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
      body: RefreshIndicator(
        onRefresh: () => getSnapshots(),
        child: isLoading ? Container() : showBody(),
      ),
    );
  }

  Widget showBody() {
    return ListView(
      padding: EdgeInsets.all(0),
      children: <Widget>[
        showNameAndProfilePic(),
        userDS['description'].toString().isEmpty ? Container() : showUserDescription(),
        reusableCategory("RATINGS"),
        showUserRating(),
        reusableCategory("REVIEWS"),
        Container(
          height: 50,
          padding: EdgeInsets.symmetric(horizontal: pageWidth * 0.04),
          child: AppBar(
            automaticallyImplyLeading: false,
            primary: false,
            elevation: 0,
            backgroundColor: Colors.transparent,
            bottom: TabBar(
              labelColor: primaryColor,
              controller: tabController,
              indicatorColor: primaryColor,
              unselectedLabelColor: Colors.black87,
              tabs: myTabs,
            ),
          ),
        ),
        Container(
          height: pageHeight * 0.3,
          child: TabBarView(
            controller: tabController,
            children: <Widget>[
              reviewsList(widget.userID, ReviewType.fromRenters),
              reviewsList(widget.userID, ReviewType.fromOwners),
            ],
          ),
        ),
        divider(),
        reusableCategory("ITEMS"),
        SizedBox(height: 10.0),
        showItems(),
      ],
    );
  }

  Widget showUserRating() {
    double renterRating = 0;
    double ownerRating = 0;
    Map renterRatingMap = userDS['renterRating'];
    Map ownerRatingMap = userDS['ownerRating'];

    if (renterRatingMap['count'] > 0) {
      renterRating = renterRatingMap['total'] / renterRatingMap['count'];
    }

    if (ownerRatingMap['count'] > 0) {
      ownerRating = ownerRatingMap['total'] / ownerRatingMap['count'];
    }

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 20, vertical: 5.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: <Widget>[
            Text('Renter rating', style: TextStyle(fontFamily: appFont, fontSize: 15),),
            StarRating(rating: renterRating,),
          ],),
          Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: <Widget>[
            Text('Owner rating', style: TextStyle(fontFamily: appFont, fontSize: 15),),
            StarRating(rating: ownerRating,),
          ],),
        ],
      ),
    );
  }

  Widget showUserDescription() {
    String desc = userDS['description'];
    return Padding(
      padding: const EdgeInsets.only(left: 15.0, right: 15.0, bottom: 5.0, top: 10.0),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
        Text("Joined in 2020", style: TextStyle(fontSize: MediaQuery.of(context).size.width / 25, fontFamily: appFont, fontWeight: FontWeight.bold)),
        SizedBox(height: 5.0),
        Text("$desc", style: TextStyle(fontSize: MediaQuery.of(context).size.width / 25, fontFamily: appFont)),
      ],),
    );
  }

  Widget showNameAndProfilePic() {
    double h = MediaQuery.of(context).size.height;
    double w = MediaQuery.of(context).size.width;
    double statusBarHeight = MediaQuery.of(context).padding.top;

    String name = '${userDS['name']}'.trim();
    String firstName = name.split(' ')[0];

    return Stack(
      children: <Widget>[
        Container(
            decoration: new BoxDecoration(
              image: DecorationImage(
                image: CachedNetworkImageProvider(userDS['avatar']),
                fit: BoxFit.fill,
                colorFilter: new ColorFilter.mode(
                    Colors.black.withOpacity(0.35), BlendMode.srcATop),
              ),
            ),
            height: w,
            child: Align(
              alignment: Alignment.bottomLeft,
              child: Text(
                firstName,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: h / 20,
                  fontFamily: 'Quicksand',
                ),
              ),
            )),
        Positioned(
          top: statusBarHeight,
          right: 0,
          child: PopupMenuButton<String>(
            icon: Icon(
              Icons.more_vert,
              color: Colors.white,
            ),
            onSelected: (value) {
              if (value == 'report') {
                showReportUserDialog(
                    context: context,
                    myId: currentUser.id,
                    myName: currentUser.name,
                    offenderId: userDS.documentID,
                    offenderName: userDS['name']);
              }
            },
            itemBuilder: (BuildContext context) => <PopupMenuItem<String>>[
              const PopupMenuItem<String>(
                value: 'report',
                child: Text('Report user'),
              ),
            ],
          ),
        )
      ],
    );
  }

  Widget showItems() {
    double h = MediaQuery.of(context).size.height;
    double w = MediaQuery.of(context).size.width;

    return Container(
      height: h / 3.2,
      child: StreamBuilder(
        stream: Firestore.instance
            .collection('items')
            .where('creator',
                isEqualTo: Firestore.instance
                    .collection('users')
                    .document(userDS.documentID))
            .snapshots(),
        builder: (BuildContext context, AsyncSnapshot<QuerySnapshot> snapshot) {
          if (snapshot.hasError) {
            return new Text('${snapshot.error}');
          }

          switch (snapshot.connectionState) {
            case ConnectionState.waiting:

            default:
              if (snapshot.hasData) {
                List<DocumentSnapshot> itemSnaps = snapshot.data.documents;

                return ListView.builder(
                  scrollDirection: Axis.horizontal,
                  shrinkWrap: true,
                  itemCount: itemSnaps.length,
                  itemBuilder: (context, index) {
                    DocumentSnapshot itemDS = itemSnaps[index];
                    return Container(
                        width: w / 2.2,
                        child: ScopedModel<User>(
                          model: currentUser,
                          child: itemCard(itemDS, context),
                        ));
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
