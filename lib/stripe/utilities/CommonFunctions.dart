import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shareapp/stripe/utilities/CurrentUser.dart';

Future<void> fetchUser() async {
  final user = await FirebaseAuth.instance.currentUser();
  CurrentUser.uid = user.uid; //can save other stuff also....
}

final fInstance = Firestore.instance;

final currencyList = ['USD', 'SGD'];
double defAmount = 5.0;

double min = 0.0;
double max = 100.0;

String usd = 'USD';
String sgd = 'SGD';

String refundID;
