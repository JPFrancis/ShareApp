import 'package:cloud_firestore/cloud_firestore.dart';

class DB {
  final db = Firestore.instance;

  Future<dynamic> addStripeConnectedAccount({String url, String userId}) async {
    try {
      String acctId;

      RegExp regExp = RegExp(r'code=(.*)');
      acctId = regExp.firstMatch(url.trim()).group(1);

      await db
          .collection('users')
          .document(userId)
          .updateData({'connectedAcctId': acctId});

      return acctId;
    } catch (e) {
      throw e.toString();
    }
  }
}
