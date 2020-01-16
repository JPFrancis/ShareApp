import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class PaymentService {
  chargeRental(
      String rentalId,
      int rentalDuration,
      Timestamp rentalStart,
      Timestamp rentalEnd,
      String idFrom,
      String idTo,
      int amount,
      Map transferData,
      String description,
      Map userData) {
    Firestore.instance.collection('charges').add({
      'currency': 'usd',
      'amount': amount,
      'description': description,
      'timestamp': DateTime.now(),
      'rental': Firestore.instance.collection('rentals').document(rentalId),
      'rentalData': {
        'idFrom': idFrom,
        'idTo': idTo,
        'duration': rentalDuration,
        'rentalStart': rentalStart,
        'rentalEnd': rentalEnd,
      },
      'transferData': transferData,
      'userData': userData,
      'users': [idFrom, idTo]
    });
  }

  createSubscription(
    String rentalId,
    int rentalDuration,
    Timestamp rentalStart,
    Timestamp rentalEnd,
    String idFrom,
    String idTo,
    int amount,
    Map transferData,
    String description,
  ) {
    Firestore.instance.collection('charges').add({
      'currency': 'usd',
      'amount': amount,
      'description': description,
      'timestamp': DateTime.now(),
      'rental': Firestore.instance.collection('rentals').document(rentalId),
      'rentalData': {
        'idFrom': idFrom,
        'idTo': idTo,
        'duration': rentalDuration,
        'rentalStart': rentalStart,
        'rentalEnd': rentalEnd,
      },
      'transferData': transferData,
    });
  }
}
