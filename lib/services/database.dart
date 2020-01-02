import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:shareapp/models/rental.dart';

class DB {
  final db = Firestore.instance;

  Future<dynamic> addStripeConnectedAccount({String url, String userId}) async {
    try {
      String acctId;

      RegExp regExp = RegExp(r'code=(.*)');
      acctId = regExp.firstMatch(url.trim()).group(1);

      HttpsCallable callable = CloudFunctions.instance.getHttpsCallable(
        functionName: 'finishOAuthFlow',
      );

      final HttpsCallableResult result = await callable.call(
        <String, dynamic>{
          'acctId': acctId,
        },
      );

      if (result != null) {
        await db
            .collection('users')
            .document(userId)
            .updateData({'connectedAcctId': result.data});

        return result.data;
      } else {
        throw 'An error occurred';
      }
    } catch (e) {
      throw e.toString();
    }
  }

  Stream<DocumentSnapshot> getRentalStream(String rentalId) {
    return db.collection('rentals').document(rentalId).snapshots();
  }

  Future<dynamic> checkAcceptRental(Rental rental) {
    try {} catch (e) {
      throw e.toString();
    }
  }
}
