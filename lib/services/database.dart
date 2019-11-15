import 'package:cloud_firestore/cloud_firestore.dart';

class DB {
  final db = Firestore.instance;

  Future<dynamic> addStripeConnectedAccount({String url}) async {
    try {
      return 0;
    } catch (e) {
      throw e.toString();
    }
  }
}
