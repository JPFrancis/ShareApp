import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shareapp/extras/helpers.dart';
import 'package:shareapp/models/rental.dart';
import 'package:shareapp/services/dialogs.dart';

void showToast(String message) {
  Fluttertoast.showToast(
    msg: message,
    toastLength: Toast.LENGTH_SHORT,
    gravity: ToastGravity.BOTTOM,
    timeInSecForIos: 1,
    fontSize: 15.5,
    backgroundColor: Colors.grey[800],
  );
}

bool checkIdIsFirst(String id0, String id1) {
  return id0.hashCode < id1.hashCode ? true : false;
}

/// Ids can be given in any order
Map getChatRoomData(String id0, String id1) {
  String combinedId = '';
  List users = [];

  if (checkIdIsFirst(id0, id1)) {
    combinedId = '$id0-$id1';
    users = [id0, id1];
  } else {
    combinedId = '$id1-$id0';
    users = [id1, id0];
  }

  if (combinedId.isEmpty || users.isEmpty) {
    return null;
  } else {
    return {
      'combinedId': combinedId,
      'users': users,
    };
  }
}

Map setChatUserData(Map user0, Map user1) {
  Map map = {};
  String id0 = user0['id'];
  String id0Name = user0['name'];
  String id0Avatar = user0['avatar'];
  String id1 = user1['id'];
  String id1Name = user1['name'];
  String id1Avatar = user1['avatar'];

  if (checkIdIsFirst(id0, id1)) {
    map = {
      'user0': {
        'name': id0Name,
        'avatar': id0Avatar,
      },
      'user1': {
        'name': id1Name,
        'avatar': id1Avatar,
      },
    };
  } else {
    map = {
      'user0': {
        'name': id1Name,
        'avatar': id1Avatar,
      },
      'user1': {
        'name': id0Name,
        'avatar': id0Avatar,
      },
    };
  }

  return map;
}

Future<void> submitReview(
  bool isRenter,
  String myUserId,
  Rental rental,
  String reviewNote,
  double communicationRating,
  double itemQualityRating,
  double overallExpRating,
  double renterRating,
) async {
  String otherUserId =
      isRenter ? rental.ownerRef.documentID : rental.renterRef.documentID;

  if (isRenter) {
    if (communicationRating > 0 &&
        itemQualityRating > 0 &&
        overallExpRating > 0) {
      double avg =
          (communicationRating + itemQualityRating + overallExpRating) / 3;

      var review = {
        'communication': communicationRating,
        'itemQuality': itemQualityRating,
        'overall': overallExpRating,
        'average': avg,
        'reviewNote': reviewNote,
      };

      return await Firestore.instance
          .collection('rentals')
          .document(rental.id)
          .updateData({
        'lastUpdateTime': DateTime.now(),
        'ownerReview': review,
        'ownerReviewSubmitted': true,
      });

      /*
      await Firestore.instance.collection('items').document(rentalDS['item'].documentID).updateData({
        'numRatings': FieldValue.increment(1),
        'rating': FieldValue.increment(avg),
      });

      await Firestore.instance
          .collection('users')
          .document(rentalDS['owner'].documentID)
          .updateData({
        'ownerRating': {
          'count': FieldValue.increment(1),
          'total': FieldValue.increment(avg),
        },
      });

      DocumentSnapshot otherUserDS = await Firestore.instance
          .collection('users')
          .document(otherUserId)
          .get();

      await Firestore.instance.collection('notifications').add({
        'title': '$myName left you a review',
        'body': '',
        'pushToken': otherUserDS['pushToken'],
        'rentalID': rentalDS.documentID,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      });
      */
    }
  } else {
    if (renterRating > 0) {
      return await Firestore.instance
          .collection('rentals')
          .document(rental.id)
          .updateData({
        'lastUpdateTime': DateTime.now(),
        'renterReview': {
          'rating': renterRating,
          'reviewNote': reviewNote,
        },
        'renterReviewSubmitted': true,
      });

      /*
      await Firestore.instance
          .collection('users')
          .document(rentalDS['renter'].documentID)
          .updateData({
        'renterRating': {
          'count': FieldValue.increment(1),
          'total': FieldValue.increment(renterRating),
        },
      });

      DocumentSnapshot otherUserDS = await Firestore.instance
          .collection('users')
          .document(otherUserId)
          .get();

      await Firestore.instance.collection('notifications').add({
        'title': '$myName left you a review',
        'body': '',
        'pushToken': otherUserDS['pushToken'],
        'rentalID': rentalDS.documentID,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      });
       */
    }
  }
}

Future<Position> getUserLocation() async {
  Position currentLocation;

  GeolocationStatus geolocationStatus =
      await Geolocator().checkGeolocationPermissionStatus();

  Future<Position> onTimeout() {
    return null;
  }

  Future<Position> getLoc() async {
    return await Geolocator()
        .getCurrentPosition(desiredAccuracy: LocationAccuracy.high)
        .timeout(const Duration(seconds: 5), onTimeout: onTimeout);
  }

  if (geolocationStatus != null) {
    if (geolocationStatus == GeolocationStatus.granted) {
      currentLocation = await getLoc();
    } else {
      if (geolocationStatus != GeolocationStatus.granted) {
        Map<PermissionGroup, PermissionStatus> permissions =
            await PermissionHandler()
                .requestPermissions([PermissionGroup.location]);

        if (permissions[PermissionGroup.location] == PermissionStatus.granted) {
          currentLocation = await getLoc();
        }
      }
    }

    return currentLocation ?? null;
  }

  return currentLocation;
}

void showReportUserDialog(
    {BuildContext context,
    String myId,
    String myName,
    String offenderId,
    String offenderName}) async {
  double pageWidth = MediaQuery.of(context).size.width;

  var value = await showDialog(
    barrierDismissible: true,
    context: context,
    builder: (BuildContext context) {
      return Container(
        child: ReportUserDialog(
          pageWidth: pageWidth,
          myId: myId,
          myName: myName,
          offenderId: offenderId,
          offenderName: offenderName,
        ),
      );
    },
  );

  if (value != null && value is int && value == 0) {
    showToast('Report sent!');
  }
}

List getDatesInRange(DateTime start, DateTime end) {
  List rentalDays = [];

  DateTime parsedStart = stripHourMin(start);
  DateTime parsedEnd = stripHourMin(end).add(Duration(hours: 1));

  for (DateTime curr = parsedStart;
      curr.isBefore(parsedEnd);
      curr = curr.add(Duration(days: 1))) {
    rentalDays.add(curr);
  }

  rentalDays.sort();

  return rentalDays;
}
