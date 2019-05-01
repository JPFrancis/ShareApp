import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:multi_image_picker/multi_image_picker.dart';
import 'package:shareapp/models/item.dart';
import 'package:shareapp/services/select_location.dart';

Widget divider() {
  return Padding(
    padding: const EdgeInsets.all(8.0),
    child: Divider(),
  );
}

  Widget backButton(context) {
    return IconButton(
      alignment: Alignment.topLeft,
      icon: BackButton(),
      onPressed: () => Navigator.pop(context),
    );
  }