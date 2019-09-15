import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:shareapp/login/login_page.dart';
import 'package:shareapp/main.dart';
import 'package:shareapp/pages/home_page.dart';
import 'package:shareapp/rentals/chat.dart';
import 'package:shareapp/rentals/rental_detail.dart';
import 'package:shareapp/services/auth.dart';

class RootPage extends StatefulWidget {
  static const routeName = '/rootPage';

  RootPage({Key key, this.auth}) : super(key: key);
  final BaseAuth auth;

  @override
  State<StatefulWidget> createState() => new RootPageState();
}

enum AuthStatus {
  notSignedIn,
  signedIn,
}

class RootPageState extends State<RootPage> {
  final FirebaseMessaging firebaseMessaging = FirebaseMessaging();
  AuthStatus authStatus = AuthStatus.notSignedIn;
  bool isLoading = true;

  initState() {
    super.initState();

    configureFCM();

    widget.auth.getUserID().then((userId) {
      setState(() {
        authStatus =
            userId != null ? AuthStatus.signedIn : AuthStatus.notSignedIn;
      });
    });
  }

  void _updateAuthStatus(AuthStatus status) {
    setState(() {
      authStatus = status;
    });
  }

  void configureFCM() async {
    firebaseMessaging.configure(
      /// called if app is closed but running in background
      onResume: (Map<String, dynamic> message) async {
        handleNotifications(message);
      },

      /// called if app is fully closed
      onLaunch: (Map<String, dynamic> message) async {
        handleNotifications(message);
      },

      /// called when app is running in foreground
      onMessage: (Map<String, dynamic> message) async {},
    );
  }

  void handleNotifications(Map<String, dynamic> message) async {
    var data = message['data'];
    var rentalID = data['rentalID'];
    String otherUserID = data['idFrom'];

    switch (data['type']) {
      case 'rental':
        Navigator.of(context).popUntil(ModalRoute.withName('/'));
        Navigator.of(context).pushNamed(
          RentalDetail.routeName,
          arguments: RentalDetailArgs(
            rentalID,
          ),
        );

        break;

      case 'chat':
//        Navigator.of(context).popUntil(ModalRoute.withName('/'));
        Navigator.of(context).pushNamed(
          Chat.routeName,
          arguments: ChatArgs(
            otherUserID,
          ),
        );

        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (authStatus == AuthStatus.signedIn) {
      return FutureBuilder(
          future: widget.auth.getFirebaseUser(),
          builder: (BuildContext context, AsyncSnapshot snapshot) {
            if (snapshot.hasData) {
              FirebaseUser user = snapshot.data;

              return HomePage(
                auth: widget.auth,
                firebaseUser: user,
                onSignOut: () => _updateAuthStatus(AuthStatus.notSignedIn),
              );
            } else {
              return Container(color: Colors.white);
            }
          });
    } else {
      return LoginPage(
        title: 'ShareApp Login',
        auth: widget.auth,
        onSignIn: () => _updateAuthStatus(AuthStatus.signedIn),
      );
    }
  }
}
