import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class FeedbackPage extends StatefulWidget {
  static const routeName = '/feedbackPage';

  FeedbackPage({Key key}) : super(key: key);

  @override
  State<StatefulWidget> createState() {
    return FeedbackPageState();
  }
}

class FeedbackPageState extends State<FeedbackPage> {
  String appBarTitle = 'Give feedback';
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
          showWriteReviewTextBox(),
          Align(
            alignment: AlignmentDirectional(0, 0),
            child: showSubmitReviewButton(),
          ),
        ],
      ),
    );
  }

  Widget showWriteReviewTextBox() {
    return Padding(
      padding: EdgeInsets.all(padding),
      child: TextField(
        maxLines: 5,
        controller: feedbackController,
        //style: textStyle,
        decoration: InputDecoration(
          labelText: 'Write feedback',
          filled: true,
        ),
      ),
    );
  }

  Widget showSubmitReviewButton() {
    return RaisedButton(
      shape: new RoundedRectangleBorder(
          borderRadius: new BorderRadius.circular(5.0)),
      color: Colors.green,
      textColor: Colors.white,
      child: Text(
        'Send feedback',

        textScaleFactor: 1.25,
      ),
      onPressed: () {

      },
    );
  }

  void goToLastScreen() {
    Navigator.pop(context);
  }
}
