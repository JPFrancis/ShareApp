import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class PaymentService {
  addCard(token) {
    FirebaseAuth.instance.currentUser().then((user) {
      Firestore.instance
          .collection('users')
          .document(user.uid)
          .collection('tokens')
          .add({'tokenId': token}).then((val) {
        //print('saved');
      });
    });
  }


  chargeRental(price, description) {
    // Stripe charges in cents. so $3.00 = 300 cents
    var processedPrice = price * 100;

    FirebaseAuth.instance.currentUser().then((user) {
      Firestore.instance
          .collection('users')
          .document(user.uid)
          .collection('charges')
          .add({
        'currency': 'usd',
        'amount': processedPrice,
        'description': description,
        'chargeTimestamp': DateTime.now().millisecondsSinceEpoch,
      });
    });
  }
}
