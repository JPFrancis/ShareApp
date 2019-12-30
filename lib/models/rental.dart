import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:scoped_model/scoped_model.dart';

/*
declined:
true = declined
false = cancelled
null = neither
 */

/*
int status
1 = requested
2 = accepted
3 = active'
4 = returned
5 = cancelled
*/

/*
0) renter has proposed time - burden of accept is on owner.
  Entered when renter proposes new time
1) owner has proposed time - burden of accept is on renter
  Entered when owner proposes new time
2) accepted - when the rental request is agreed upon, can be done by either
  renter or owner. Before the pickup window starts
3) active - the actual renting is taking place including pickup window.
  Occurs when rental pickup start is after current time.
4) Rental is finished. Starts when current time hits rentalEnd.
5) Rental is cancelled
*/

class Rental extends Model {
  String id;
  DateTime created;
  DateTime lastUpdateTime;
  DateTime pickupStart;
  DateTime pickupEnd;
  DateTime rentalEnd;

  int status;
  double price;
  int duration;

  bool requesting;
  bool declined;

  DocumentReference itemRef;
  String itemAvatar;
  String itemName;

  DocumentReference ownerRef;
  String ownerAvatar;
  String ownerName;

  double ownerReviewAverage;
  int ownerReviewCommunication;
  int ownerReviewItemQuality;
  int ownerReviewOverall;
  String ownerReviewNote;
  bool ownerReviewSubmitted;

  DocumentReference renterRef;
  String renterAvatar;
  String renterName;

  int renterReviewRating;
  String renterReviewNote;
  bool renterReviewSubmitted;

  List users;

  static Rental getModel(BuildContext context) =>
      ScopedModel.of<Rental>(context);

  Rental(DocumentSnapshot snap) {
    updateData(snap, constructor: true);
  }

  void updateData(DocumentSnapshot snap, {bool constructor}) {
    Map data = snap.data;

    this.id = snap.documentID;
    this.created = (data['created'] as Timestamp).toDate();
    this.lastUpdateTime = (data['lastUpdateTime'] as Timestamp).toDate();
    this.pickupStart = (data['pickupStart'] as Timestamp).toDate();
    this.pickupEnd = (data['pickupEnd'] as Timestamp).toDate();
    this.rentalEnd = (data['rentalEnd'] as Timestamp).toDate();

    this.status = data['status'];
    this.price = data['price'];
    this.duration = data['duration'];

    this.requesting = data['requesting'];
    this.declined = data['declined'];

    this.itemRef = data['item'];
    this.itemAvatar = data['itemAvatar'];
    this.itemName = data['itemName'];

    this.ownerRef = data['owner'];
    Map ownerData = data['ownerData'];
    this.ownerAvatar = ownerData['avatar'];
    this.ownerName = ownerData['name'];

    Map ownerReview = data['ownerReview'];

    if (ownerReview != null) {
      this.ownerReviewAverage = ownerReview['average'];
      this.ownerReviewCommunication = ownerReview['communication'];
      this.ownerReviewItemQuality = ownerReview['itemQuality'];
      this.ownerReviewOverall = ownerReview['overall'];
      this.ownerReviewNote = ownerReview['reviewNote'];
    }

    this.ownerReviewSubmitted = data['ownerReviewSubmitted'];

    this.renterRef = data['renter'];
    Map renterData = data['renterData'];
    this.renterAvatar = renterData['avatar'];
    this.renterName = renterData['name'];

    Map renterReview = data['renterReview'];

    if (renterReview != null) {
      this.renterReviewRating = renterReview['rating'];
      this.renterReviewNote = renterReview['reviewNote'];
    }
    
    this.renterReviewSubmitted = data['renterReviewSubmitted'];

    this.users = []..addAll(data['users']);

    if (constructor == null) {
      notifyListeners();
    }
  }

//  Rental.fromMap(Map<String, dynamic> data)
//      : this(
//          status: data['status'],
//          item: data['item'],
//          owner: data['owner'],
//          renter: data['renter'],
//          start: data['start'],
//          end: data['end'],
//        );
}
