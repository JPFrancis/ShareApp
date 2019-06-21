import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class HelpPage extends StatefulWidget {
  static const routeName = '/helpPage';

  HelpPage({Key key}) : super(key: key);

  @override
  State<StatefulWidget> createState() {
    return HelpPageState();
  }
}

class HelpPageState extends State<HelpPage> {
  String appBarTitle = 'Help Page';
  TextEditingController feedbackController = TextEditingController();
  double padding = 5.0;
  String myUserID;
  bool isLoading = true;

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

      if (myUserID != null) {
        setState(() {
          isLoading = false;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('$appBarTitle'),
      ),
      body: showBody(),
    );
  }

  Widget showBody() {
    return Padding(
      padding: EdgeInsets.all(15),
      child: ListView(
        children: <Widget>[
          Text('Help'),
        ],
      ),
    );
  }


  void goToLastScreen() {
    Navigator.pop(context);
  }
}
