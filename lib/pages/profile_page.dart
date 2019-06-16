import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class ProfilePage extends StatefulWidget {
  static const routeName = '/profilePage';

  final DocumentSnapshot initUserDS;

  ProfilePage({Key key, this.initUserDS}) : super(key: key);

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

    userDS = widget.initUserDS;
    getSnapshots(false);
  }

  Future<Null> getSnapshots(bool refreshItemDS) async {
    DocumentSnapshot ds = refreshItemDS
        ? await Firestore.instance
            .collection('users')
            .document(userDS.documentID)
            .get()
        : userDS;

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
      appBar: AppBar(
        title: Text('${userDS['name']}'),
      ),
      body: RefreshIndicator(
        onRefresh: () => getSnapshots(true),
        child: isLoading ? Container() : showBody(),
      ),
    );
  }

  Widget showBody() {
    return Padding(
      padding: EdgeInsets.all(15),
      child: ListView(
        children: <Widget>[
          showNameAndProfilePic(),
          Text('Items'),
          showItems(),
        ],
      ),
    );
  }

  Widget showNameAndProfilePic() {
    return SizedBox(
        child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: <Widget>[
        Text(
          '${userDS['name']}',
          style: TextStyle(
            color: Colors.black,
            fontSize: 20.0,
            fontFamily: 'Quicksand',
          ),
          textAlign: TextAlign.left,
        ),
        Container(
          height: 50.0,
          child: ClipOval(
            child: CachedNetworkImage(
              imageUrl: userDS['avatar'],
              placeholder: (context, url) => CircularProgressIndicator(),
            ),
          ),
        ),
      ],
    ));
  }

  Widget showItems() {
    return Container(
      height: 100,
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
                double h = 100;
                double w = 200;

                return ListView.builder(
                  scrollDirection: Axis.horizontal,
                  shrinkWrap: true,
                  itemCount: itemSnaps.length,
                  itemBuilder: (context, index) {
                    DocumentSnapshot itemDS = itemSnaps[index];

                    return Container(
                      height: h,
                      width: w,
                      child: Text('${itemDS['name']}'),
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
