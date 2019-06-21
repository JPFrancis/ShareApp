import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class PayoutsPage extends StatefulWidget {
  static const routeName = '/payoutsPage';

  PayoutsPage({Key key}) : super(key: key);

  @override
  State<StatefulWidget> createState() {
    return PayoutsPageState();
  }
}

class PayoutsPageState extends State<PayoutsPage> {
  String appBarTitle = 'Payments and payouts';
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
    return Column(
      children: <Widget>[
        Container(height: 0,),
        buildChargesList(),
      ],
    );
  }

  Widget buildChargesList() {
    return Expanded(
      child: StreamBuilder<QuerySnapshot>(
        stream: Firestore.instance
            .collection('users')
            .document(myUserID)
            .collection('charges')
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
                      return ListTile(
                        title: Text(
                          '${ds['amount']}',
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

  void goToLastScreen() {
    Navigator.pop(context);
  }
}
