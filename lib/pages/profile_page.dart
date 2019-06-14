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
  bool isLoading;

  @override
  void initState() {
    // TODO: implement initState
    super.initState();

    userDS = widget.initUserDS;
  }

  Future<Null> getSnapshots(bool refreshItemDS) async {
    DocumentSnapshot ds = refreshItemDS
        ? await Firestore.instance
            .collection('users')
            .document(userDS.documentID)
            .get()
        : userDS;

    if (ds != null) {}
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Search Results Page'),
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
          Text('${widget.initUserDS['name']}'),
        ],
      ),
    );
  }

  void goBack() {
    Navigator.pop(context);
  }
}
