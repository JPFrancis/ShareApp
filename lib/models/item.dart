import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:scoped_model/scoped_model.dart';

/*
'Tool',
'Leisure',
'Home',
'Equipment',
'Other',
 */

/*
int condition
'Lightly Used',
'Good',
'Fair',
'Has Character',
 */

/*
bool status
true = active
false = inactive
 */

class Item extends Model {
  bool isVisible;
  DocumentReference creator; // user ID of user who created the item
  String name;
  String description;
  String type;
  String condition;
  String policy;
  double rating;
  double numRatings;
  int price;
  int numImages;
  List images;
  Map<dynamic, dynamic> location;
  List unavailable;

  static Item getModel(BuildContext context) => ScopedModel.of<Item>(context);

  Item({DocumentSnapshot snap, String userId}) {
    if (userId != null) {
      this.isVisible = true;
      this.creator = Firestore.instance.collection('users').document(userId);
      this.name = '';
      this.description = '';
      this.type = null;
      this.condition = null;
      this.price = 0;
      this.numImages = 0;
      this.images = [];
      this.location = {'geopoint': null};
    } else if (snap != null) {
      updateData(snap, constructor: true);
    }
  }

  void updateData(DocumentSnapshot snap, {bool constructor}) {
    Map data = snap.data;

    this.isVisible = data['status'];
    this.creator = data['creator'];
    this.name = data['name'];
    this.description = data['description'];
    this.type = data['type'];
    this.condition = data['condition'];
    this.rating = data['rating'].toDouble();
    this.numRatings = data['numRatings'].toDouble();
    this.price = data['price'];
    this.numImages = data['numImages'];
    this.images = data['images'];
    this.location = data['location'];
    this.unavailable = data['unavailable'];

    if (constructor == null) {
      notifyListeners();
    }
  }

  Item.copy(Item other) {
    this.isVisible = other.isVisible;
    this.creator = other.creator;
    this.name = other.name;
    this.description = other.description;
    this.type = other.type;
    this.condition = other.condition;
    this.rating = other.rating;
    this.numRatings = other.numRatings;
    this.price = other.price;
    this.numImages = other.numImages;
    this.images = other.images.toList();
    this.location = other.location;
    this.unavailable = other.unavailable;
  }

  bool compare(Item other) {
    return this.name == other.name &&
        this.description == other.description &&
        this.type == other.type &&
        this.condition == other.condition &&
        this.price == other.price &&
        this.location == other.location;
  }
}
