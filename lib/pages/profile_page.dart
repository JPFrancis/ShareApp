import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shareapp/extras/helpers.dart';
import 'package:shareapp/extras/quote_icons.dart';
import 'package:shareapp/services/const.dart';

class ProfilePage extends StatefulWidget {
  static const routeName = '/profilePage';

  final String userID;

  ProfilePage({Key key, this.userID}) : super(key: key);

  @override
  State<StatefulWidget> createState() {
    return ProfilePageState();
  }
}

class ProfilePageState extends State<ProfilePage> {
  DocumentSnapshot userDS;
  List<DocumentSnapshot> searchList;
  TextEditingController searchController = TextEditingController();
  bool isLoading = true;

  @override
  void initState() {
    // TODO: implement initState
    super.initState();

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
    bool empty = userDS['description']
        .toString()
        .isEmpty ? true : false;
    String desc = userDS['description']
        .toString()
        .isEmpty
        ? "The user hasn't added a description yet!"
        : userDS['description'];
    return Column(
      children: <Widget>[
        Align(alignment: Alignment.topLeft, child: Icon(QuoteIcons.quote_left)),
        SizedBox(height: 10.0),
        Text("$desc",
            style: TextStyle(
                fontSize: MediaQuery
                    .of(context)
                    .size
                    .width / 25,
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
    double h = MediaQuery
        .of(context)
        .size
        .height;
    double w = MediaQuery
        .of(context)
        .size
        .width;

    return Container(
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
            '${userDS['name']}',
            style: TextStyle(
              color: Colors.white,
              fontSize: h / 20,
              fontFamily: 'Quicksand',
            ),
          ),
        ));
  }

  Widget showItems() {
    double h = MediaQuery
        .of(context)
        .size
        .height;
    double w = MediaQuery
        .of(context)
        .size
        .width;

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
                        width: w / 2.2, child: itemCard(itemDS, context));
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
