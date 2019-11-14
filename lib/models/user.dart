import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';
import 'package:scoped_model/scoped_model.dart';

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
  String custId;
  String defaultSource;
  String description;
  String email;
  String gender;
  String name;
  String phoneNum;

  // current user only
  Position currentLocation;

  User(DocumentSnapshot snap) {
    updateData(snap, constructor: true);
  }

  void updateData(DocumentSnapshot snap, {bool constructor}) {
    Map data = snap.data;
    Timestamp bDay = data['birthday'];
    DateTime birthday = bDay.toDate();

    this.snap = snap;
    this.id = snap.documentID;
    this.acceptedTOS = data['acceptedTOS'];
    this.address = data['address'];
    this.avatar = data['avatar'];
    this.birthday = birthday;
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

  void updateCurrentLocation(Position position) {
    this.currentLocation = position;

    notifyListeners();
  }
}
