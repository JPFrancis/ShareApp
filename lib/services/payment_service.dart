import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class PaymentService {
  addCard(token) {
    FirebaseAuth.instance.currentUser().then((user) {
      Firestore.instance
          .collection('users')
          .document(user.uid)
          .collection('tokens')
          .add({
        'tokenId': token,
        'timestamp': DateTime.now(),
      }).then((val) {});
    });
  }

  chargeRental(
      String rentalId,
      int rentalDuration,
      Timestamp rentalStart,
      Timestamp rentalEnd,
      String idFrom,
      String idTo,
      double amount,
      String description) {
    // Stripe charges in cents. so $3.00 = 300 cents
    var processedPrice = amount * 100;

    Firestore.instance.collection('charges').add({
      'currency': 'usd',
      'amount': processedPrice,
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
    });
  }
}
