import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';
import 'package:scoped_model/scoped_model.dart';
import 'package:shareapp/models/user_edit.dart';

/*
Address fields (all strings):
city
state (abbr)
street
zip
 */

class User extends Model {
  DocumentSnapshot snap;
  String id;
  bool acceptedTOS;
  Map address;
  String avatar;
  DateTime birthday;
  String connectedAcctId;
  String custId;
  String defaultSource;
  String description;
  String email;
  String gender;
  String name;
  String phoneNum;
  bool verified;

  // current user only
  Position currentLocation;

  User(DocumentSnapshot snap) {
    updateData(snap, constructor: true);
  }

  void updateData(DocumentSnapshot snap, {bool constructor}) {
    Map data = snap.data;
    Timestamp bDay = data['birthday'];
    DateTime birthday = bDay?.toDate();

    this.snap = snap;
    this.id = snap.documentID;
    this.acceptedTOS = data['acceptedTOS'];
    this.address = data['address'];
    this.avatar = data['avatar'];
    this.birthday = birthday;
    this.connectedAcctId = data['connectedAcctId'];
    this.custId = data['custId'];
    this.defaultSource = data['defaultSource'];
    this.description = data['description'];
    this.email = data['email'];
    this.gender = data['gender'];
    this.name = data['name'];
    this.phoneNum = data['phoneNum'];

    if (constructor == null) {
      notifyListeners();
    }
  }

  void updateUser({UserEdit userEdit}) {
    this.avatar = userEdit.avatar;
    this.name = userEdit.name;
    this.description = userEdit.description;
    this.gender = userEdit.gender;
    this.birthday = userEdit.birthday;
    this.phoneNum = userEdit.phoneNum;
    this.address = userEdit.address;

    notifyListeners();
  }

  void updateCurrentLocation(Position position) {
    this.currentLocation = position;

    notifyListeners();
  }

  void acceptTOS() {
    this.acceptedTOS = true;

    notifyListeners();
  }
}

bool verifyUser(
    {Map address, DateTime birthday, String gender, String phoneNum}) {
  if (address == null) {
    return false;
  } else {
    String city = address['city'];
    String state = address['state'];
    String street = address['street'];
    String zip = address['zip'];

    if (city == null || city.isEmpty) {
      return false;
    } else if (state == null || state.length != 2) {
      return false;
    } else if (street == null || street.isEmpty) {
      return false;
    } else if (zip == null || zip.length != 5) {
      return false;
    }
  }

  if (birthday == null) {
    return false;
  }

  if (gender == null || gender.isEmpty) {
    return false;
  }

  if (phoneNum == null || phoneNum.length != 10) {
    return false;
  }

  return true;
}
