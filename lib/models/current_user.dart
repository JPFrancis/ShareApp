import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:shareapp/models/user.dart';
import 'package:scoped_model/scoped_model.dart';

class CurrentUser extends User {
  static CurrentUser getModel(BuildContext context) =>
      ScopedModel.of<CurrentUser>(context);

  CurrentUser(DocumentSnapshot snap) : super(snap);
}
