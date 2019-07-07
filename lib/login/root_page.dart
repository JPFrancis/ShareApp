import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:shareapp/login/login_page.dart';
import 'package:shareapp/pages/home_page.dart';
import 'package:shareapp/services/auth.dart';

class RootPage extends StatefulWidget {
  static const routeName = '/rootPage';

  RootPage({Key key, this.auth}) : super(key: key);
  final BaseAuth auth;

  @override
  State<StatefulWidget> createState() => new _RootPageState();
}

enum AuthStatus {
  notSignedIn,
  signedIn,
}

class _RootPageState extends State<RootPage> {
  final FirebaseMessaging firebaseMessaging = FirebaseMessaging();
  AuthStatus authStatus = AuthStatus.notSignedIn;
  bool isLoading = true;

  initState() {
    super.initState();
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

  @override
  Widget build(BuildContext context) {
    if (authStatus == AuthStatus.signedIn) {
      return FutureBuilder(
          future: widget.auth.getFirebaseUser(),
          builder: (BuildContext context, AsyncSnapshot snapshot) {
            if (snapshot.hasData) {
              FirebaseUser user = snapshot.data;

              return new HomePage(
                auth: widget.auth,
                firebaseUser: user,
                onSignOut: () => _updateAuthStatus(AuthStatus.notSignedIn),
              );
            } else {
              return new Container(
                color: Colors.white,
              );
            }
          });
    } else {
      return new LoginPage(
        title: 'ShareApp Login',
        auth: widget.auth,
        onSignIn: () => _updateAuthStatus(AuthStatus.signedIn),
      );
    }
  }
}
