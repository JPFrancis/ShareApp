import 'dart:async';
import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_facebook_login/flutter_facebook_login.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;

abstract class BaseAuth {
  Future<String> signIn(String email, String password);

  Future<String> createUser(String email, String password);

  Future<String> loginFB();

  Future<String> logInGoogle();

  Future<void> signOut();

  /// ===============

  Future<FirebaseUser> getFirebaseUser();

  Future<String> getUserID();

  Future<String> getUserDisplayName();

  Future<String> getPhotoURL();

  Future<String> getEmail();

  Future<FirebaseUser> updateAndRefresh(UserUpdateInfo info);
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
  String fbProfileStr;
  GoogleSignInAccount _currentUser;
  String _contactText;
  String id;

  FirebaseUser firebaseUser;

  Future<String> signIn(String email, String password) async {
    FirebaseUser user = await firebaseAuth.signInWithEmailAndPassword(
        email: email, password: password);

    if (user != null) {
      firebaseUser = user;
    }

    return firebaseUser.uid;
  }

  Future<String> createUser(String email, String password) async {
    FirebaseUser user = await firebaseAuth.createUserWithEmailAndPassword(
        email: email, password: password);

    if (user != null) {
      firebaseUser = user;
    }

    return firebaseUser.uid;
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
            'https://graph.facebook.com/v2.12/me?fields=name,first_name,last_name,email,picture.height(200)&access_token=${facebookLoginResult.accessToken.token}');

        var profile = json.decode(graphResponse.body);
        //print(profile.toString());
        fbProfileStr = profile.toString();

        onLoginStatusChanged(true, profileData: profile);
        break;
    }

    firebaseAuth.signInWithCredential(FacebookAuthProvider.getCredential());

    id = fbProfileStr;
    return fbProfileStr;
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

    final FirebaseUser user =
        await FirebaseAuth.instance.signInWithCredential(credential);

    if (user != null) {
      firebaseUser = user;
    }

    return firebaseUser.uid;
  }

  void onLoginStatusChanged(bool isLoggedIn, {profileData}) {
    this.isFbLoggedIn = isLoggedIn;
    this.profileData = profileData;
  }

  Future<void> signOut() async {
    if (isFbLoggedIn)
      return facebookLogin.logOut();
    else {
      return firebaseAuth.signOut();
    }
  }

  /// ===============================

  Future<FirebaseUser> getFirebaseUser() async {
    FirebaseUser user = await firebaseAuth.currentUser();
    return user != null ? user : null;
  }

  Future<String> getUserID() async {
    FirebaseUser user = await firebaseAuth.currentUser();
    return user != null ? user.uid : null;
  }

  Future<String> getUserDisplayName() async {
    FirebaseUser user = await firebaseAuth.currentUser();
    return user != null ? user.displayName : null;
  }

  Future<String> getPhotoURL() async {
    FirebaseUser user = await firebaseAuth.currentUser();
    return user != null ? user.photoUrl : null;
  }

  Future<String> getEmail() async {
    FirebaseUser user = await firebaseAuth.currentUser();
    return user != null ? user.email : null;
  }

  Future<FirebaseUser> updateAndRefresh(UserUpdateInfo info) async {
    FirebaseUser user = await firebaseAuth.currentUser();

    user.updateProfile(info);
    await user.reload();
    firebaseUser = user;
/*
    FirebaseUser check = await firebaseAuth.currentUser();

    assert(firebaseUser.uid == check.uid &&
        firebaseUser.displayName == check.displayName &&
        firebaseUser.photoUrl == check.photoUrl);
*/
    return await firebaseUser;
  }
}
