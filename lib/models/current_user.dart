import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:scoped_model/scoped_model.dart';
import 'package:shareapp/models/user.dart';

class CurrentUser extends User {
  static CurrentUser getModel(BuildContext context) =>
      ScopedModel.of<CurrentUser>(context);

  CurrentUser(DocumentSnapshot snap) : super(snap);
}
