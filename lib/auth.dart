import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter_facebook_login/flutter_facebook_login.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

abstract class BaseAuth {
  Future<String> currentUser();

  Future<String> signIn(String email, String password);

  Future<String> createUser(String email, String password);

  Future<String> loginFB();

  Future<String> logInGoogle();

  Future<void> signOut();
}

GoogleSignIn _googleSignIn = GoogleSignIn(
  scopes: <String>[
    'email',
    'https://www.googleapis.com/auth/contacts.readonly',
  ],
);

class Auth implements BaseAuth {
  final FirebaseAuth firebaseAuth = FirebaseAuth.instance;
  var facebookLogin = FacebookLogin();
  bool isFbLoggedIn = false;
  var profileData;
  String profileStr;
  GoogleSignInAccount _currentUser;
  String _contactText;

  Future<String> signIn(String email, String password) async {
    FirebaseUser user = await firebaseAuth.signInWithEmailAndPassword(
        email: email, password: password);
    return user.uid;
  }

  Future<String> createUser(String email, String password) async {
    FirebaseUser user = await firebaseAuth.createUserWithEmailAndPassword(
        email: email, password: password);
    return user.uid;
  }

  Future<String> loginFB() async {
    var facebookLoginResult =
    await facebookLogin.logInWithReadPermissions(['email']);


    switch (facebookLoginResult.status) {
      case FacebookLoginStatus.error:
        onLoginStatusChanged(false);
        break;
      case FacebookLoginStatus.cancelledByUser:
        onLoginStatusChanged(false);
        break;
      case FacebookLoginStatus.loggedIn:
        var graphResponse = await http.get(
            'https://graph.facebook.com/v2.12/me?fields=name,first_name,last_name,email,picture.height(200)&access_token=${facebookLoginResult
                .accessToken.token}');

        var profile = json.decode(graphResponse.body);
        //print(profile.toString());
        profileStr = profile.toString();

        onLoginStatusChanged(true, profileData: profile);
        break;
    }

    firebaseAuth.signInWithCredential(FacebookAuthProvider.getCredential());

    return profileStr;
    //return user.uid;
  }

  Future<String> logInGoogle() async {
    final GoogleSignInAccount googleUser = await _googleSignIn.signIn();
    final GoogleSignInAuthentication googleAuth =
    await googleUser.authentication;

    final AuthCredential credential = GoogleAuthProvider.getCredential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );

    final FirebaseUser user = await FirebaseAuth.instance.signInWithCredential(
        credential);
    /*
    assert(user.email != null);
    assert(user.displayName != null);
    assert(!user.isAnonymous);
    assert(await user.getIdToken() != null);
*/
    //final FirebaseUser currentUser = await FirebaseAuth.instance.currentUser();
    //assert(user.uid == currentUser.uid);

    return user.uid;
  }

void onLoginStatusChanged(bool isLoggedIn, {profileData}) {
  this.isFbLoggedIn = isLoggedIn;
  this.profileData = profileData;
}

Future<String> currentUser() async {
  FirebaseUser user = await firebaseAuth.currentUser();
  return user != null ? user.uid : null;
}

Future<void> signOut() async {
  if (isFbLoggedIn)
    return facebookLogin.logOut();
  else {
    return firebaseAuth.signOut();
  }
}}
