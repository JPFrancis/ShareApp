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

  ProfilePage({Key key}) : super(key: key);

  @override
  State<StatefulWidget> createState() {
    return ProfilePageState();
  }
}

class ProfilePageState extends State<ProfilePage>
    with SingleTickerProviderStateMixin {
  CurrentUser currentUser;
  User user;
  List<DocumentSnapshot> searchList;
  TextEditingController searchController = TextEditingController();
  bool isLoading = false;
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
    user = User.getModel(context);
    tabController = TabController(vsync: this, length: myTabs.length);
  }

  Future<Null> getSnapshots() async {
    DocumentSnapshot snap =
        await Firestore.instance.collection('users').document(user.id).get();

    if (snap != null) {
      setState(() {
        user = User(snap);
      });
    }
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
        SizedBox(height: 20.0),
        showUserDescription(),
        showUserRating(),
        Container(
          padding: EdgeInsets.only(
            left: pageWidth * 0.04,
            top: pageHeight * 0.02,
          ),
          child: Text(
            'Reviews',
            style: TextStyle(
              fontFamily: appFont,
              fontSize: 20,
              fontWeight: FontWeight.w500,
              color: Colors.black87,
            ),
          ),
        ),
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
              reviewsList(user.id, ReviewType.fromRenters),
              reviewsList(user.id, ReviewType.fromOwners),
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
    Map renterRatingMap = {}..addAll(user.renterRating);
    Map ownerRatingMap = {}..addAll(user.ownerRating);

    if (renterRatingMap['count'] > 0) {
      renterRating = renterRatingMap['total'] / renterRatingMap['count'];
    }

    if (ownerRatingMap['count'] > 0) {
      ownerRating = ownerRatingMap['total'] / ownerRatingMap['count'];
    }

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text('Renter rating'),
          StarRating(
            rating: renterRating,
          ),
          Text('Owner rating'),
          StarRating(
            rating: ownerRating,
          ),
        ],
      ),
    );
  }

  Widget showUserDescription() {
    bool empty = user.description.isEmpty ? true : false;
    String desc = user.description.isEmpty
        ? "The user hasn't added a description yet!"
        : user.description;
    return Column(
      children: <Widget>[
        Align(alignment: Alignment.topLeft, child: Icon(QuoteIcons.quote_left)),
        SizedBox(height: 10.0),
        Text("$desc",
            style: TextStyle(
                fontSize: MediaQuery.of(context).size.width / 25,
                fontFamily: appFont,
                color: empty ? Colors.grey : Colors.black54)),
        SizedBox(height: 10.0),
        Align(
            alignment: Alignment.bottomRight,
            child: Icon(QuoteIcons.quote_right)),
      ],
    );
  }

  Widget showNameAndProfilePic() {
    double h = MediaQuery.of(context).size.height;
    double w = MediaQuery.of(context).size.width;
    double statusBarHeight = MediaQuery.of(context).padding.top;

    String name = user.name.trim();
    String firstName = name.split(' ')[0];

    return Stack(
      children: <Widget>[
        Container(
            decoration: new BoxDecoration(
              image: DecorationImage(
                image: CachedNetworkImageProvider(user.avatar),
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
              size: 28,
              color: Colors.white,
            ),
            onSelected: (value) {
              if (value == 'report') {
                showReportUserDialog(
                  context: context,
                  reporter: currentUser,
                  offender: user,
                );
              }
            },
            itemBuilder: (BuildContext context) => <PopupMenuItem<String>>[
              const PopupMenuItem<String>(
                value: 'report',
                child: Text('Report user'),
              ),
            ],
          ),
        ),
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
                isEqualTo:
                    Firestore.instance.collection('users').document(user.id))
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
