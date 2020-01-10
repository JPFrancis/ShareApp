import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:shareapp/models/current_user.dart';
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

  Future<dynamic> checkAcceptRental(Rental rental) async {
    try {
      List rentalDays = []..addAll(rental.rentalDays);

      var snaps = await db
          .collection('rentals')
          .where('item', isEqualTo: rental.itemRef)
          .where('rentalDays', arrayContainsAny: rentalDays)
          .where('status', isGreaterThanOrEqualTo: 2)
          .limit(1)
          .getDocuments();

      if (snaps != null && snaps.documents.isNotEmpty) {
        throw 'Someone else accepted a rental during this time!';
      } else {
        return 0;
      }
    } catch (e) {
      throw e.toString();
    }
  }

  Future<dynamic> addStripeSource({
    CurrentUser currentUser,
    String token,
  }) async {
    try {
      if (currentUser != null && token != null) {
        final HttpsCallable callable = CloudFunctions.instance
            .getHttpsCallable(functionName: 'addStripeCard');

        final HttpsCallableResult result =
            await callable.call(<String, dynamic>{
          'tokenId': token,
          'userId': currentUser.id,
          'email': currentUser.email,
          'customerId': currentUser.custId,
        });

        final response = result.data;

        if (response != null && response is Map) {
          String custId = response['custId'];
          String defaultSource = response['defaultSource'];

          currentUser.updateCustomerId(custId);
          currentUser.updateDefaultSource(defaultSource);

          return 0;
        } else {
          throw 'An error occurred';
        }
      }
    } on CloudFunctionsException catch (e) {
      throw e.message;
    } catch (e) {
      throw e.toString();
    }
  }

  Future<dynamic> setDefaultStripeSource({
    CurrentUser currentUser,
    String cardId,
  }) async {
    try {
      if (currentUser != null && cardId != null) {
        final HttpsCallable callable = CloudFunctions.instance
            .getHttpsCallable(functionName: 'setDefaultSource');

        final HttpsCallableResult result =
            await callable.call(<String, dynamic>{
          'userId': currentUser.id,
          'customerId': currentUser.custId,
          'newSourceId': cardId,
        });

        final response = result.data;

        if (response != null && response is String && response.isNotEmpty) {
          currentUser.updateDefaultSource(response);

          return 0;
        } else {
          throw 'An error occurred';
        }
      }
    } on CloudFunctionsException catch (e) {
      throw e.message;
    } catch (e) {
      throw e.toString();
    }
  }

  Future<dynamic> deleteStripeSource({
    CurrentUser currentUser,
    String cardId,
    String fingerprint,
  }) async {
    try {
      if (currentUser != null && cardId != null) {
        final HttpsCallable callable = CloudFunctions.instance.getHttpsCallable(
          functionName: 'deleteStripeSource',
        );

        final HttpsCallableResult result =
            await callable.call(<String, dynamic>{
          'userId': currentUser.id,
          'customerId': currentUser.custId,
          'source': cardId,
        });

        final response = result.data;

        if (response != null && response is String && response.isNotEmpty) {
          currentUser.updateDefaultSource(response);

          await Firestore.instance
              .collection('users')
              .document(currentUser.id)
              .collection('sources')
              .document(fingerprint)
              .delete()
              .then((_) {
            return 0;
          });
        } else {
          throw 'An error occurred';
        }
      }
    } on CloudFunctionsException catch (e) {
      throw e.message;
    } catch (e) {
      throw e.toString();
    }
  }
}
