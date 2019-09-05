import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

abstract class BaseAuth {
  Future<String> signIn(String email, String password);

  Future<String> createUser(String email, String password);

  Future<String> logInGoogle();

  Future<void> signOut();

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
  bool isFbLoggedIn = false;
  var profileData;
  String fbProfileStr;
  GoogleSignInAccount _currentUser;
  String _contactText;
  String id;

  FirebaseUser firebaseUser;

  Future<String> signIn(String email, String password) async {
    AuthResult user = await firebaseAuth.signInWithEmailAndPassword(
        email: email, password: password);

    if (user != null) {
      firebaseUser = user.user;
    }

    return firebaseUser.uid;
  }

  Future<String> createUser(String email, String password) async {
    AuthResult user = await firebaseAuth.createUserWithEmailAndPassword(
        email: email, password: password);

    if (user != null) {
      firebaseUser = user.user;
    }

    return firebaseUser.uid;
  }

  Future<String> logInGoogle() async {
    final GoogleSignInAccount googleUser = await _googleSignIn.signIn();
    final GoogleSignInAuthentication googleAuth =
        await googleUser.authentication;

    final AuthCredential credential = GoogleAuthProvider.getCredential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );

    AuthResult user =
        await FirebaseAuth.instance.signInWithCredential(credential);

    if (user != null) {
      firebaseUser = user.user;
    }

    return firebaseUser.uid;
  }

  void onLoginStatusChanged(bool isLoggedIn, {profileData}) {
    this.isFbLoggedIn = isLoggedIn;
    this.profileData = profileData;
  }

  Future<void> signOut() async {
    return firebaseAuth.signOut();
  }

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
